import 'package:flutter/material.dart';

abstract final class AppColor {
  // SANAD's new visual language is built around a calm, clinical blue-gray
  // canvas, charcoal actions, and a small mint status accent.
  static const Color primary = Color(0xFF212529);
  static const Color primaryDark = Color(0xFF111820);
  static const Color secondary = Color(0xFFE7F0F8);
  static const Color tertiary = Color(0xFF10B981);
  static const Color neutral = Color(0xFFF4F8FC);
  static const Color background = Color(0xFFF4F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFE7F0F8);
  static const Color textPrimary = Color(0xFF111820);
  static const Color textSecondary = Color(0xFF52606D);
  static const Color mutedText = Color(0xFF7B8794);
  static const Color border = Color(0xFFD6E0EA);
  static const Color indicatorActive = Color(0xFF212529);
  static const Color indicatorInactive = Color(0xFFD9E3EC);
  static const Color success = Color(0xFF10B981);
  static const Color alert = Color(0xFFEF4444);

  static ThemeData theme({required bool isArabic}) {
    final fontFamily = isArabic ? 'Tajawal' : 'Poppins';

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      fontFamilyFallback: const ['Arial'],
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontFamily: fontFamily,
          fontSize: 12,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
