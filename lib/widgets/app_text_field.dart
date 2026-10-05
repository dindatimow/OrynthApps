import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Extract widget: TextField dengan dekorasi konsisten.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final Widget? suffix;
  final int? maxLength;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool isSecret;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.suffix,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.isSecret = false,
  });

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      autocorrect: !isSecret,
      enableSuggestions: !isSecret,
      enableIMEPersonalizedLearning: !isSecret,
      inputFormatters: [
        // Blokir karakter kontrol; baris baru tetap diizinkan.
        FilteringTextInputFormatter.deny(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixIcon: suffix,
        counterText: '',
        filled: true,
        fillColor: Colors.white.withValues(alpha:0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.black12),
        focusedBorder: _border(AppTheme.accent, 1.6),
        errorBorder: _border(Colors.redAccent.shade100),
        focusedErrorBorder: _border(Colors.redAccent, 1.6),
      ),
    );
  }
}
