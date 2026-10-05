import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../theme.dart';

class AuthService {
  AuthService._();

  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  final signedIn = ValueNotifier<bool>(false);

  String? uid;
  String? email;

  bool _googleInitialized = false;

  Future<void> _initializeGoogle() async {
    if (_googleInitialized) return;

    await _googleSignIn.initialize();

    _googleInitialized = true;
  }

  Future<void> _updateSession(User? user) async {
    uid = user?.uid;
    email = user?.email;
    signedIn.value = user != null;
  }

  // ============================================================
  // REGISTER EMAIL
  // ============================================================

  Future<void> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    UserCredential? result;
    bool usernameRegistered = false;

    try {
      final cleanUsername = username.trim();
      final cleanEmail = email.trim();

      if (!RegExp(
        r'^[a-zA-Z0-9_]{3,20}$',
      ).hasMatch(cleanUsername)) {
        throw Exception(
          'Username harus 3-20 karakter, '
          'hanya huruf, angka, dan underscore.',
        );
      }

      result =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = result.user;

      if (user == null) {
        throw Exception('Akun gagal dibuat.');
      }

      debugPrint(
        'REGISTER AUTH BERHASIL: ${user.uid}',
      );

      await user.updateDisplayName(
        cleanUsername,
      );

      final callable =
          _functions.httpsCallable(
        'registerUsername',
      );

      try {
        final response =
            await callable.call({
          'username': cleanUsername,
        });

        debugPrint(
          'REGISTER USERNAME BERHASIL: '
          '${response.data}',
        );

        usernameRegistered = true;
      } on FirebaseFunctionsException catch (e) {
        debugPrint(
          '=== REGISTER USERNAME ERROR ===',
        );
        debugPrint(
          'CODE: ${e.code}',
        );
        debugPrint(
          'MESSAGE: ${e.message}',
        );
        debugPrint(
          'DETAILS: ${e.details}',
        );

        rethrow;
      }

      try {
        await user.sendEmailVerification();

        debugPrint(
          'EMAIL VERIFICATION: BERHASIL DIPANGGIL',
        );
      } on FirebaseAuthException catch (e) {
        debugPrint(
          'EMAIL VERIFICATION ERROR: ${e.code}',
        );

        debugPrint(
          'PESAN: ${e.message}',
        );

        rethrow;
      }

      await _auth.signOut();

      await _updateSession(null);
    } on FirebaseAuthException catch (e) {
      if (result?.user != null &&
          !usernameRegistered) {
        try {
          await result!.user!.delete();
        } catch (_) {}
      }

      throw Exception(
        _authErrorMessage(e.code),
      );
    } on FirebaseFunctionsException catch (e) {
      if (result?.user != null &&
          !usernameRegistered) {
        try {
          await result!.user!.delete();
        } catch (_) {}
      }

      throw Exception(
        '${e.code}: '
        '${e.message ?? 'Gagal mendaftarkan username.'}',
      );
    } catch (e) {
      if (result?.user != null &&
          !usernameRegistered) {
        try {
          await result!.user!.delete();
        } catch (_) {}
      }

      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // RESEND VERIFICATION
  // ============================================================

  Future<void> resendVerificationEmail() async {
    try {
      var user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'Sesi akun tidak ditemukan. '
          'Silakan login terlebih dahulu.',
        );
      }

      await user.reload();

      user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'Akun tidak ditemukan.',
        );
      }

      if (user.emailVerified) {
        throw Exception(
          'Email akun ini sudah terverifikasi.',
        );
      }

      await user.sendEmailVerification();

      debugPrint(
        'RESEND VERIFICATION: BERHASIL DIPANGGIL',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'RESEND VERIFICATION ERROR: ${e.code}',
      );

      debugPrint(
        'PESAN: ${e.message}',
      );

      throw Exception(
        _authErrorMessage(e.code),
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // RESEND VERIFICATION WITH PASSWORD
  // ============================================================

  Future<void> resendVerificationEmailWithPassword({
    required String email,
    required String password,
  }) async {
    UserCredential? credential;

    try {
      credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception(
          'Akun tidak ditemukan.',
        );
      }

      await user.reload();

      final currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        throw Exception(
          'Sesi akun tidak ditemukan.',
        );
      }

      if (currentUser.emailVerified) {
        throw Exception(
          'Email akun ini sudah terverifikasi.',
        );
      }

      await currentUser.sendEmailVerification();

      debugPrint(
        'RESEND VERIFICATION: BERHASIL DIPANGGIL',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'RESEND VERIFICATION ERROR: ${e.code}',
      );

      debugPrint(
        'PESAN: ${e.message}',
      );

      throw Exception(
        _authErrorMessage(e.code),
      );
    } finally {
      if (credential != null) {
        await _auth.signOut();
        await _updateSession(null);
      }
    }
  }

  // ============================================================
  // LOGIN EMAIL / USERNAME
  // ============================================================

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final identifier = email.trim();

      var loginEmail = identifier;

      if (!identifier.contains('@')) {
        final callable =
            _functions.httpsCallable(
          'resolveUsername',
        );

        final response =
            await callable.call({
          'username': identifier,
        });

        final data =
            Map<String, dynamic>.from(
          response.data as Map,
        );

        final resolvedEmail =
            data['email'];

        if (resolvedEmail is! String ||
            resolvedEmail.isEmpty) {
          throw Exception(
            'Username atau password salah.',
          );
        }

        loginEmail = resolvedEmail;
      }

      final result =
          await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      final user = result.user;

      if (user == null) {
        throw Exception(
          'Login gagal.',
        );
      }

      await user.reload();

      final currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        throw Exception(
          'Sesi login tidak ditemukan.',
        );
      }

      if (!currentUser.emailVerified) {
        await _auth.signOut();

        await _updateSession(null);

        throw Exception(
          'Email belum diverifikasi. '
          'Silakan cek email kamu.',
        );
      }

      await _updateSession(
        currentUser,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _authErrorMessage(e.code),
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        throw Exception(
          'Username atau password salah.',
        );
      }

      throw Exception(
        e.message ??
            'Gagal menghubungi server.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // LOGIN GOOGLE
  // ============================================================

  Future<void> loginWithGoogle() async {
    try {
      await _initializeGoogle();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception(
          'Google Sign-In tidak didukung '
          'pada platform ini.',
        );
      }

      final GoogleSignInAccount account =
          await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          account.authentication;

      final credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final result =
          await _auth.signInWithCredential(
        credential,
      );

      await _updateSession(
        result.user,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(
        e.message ??
            'Login Google gagal.',
      );
    } catch (e) {
      throw Exception(
        'Login Google gagal: '
        '${e.toString().replaceFirst(
          'Exception: ',
          '',
        )}',
      );
    }
  }

  // ============================================================
  // FIREBASE AUTH ERROR MESSAGE
  // ============================================================

  String _authErrorMessage(
    String code,
  ) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';

      case 'invalid-email':
        return 'Format email tidak valid.';

      case 'weak-password':
        return 'Password terlalu lemah.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';

      case 'too-many-requests':
        return 'Terlalu banyak percobaan. '
            'Coba lagi nanti.';

      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';

      case 'operation-not-allowed':
        return 'Login email/password belum '
            'diaktifkan di Firebase.';

      case 'requires-recent-login':
        return 'Silakan login ulang untuk '
            'melakukan tindakan ini.';

      default:
        return 'Terjadi kesalahan autentikasi: '
            '$code';
    }
  }

  // ============================================================
  // RESTORE SESSION
  // ============================================================

  Future<bool> restore() async {
    var user = _auth.currentUser;

    if (user == null) {
      await _updateSession(null);
      return false;
    }

    final usesPassword =
        user.providerData.any(
      (provider) =>
          provider.providerId == 'password',
    );

    if (usesPassword) {
      await user.reload();

      user = _auth.currentUser;

      if (user == null ||
          !user.emailVerified) {
        await _auth.signOut();

        await _updateSession(null);

        return false;
      }
    }

    await _updateSession(user);

    return true;
  }

  // ============================================================
  // VALID TOKEN
  // ============================================================

  Future<String> validToken() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Silakan login.',
      );
    }

    final usesPassword =
        user.providerData.any(
      (provider) =>
          provider.providerId == 'password',
    );

    if (usesPassword) {
      await user.reload();

      final refreshedUser =
          _auth.currentUser;

      if (refreshedUser == null ||
          !refreshedUser.emailVerified) {
        await _auth.signOut();

        await _updateSession(null);

        throw Exception(
          'Email belum diverifikasi. '
          'Silakan login kembali setelah verifikasi.',
        );
      }
    }

    final token =
        await _auth.currentUser!.getIdToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Sesi berakhir. Silakan login lagi.',
      );
    }

    return token;
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> deleteAccount() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Silakan login.',
      );
    }

    await user.delete();

    await _updateSession(null);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _auth.signOut();

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    AppTheme.selected.value = 0;

    await _updateSession(null);
  }
}