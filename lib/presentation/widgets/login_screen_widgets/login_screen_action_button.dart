import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared_widgets/auth_screen_styles.dart';
import 'login_screen_squares_loading.dart';

class LoginScreenActionButton extends StatelessWidget {
  final String text;
  final bool loading, isArabic;
  final VoidCallback onTap;
  const LoginScreenActionButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onTap,
    required this.isArabic,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Container(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.sanadText,
          foregroundColor: context.sanadBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: t(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading ? const LoginScreenSquaresLoading() : Text(text),
      ),
    );
  }
}
