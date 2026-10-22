import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color.dart';
import 'auth_screen_styles.dart';

class AuthFormInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure, isArabic;
  final IconData? icon;
  final Widget? suffix, extraLabel, prefix;
  final bool error;
  final String? helperText, hint;
  final Color? helperColor;
  final Key? inputKey;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  const AuthFormInput({
    this.inputKey,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.isArabic = false,
    this.icon,
    this.suffix,
    this.extraLabel,
    this.prefix,
    this.error = false,
    this.helperText,
    this.helperColor,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: t(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.sanadInputLabel,
                ),
              ),
              if (extraLabel != null) extraLabel!,
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.sanadCardInner,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error ? AppColor.loginError : context.sanadBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null) prefix!,
              Expanded(
                child: TextField(
                  key: inputKey,
                  controller: controller,
                  maxLines: maxLines,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  cursorColor: context.sanadText,
                  style: t(color: context.sanadText, fontSize: 16),
                  onChanged: (_) => (context as Element).markNeedsBuild(),
                  decoration: InputDecoration(
                    prefixIcon: icon != null
                        ? Icon(icon, color: context.sanadDim, size: 22)
                        : null,
                    suffixIcon: suffix,
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (helperText != null && helperText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              helperText!,
              style: t(
                fontSize: 12,
                color: helperColor ?? context.sanadDim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
