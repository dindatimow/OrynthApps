import '../config.dart';
import '../models/note.dart';
import 'api.dart';
import 'auth_service.dart';
import 'validators.dart';

/// CRUD ke Firebase Realtime Database via REST:
/// POST (create), GET (read), PUT (replace), PATCH (partial), DELETE.
class NotesService {
  NotesService._();
  static final instance = NotesService._();
  final _auth = AuthService.instance;

  Future<Uri> _uri(String path) async {
    final token = await _auth.validToken();
    final uid = _auth.uid;
    if (uid == null) throw ApiException('Silakan login.');
    return Uri.parse('${AppConfig.dbUrl}/users/$uid/$path.json')
        .replace(queryParameters: {'auth': token});
  }

  String _checkId(String id) {
    if (!Validators.idRe.hasMatch(id)) throw ApiException('ID tidak valid.');
    return id;
  }

  /// Catatan tersemat di atas, lalu terbaru.
  static int compare(Note a, Note b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  // READ (GET)
  Future<List<Note>> fetchAll() async {
    final data = await Api.getJson(await _uri('notes'));
    if (data is! Map) return [];
    final list = <Note>[];
    data.forEach((k, v) {
      if (k is String && Validators.idRe.hasMatch(k)) {
        final n = Note.fromJson(k, v);
        if (n != null) list.add(n);
      }
    });
    list.sort(compare);
    return list;
  }

  // CREATE (POST)
  Future<String> create(String title, String content) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(
      title: Validators.sanitize(title),
      content: Validators.sanitize(content),
      createdAt: now,
      updatedAt: now,
    );
    final res = await Api.postJson(await _uri('notes'), note.toJson());
    return (res is Map ? res['name'] : null) as String? ?? '';
  }

  // UPDATE penuh (PUT)
  Future<void> replace(Note old, String title, String content) async {
    final id = _checkId(old.id ?? '');
    final note = Note(
      title: Validators.sanitize(title),
      content: Validators.sanitize(content),
      createdAt: old.createdAt,
      pinned: old.pinned,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await Api.putJson(await _uri('notes/$id'), note.toJson());
  }

  // DELETE
  Future<void> remove(String id) async {
    await Api.delete(await _uri('notes/${_checkId(id)}'));
  }

  // PIN catatan (PATCH parsial: hanya field `pinned`)
  Future<void> setPinned(String id, bool pinned) async {
    await Api.patchJson(await _uri('notes/${_checkId(id)}'), {'pinned': pinned});
  }

  // Pengaturan tema: GET + PATCH
  Future<int?> getBgColor() async {
    final v = await Api.getJson(await _uri('settings/bgColor'));
    return v is int ? v : null;
  }

  Future<void> setBgColor(int index) async {
    await Api.patchJson(await _uri('settings'), {'bgColor': index});
  }

  Future<void> deleteAllMyData() async {
    await Api.delete(await _uri('notes'));
    await Api.delete(await _uri('settings'));
  }
}
