import 'package:flutter/material.dart';
import '../theme.dart';

/// Extract widget: pemilih warna latar pastel.
class ColorPickerSheet extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const ColorPickerSheet({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Warna latar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(spacing: 14, runSpacing: 14, children: [
            for (var i = 0; i < AppTheme.palette.length; i++)
              GestureDetector(
                onTap: () => onSelect(i),
                child: Column(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.palette[i].color,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: i == selected ? AppTheme.accent : Colors.black12,
                          width: i == selected ? 3 : 1),
                    ),
                    child: i == selected ? const Icon(Icons.check, color: AppTheme.accent) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(AppTheme.palette[i].name, style: const TextStyle(fontSize: 11)),
                ]),
              ),
          ]),
        ]),
      ),
    );
  }
}
