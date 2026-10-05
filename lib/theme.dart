import 'package:flutter/material.dart';

class PastelColor {
  final String name;
  final Color color;
  const PastelColor(this.name, this.color);
}

class AppTheme {
  static const palette = <PastelColor>[
    PastelColor('Krem', Color(0xFFFFF8F0)),
    PastelColor('Rose', Color(0xFFFDE2E4)),
    PastelColor('Mint', Color(0xFFE2F0EA)),
    PastelColor('Biru', Color(0xFFDFE7FD)),
    PastelColor('Peach', Color(0xFFFFE8D6)),
    PastelColor('Lavender', Color(0xFFE8E1F5)),
    PastelColor('Langit', Color(0xFFD7EEF5)),
    PastelColor('Lemon', Color(0xFFF3F5D3)),
  ];

  /// Indeks warna latar yang sedang dipakai.
  static final selected = ValueNotifier<int>(0);

  static const accent = Color(0xFF6F7FA8);
}
