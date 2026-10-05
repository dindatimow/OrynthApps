import 'package:flutter/services.dart';

class SecurityReport {
  final bool rooted;
  final bool debugger;
  const SecurityReport({this.rooted = false, this.debugger = false});
  bool get compromised => rooted || debugger;
}

/// Jembatan ke kode native Kotlin (MainActivity) untuk deteksi root & debugger.
class DeviceSecurity {
  static const _channel = MethodChannel('orynth_apps/security');

  static Future<SecurityReport> check() async {
    try {
      final m = await _channel.invokeMapMethod<String, dynamic>('check');
      return SecurityReport(rooted: m?['rooted'] == true, debugger: m?['debugger'] == true);
    } catch (_) {
      // Fail-open agar app tetap bisa berjalan di platform tanpa implementasi native.
      return const SecurityReport();
    }
  }
}
