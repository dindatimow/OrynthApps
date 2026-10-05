import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme.dart';

/// Extract widget (StatelessWidget): kartu catatan.
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.onPin,
  });

  static String formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String t(int n) => n.toString().padLeft(2, '0');
    return '${t(d.day)}/${t(d.month)}/${d.year} ${t(d.hour)}:${t(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha:0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: note.pinned
            ? const BorderSide(color: AppTheme.accent, width: 1.4)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: note.pinned ? 'Lepas sematan' : 'Sematkan',
                  icon: Icon(
                    note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 20,
                    color: note.pinned ? AppTheme.accent : null,
                  ),
                  onPressed: onPin,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(note.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.3)),
                ),
              ),
              Text(formatDate(note.updatedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}
