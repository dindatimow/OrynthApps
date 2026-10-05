import 'package:flutter_test/flutter_test.dart';
import 'package:orynth_apps/models/note.dart';
import 'package:orynth_apps/services/notes_service.dart';
import 'package:orynth_apps/services/validators.dart';

void main() {
  group('sanitize (anti XSS/injection)', () {
    test('menghapus tag script', () {
      expect(Validators.sanitize('<script>alert(1)</script>Halo'), 'alert(1)Halo');
    });
    test('menghapus tag dengan atribut event', () {
      expect(Validators.sanitize('<img src=x onerror=alert(1)>'), '');
    });
    test('menghapus karakter kontrol & sisa < >', () {
      expect(Validators.sanitize('a\u0000b'), 'ab');
      expect(Validators.sanitize('1 < 2'), '1  2');
    });
  });

  group('validasi input', () {
    test('email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user@example'), isNotNull);
      expect(Validators.email('a b@c.com'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
    test('password policy', () {
      expect(Validators.password('Abcdef123!'), isNull);
      expect(Validators.password('abc'), isNotNull);
      expect(Validators.password('abcdefghij1!'), 'Harus ada huruf besar');
      expect(Validators.password('ABCDEFGHIJ1!'), 'Harus ada huruf kecil');
      expect(Validators.password('Abcdefghijk!'), 'Harus ada angka');
      expect(Validators.password('Abcdefghij12'), 'Harus ada simbol');
    });
    test('judul', () {
      expect(Validators.title('   '), 'Judul wajib diisi');
      expect(Validators.title('Belanja'), isNull);
    });
    test('ID path hanya karakter aman (anti path traversal)', () {
      expect(Validators.idRe.hasMatch('-Nabc_123'), isTrue);
      expect(Validators.idRe.hasMatch('../x'), isFalse);
      expect(Validators.idRe.hasMatch('a/b'), isFalse);
      expect(Validators.idRe.hasMatch('a.json?x=1'), isFalse);
    });
  });

  group('Note model', () {
    test('parsing defensif menolak tipe salah', () {
      expect(Note.fromJson('id1', {'title': 1, 'content': 'x', 'createdAt': 1, 'updatedAt': 1}), isNull);
      expect(Note.fromJson('id1', 'bukan map'), isNull);
    });
    test('pinned default false & terbaca true', () {
      final base = {'title': 't', 'content': 'c', 'createdAt': 1, 'updatedAt': 2};
      expect(Note.fromJson('a', base)!.pinned, isFalse);
      expect(Note.fromJson('a', {...base, 'pinned': true})!.pinned, isTrue);
    });
    test('urutan: tersemat dulu, lalu terbaru', () {
      const a = Note(id: 'a', title: 'a', content: '', createdAt: 1, updatedAt: 10);
      const b = Note(id: 'b', title: 'b', content: '', createdAt: 1, updatedAt: 5, pinned: true);
      const c = Note(id: 'c', title: 'c', content: '', createdAt: 1, updatedAt: 20);
      final l = [a, b, c]..sort(NotesService.compare);
      expect(l.map((n) => n.id).toList(), ['b', 'c', 'a']);
    });
  });
}
