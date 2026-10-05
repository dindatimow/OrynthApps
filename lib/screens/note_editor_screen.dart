import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/api.dart';
import '../services/notes_service.dart';
import '../services/validators.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';

/// StatefulWidget: tambah (POST) / ubah (PUT) catatan.
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _content = TextEditingController(text: widget.note?.content ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final svc = NotesService.instance;
      if (widget.note == null) {
        await svc.create(_title.text, _content.text);
      } else {
        await svc.replace(widget.note!, _title.text, _content.text);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.note == null ? 'Catatan baru' : 'Ubah catatan'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check, color: AppTheme.accent),
            label: const Text('Simpan'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                AppTextField(
                  controller: _title,
                  label: 'Judul',
                  icon: Icons.title,
                  maxLength: 100,
                  validator: Validators.title,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _content,
                  label: 'Isi catatan',
                  hint: 'Tulis sesuatu...',
                  maxLength: 5000,
                  maxLines: 14,
                  keyboardType: TextInputType.multiline,
                  validator: Validators.content,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
