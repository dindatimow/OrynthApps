import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

/// Pembungkus HTTP: HTTPS-only, timeout, pesan error generik (tanpa bocor detail internal).
class Api {
  static const _timeout = Duration(seconds: 15);

  static Future<dynamic> send(
    String method,
    Uri uri, {
    String? body,
    String contentType = 'application/json',
  }) async {
    if (uri.scheme != 'https') {
      throw ApiException('Koneksi tidak aman diblokir.');
    }
    final req = http.Request(method, uri);
    req.headers['Content-Type'] = contentType;
    req.headers['Accept'] = 'application/json';
    if (body != null) req.body = body;

    try {
      final streamed = await req.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed).timeout(_timeout);
      final text = utf8.decode(res.bodyBytes);
      dynamic data;
      if (text.isNotEmpty) {
        try {
          data = jsonDecode(text);
        } catch (_) {
          data = null;
        }
      }
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      throw ApiException(_friendly(data, res.statusCode), res.statusCode);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw ApiException('Permintaan terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw ApiException('Gagal terhubung ke server.');
    }
  }

  static Future<dynamic> getJson(Uri u) => send('GET', u);
  static Future<dynamic> postJson(Uri u, Object b) => send('POST', u, body: jsonEncode(b));
  static Future<dynamic> putJson(Uri u, Object b) => send('PUT', u, body: jsonEncode(b));
  static Future<dynamic> patchJson(Uri u, Object b) => send('PATCH', u, body: jsonEncode(b));
  static Future<dynamic> delete(Uri u) => send('DELETE', u);

  static String _friendly(dynamic data, int status) {
    String code = '';
    if (data is Map) {
      final e = data['error'];
      if (e is Map && e['message'] is String) code = e['message'] as String;
      if (e is String) code = e;
    }
    if (code.startsWith('WEAK_PASSWORD')) return 'Password terlalu lemah.';
    if (code.startsWith('TOO_MANY_ATTEMPTS')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    }
    // Pesan generik agar tidak membocorkan apakah email terdaftar (anti user enumeration).
    const authErrors = [
      'INVALID_LOGIN_CREDENTIALS', 'INVALID_PASSWORD', 'EMAIL_NOT_FOUND', 'USER_DISABLED'
    ];
    if (authErrors.any(code.startsWith)) return 'Email atau password salah.';
    if (code.startsWith('EMAIL_EXISTS')) {
      return 'Pendaftaran gagal. Gunakan email lain atau coba login.';
    }
    if (status == 401 || status == 403 || code.contains('Permission denied')) {
      return 'Akses ditolak. Silakan login ulang dan pastikan email sudah diverifikasi.';
    }
    if (status >= 500) return 'Server sedang bermasalah. Coba lagi nanti.';
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
