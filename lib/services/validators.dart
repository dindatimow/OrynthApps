/// Validasi & sanitasi input (defense in depth; server tetap divalidasi lewat Security Rules).
class Validators {
  static final _emailRe = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$");
  static final _tagRe = RegExp(r'<[^>]*>');
  static final _ctrlRe = RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]');
  static final idRe = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email wajib diisi';
    if (s.length > 254 || !_emailRe.hasMatch(s)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (s.length < 10) return 'Minimal 10 karakter';
    if (s.length > 128) return 'Maksimal 128 karakter';
    if (!RegExp(r'[a-z]').hasMatch(s)) return 'Harus ada huruf kecil';
    if (!RegExp(r'[A-Z]').hasMatch(s)) return 'Harus ada huruf besar';
    if (!RegExp(r'\d').hasMatch(s)) return 'Harus ada angka';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(s)) return 'Harus ada simbol';
    return null;
  }

  static String? title(String? v) {
    final s = sanitize(v ?? '');
    if (s.isEmpty) return 'Judul wajib diisi';
    if (s.length > 100) return 'Maksimal 100 karakter';
    return null;
  }

  static String? content(String? v) =>
      (v ?? '').length > 5000 ? 'Maksimal 5000 karakter' : null;

  /// Hapus tag HTML/script, karakter kontrol, dan tanda < > yang tersisa (anti-XSS/injection).
  static String sanitize(String input) => input
      .replaceAll(_ctrlRe, '')
      .replaceAll(_tagRe, '')
      .replaceAll(RegExp(r'[<>]'), '')
      .trim();
}
