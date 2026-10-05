
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isRegister = false;
  bool _busy = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _msg(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _submit() async {
    if (_busy) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);

    try {
      if (_isRegister) {
        await AuthService.instance.registerWithEmail(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        _msg(
          'Akun berhasil dibuat. '
          'Silakan cek email untuk verifikasi.',
        );

        setState(() {
          _isRegister = false;
          _passwordController.clear();
          _confirmController.clear();
          _emailController.clear();
          _usernameController.clear();
        });
      } else {
        await AuthService.instance.loginWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      _msg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await AuthService.instance.loginWithGoogle();
    } catch (e) {
      _msg(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // KIRIM ULANG EMAIL VERIFIKASI
  Future<void> _resendVerification() async {
    if (_busy) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _msg(
        'Isi email dan password terlebih dahulu.',
      );
      return;
    }

    if (!email.contains('@')) {
      _msg(
        'Untuk kirim ulang verifikasi, '
        'masukkan alamat email, bukan username.',
      );
      return;
    }

    setState(() => _busy = true);

    try {
      await AuthService.instance
          .resendVerificationEmailWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      _msg(
        'Permintaan verifikasi berhasil dikirim. '
        'Periksa Inbox dan folder Spam email kamu.',
      );
    } catch (e) {
      _msg(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Masukkan alamat email yang valid.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password wajib diisi.';
    }

    if (_isRegister && password.length < 12) {
      return 'Password minimal 12 karakter.';
    }

    return null;
  }

  InputDecoration _decoration(
    String label, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade400,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppTheme.accent,
          width: 1.8,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      decoration: _decoration('Username'),
      validator: (value) {
        if (!_isRegister) return null;

        final username = value?.trim() ?? '';

        if (username.isEmpty) {
          return 'Username wajib diisi.';
        }

        if (username.length < 3 ||
            username.length > 20) {
          return 'Username harus 3-20 karakter.';
        }

        if (!RegExp(r'^[a-zA-Z0-9_]+$')
            .hasMatch(username)) {
          return 'Gunakan hanya huruf, angka, dan underscore.';
        }

        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: _isRegister
          ? TextInputType.emailAddress
          : TextInputType.text,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: _decoration(
        _isRegister ? 'Email' : 'Username atau email',
      ),
      validator: _isRegister
          ? _validateEmail
          : (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Username atau email wajib diisi.';
              }
              return null;
            },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _hidePassword,
      textInputAction:
          _isRegister
              ? TextInputAction.next
              : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (!_isRegister) _submit();
      },
      decoration: _decoration(
        'Password',
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _hidePassword = !_hidePassword;
            });
          },
          icon: Icon(
            _hidePassword
                ? Icons.visibility_off
                : Icons.visibility,
          ),
        ),
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildConfirmField() {
    return TextFormField(
      controller: _confirmController,
      obscureText: _hideConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      decoration: _decoration(
        'Konfirmasi password',
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _hideConfirm = !_hideConfirm;
            });
          },
          icon: Icon(
            _hideConfirm
                ? Icons.visibility_off
                : Icons.visibility,
          ),
        ),
      ),
      validator: (value) {
        if (!_isRegister) return null;

        if (value == null || value.isEmpty) {
          return 'Konfirmasi password wajib diisi.';
        }

        if (value != _passwordController.text) {
          return 'Konfirmasi password tidak cocok.';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      size: 72,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isRegister
                          ? 'Buat akun'
                          : 'Selamat datang',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRegister
                          ? 'Daftar untuk mulai menyimpan catatanmu'
                          : 'Masuk untuk membuka catatanmu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_isRegister) ...[
                      _buildUsernameField(),
                      const SizedBox(height: 16),
                    ],

                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),

                    if (_isRegister) ...[
                      const SizedBox(height: 16),
                      _buildConfirmField(),
                      const SizedBox(height: 8),
                      Text(
                        'Gunakan password minimal 12 karakter.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isRegister
                                    ? 'Daftar'
                                    : 'Masuk',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    // Tombol kirim ulang verifikasi
                    if (!_isRegister) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : _resendVerification,
                        child: const Text(
                          'Kirim Ulang Email Verifikasi',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegister
                              ? 'Sudah punya akun? '
                              : 'Belum punya akun? ',
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _isRegister =
                                        !_isRegister;
                                    _formKey.currentState
                                        ?.reset();
                                    _passwordController
                                        .clear();
                                    _confirmController
                                        .clear();
                                  });
                                },
                          child: Text(
                            _isRegister ? 'Login' : 'Daftar',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (!_isRegister) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              'atau',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : _loginWithGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 30,
                          ),
                          label: const Text(
                            'Lanjutkan dengan Google',
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                AppTheme.accent,
                            side: const BorderSide(
                              color: AppTheme.accent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gunakan akun Google untuk masuk ke OrynthApps.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}