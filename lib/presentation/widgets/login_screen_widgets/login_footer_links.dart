import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared_widgets/auth_screen_styles.dart';

class LoginFooterLinks extends StatelessWidget {
  final bool isArabic;
  const LoginFooterLinks({required this.isArabic});
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final s = t(
      fontSize: 13,
      color: context.sanadDim,
      fontWeight: FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy', style: s),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('|', style: s.copyWith(color: context.sanadBorder)),
        ),
        Text(isArabic ? 'الشروط والأحكام' : 'Terms', style: s),
      ],
    );
  }
}
