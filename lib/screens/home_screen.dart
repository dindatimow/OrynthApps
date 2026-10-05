import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/api.dart';
import '../services/auth_service.dart';
import '../services/notes_service.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

/// StatefulWidget: daftar catatan (READ), cari, hapus (DELETE), ganti warna (PATCH).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = NotesService.instance;
  final _search = TextEditingController();
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadTheme();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _notes = await _svc.fetchAll();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadTheme() async {
    try {
      final i = await _svc.getBgColor();
      if (i != null && i >= 0 && i < AppTheme.palette.length) {
        AppTheme.selected.value = i;
      }
    } catch (_) {}
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  Future<void> _open([Note? n]) async {
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => NoteEditorScreen(note: n)));
    if (changed == true) _load();
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya')),
          ],
        ),
      ) ??
      false;

  Future<void> _delete(Note n) async {
    if (!await _confirm('Hapus catatan?', '"${n.title}" akan dihapus permanen.')) return;
    try {
      await _svc.remove(n.id!);
      setState(() => _notes.removeWhere((x) => x.id == n.id));
      _toast('Catatan dihapus');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _togglePin(Note n) async {
    final next = !n.pinned;
    try {
      await _svc.setPinned(n.id!, next);
      setState(() {
        _notes = _notes.map((x) => x.id == n.id ? x.copyWith(pinned: next) : x).toList()
          ..sort(NotesService.compare);
      });
      _toast(next ? 'Catatan disematkan' : 'Sematan dilepas');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  void _pickColor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ColorPickerSheet(
        selected: AppTheme.selected.value,
        onSelect: (i) async {
          AppTheme.selected.value = i;
          Navigator.pop(context);
          try {
            await _svc.setBgColor(i);
          } on ApiException catch (e) {
            _toast(e.message);
          }
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (!await _confirm('Hapus akun?', 'Semua catatan & akun akan dihapus permanen.')) return;
    try {
      await _svc.deleteAllMyData();
      await AuthService.instance.deleteAccount();
    } on ApiException catch (e) {
      _toast('${e.message} (Jika perlu, logout & login ulang lalu coba lagi.)');
    }
  }

  List<Note> get _filtered {
    final q = _query.toLowerCase();
    if (q.isEmpty) return _notes;
    return _notes
        .where((n) => n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('OrynthApps', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(tooltip: 'Warna latar', icon: const Icon(Icons.palette_outlined), onPressed: _pickColor),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') AuthService.instance.logout();
              if (v == 'delete') _deleteAccount();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(AuthService.instance.email ?? '', style: const TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'logout', child: Text('Keluar')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus akun')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        onPressed: () => _open(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppTextField(
              controller: _search,
              label: 'Cari catatan',
              icon: Icons.search,
              maxLength: 100,
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _body(items),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _body(List<Note> items) {
    if (_loading && _notes.isEmpty) {
      return ListView(children: const [SizedBox(height: 200), Center(child: CircularProgressIndicator())]);
    }
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(_error!, textAlign: TextAlign.center)),
        TextButton(onPressed: _load, child: const Text('Coba lagi')),
      ]);
    }
    if (items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Icon(Icons.sticky_note_2_outlined, size: 64, color: Colors.grey.shade500),
        const SizedBox(height: 8),
        Center(
          child: Text(_query.isEmpty ? 'Belum ada catatan.\nKetuk “+ Catatan” untuk mulai.' : 'Tidak ditemukan.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
        ),
      ]);
    }
    // Responsif: jumlah kolom menyesuaikan lebar layar.
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisExtent: 140,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => NoteCard(
        note: items[i],
        onTap: () => _open(items[i]),
        onDelete: () => _delete(items[i]),
        onPin: () => _togglePin(items[i]),
      ),
    );
  }
}
