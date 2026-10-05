/// Nilai diinjeksi saat build/run lewat --dart-define (tidak di-hardcode di source).
class AppConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const dbUrl = String.fromEnvironment('FIREBASE_DB_URL');

  /// Izinkan perangkat root di build release (default: diblokir).
  static const allowCompromised = bool.fromEnvironment('ALLOW_ROOTED');

  /// Auto-logout bila app di background lebih lama dari ini.
  static const idleTimeout = Duration(minutes: 5);

  static bool get isValid =>
      apiKey.isNotEmpty && dbUrl.startsWith('https://') && !dbUrl.endsWith('/');
}
