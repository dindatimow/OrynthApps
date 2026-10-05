import 'package:flutter/foundation.dart'
    show kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_options.dart';
import 'config.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/device_security.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!AppConfig.isValid) {
    runApp(const _ConfigError());
    return;
  }

  // ============================================================
  // CLOUD FUNCTIONS EMULATOR
  // ============================================================
  //
  // Firebase Authentication tetap menggunakan Firebase asli.
  //
  // Cloud Functions pada mode debug menggunakan emulator
  // yang berjalan di laptop pada:
  //
  // 192.168.1.5:5001
  //
  if (kDebugMode) {
    FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    ).useFunctionsEmulator(
      '192.168.1.5',
      5001,
    );
  }

  final report = await DeviceSecurity.check();

  if (kReleaseMode &&
      report.compromised &&
      !AppConfig.allowCompromised) {
    runApp(const _BlockedApp());
    return;
  }

  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppTheme.selected,
      builder: (_, i, __) => MaterialApp(
        title: 'OrynthApps',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: AppTheme.accent,
          scaffoldBackgroundColor:
              AppTheme.palette[i].color,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with WidgetsBindingObserver {
  late final Future<bool> _restore =
      AuthService.instance.restore();

  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;

      if (p != null &&
          AuthService.instance.signedIn.value &&
          DateTime.now().difference(p) >
              AppConfig.idleTimeout) {
        AuthService.instance.logout();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restore,
      builder: (_, snap) {
        if (snap.connectionState !=
            ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable:
              AuthService.instance.signedIn,
          builder: (_, signed, __) =>
              signed
                  ? const HomeScreen()
                  : const AuthScreen(),
        );
      },
    );
  }
}

class _ConfigError extends StatelessWidget {
  const _ConfigError();

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Konfigurasi belum diisi.\n'
                'Jalankan dengan '
                '--dart-define=FIREBASE_API_KEY=... '
                'dan '
                '--dart-define=FIREBASE_DB_URL=... '
                '(tanpa "/" di akhir).',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}

class _BlockedApp extends StatelessWidget {
  const _BlockedApp();

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Demi keamanan data kamu, '
                'aplikasi tidak dapat dijalankan\n'
                'pada perangkat yang di-root '
                'atau sedang di-debug.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}