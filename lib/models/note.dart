class Note {
  final String? id;
  final String title;
  final String content;
  final int createdAt;
  final int updatedAt;
  final bool pinned;

  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.pinned = false,
  });

  Note copyWith({bool? pinned}) => Note(
        id: id,
        title: title,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
        pinned: pinned ?? this.pinned,
      );

  /// Parsing defensif: tipe data tak terduga dari server tidak membuat app crash.
  static Note? fromJson(String id, dynamic j) {
    if (j is! Map) return null;
    final t = j['title'], c = j['content'], ca = j['createdAt'], ua = j['updatedAt'];
    if (t is! String || c is! String || ca is! num || ua is! num) return null;
    return Note(
      id: id,
      title: t,
      content: c,
      createdAt: ca.toInt(),
      updatedAt: ua.toInt(),
      pinned: j['pinned'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'pinned': pinned,
      };
}
