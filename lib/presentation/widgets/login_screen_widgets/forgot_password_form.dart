import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared_widgets/auth_screen_styles.dart';
import 'login_screen_action_button.dart';
import '../shared_widgets/auth_form_input.dart';

class ForgotPasswordForm extends StatelessWidget {
  final bool isArabic, loading;
  final TextEditingController email;
  final bool emailError;
  final int emailShake;
  final VoidCallback onSubmit;
  const ForgotPasswordForm({
    super.key,
    required this.isArabic,
    required this.loading,
    required this.email,
    this.emailError = false,
    this.emailShake = 0,
    required this.onSubmit,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Column(
      key: const ValueKey('forgot'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
          style: t(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: context.sanadText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isArabic
              ? 'أدخل بريد حسابك للتحقق منه، ثم أدخل رقم واتساب المرتبط به في الخطوة التالية.'
              : 'Enter your account email to check it, then confirm its WhatsApp number in the next step.',
          style: t(fontSize: 16, color: context.sanadDim, height: 1.5),
        ),
        const SizedBox(height: 40),
        AuthFormInput(
          label: isArabic ? 'البريد الإلكتروني' : 'Email',
          controller: email,
          isArabic: isArabic,
          icon: Icons.mail_outline_rounded,
          error: emailError,
          hint: 'name@example.com',
        ),
        const SizedBox(height: 32),
        LoginScreenActionButton(
          text: isArabic ? 'التالي' : 'Next',
          loading: loading,
          onTap: onSubmit,
          isArabic: isArabic,
        ),
      ],
    );
  }
}
