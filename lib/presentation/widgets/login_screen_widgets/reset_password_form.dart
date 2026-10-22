import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared_widgets/auth_screen_styles.dart';
import 'login_screen_action_button.dart';
import '../shared_widgets/auth_form_input.dart';
import '../shared_widgets/password_strength_dots.dart';

class ResetPasswordForm extends StatelessWidget {
  final bool isArabic,
      loading,
      obscure,
      obscureConfirm,
      minLen,
      hasUpper,
      hasNum,
      hasSpec,
      passMatch;
  final TextEditingController pass, confirm;
  final VoidCallback onBack, onSubmit, onToggleObscure, onToggleConfirm;
  const ResetPasswordForm({
    required this.isArabic,
    required this.loading,
    required this.pass,
    required this.confirm,
    required this.obscure,
    required this.obscureConfirm,
    required this.minLen,
    required this.hasUpper,
    required this.hasNum,
    required this.hasSpec,
    required this.passMatch,
    required this.onBack,
    required this.onSubmit,
    required this.onToggleObscure,
    required this.onToggleConfirm,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Column(
      key: const ValueKey('reset'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'كلمة مرور جديدة' : 'New Password',
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
              ? 'من فضلك أدخل كلمة مرور قوية وجديدة.'
              : 'Please enter a strong new password.',
          style: t(fontSize: 16, color: context.sanadDim, height: 1.5),
        ),
        const SizedBox(height: 40),
        AuthFormInput(
          label: isArabic ? 'كلمة المرور' : 'Password',
          controller: pass,
          obscure: obscure,
          isArabic: isArabic,
          icon: Icons.password_rounded,
          suffix: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: context.sanadDim,
            ),
            onPressed: onToggleObscure,
          ),
          extraLabel: PasswordStrengthDots(
            status: [minLen, hasUpper, hasNum, hasSpec],
          ),
          hint: '********',
        ),
        const SizedBox(height: 20),
        AuthFormInput(
          label: isArabic ? 'تأكيد كلمة المرور' : 'Confirm',
          controller: confirm,
          obscure: obscureConfirm,
          isArabic: isArabic,
          icon: Icons.password_rounded,
          suffix: IconButton(
            icon: Icon(
              obscureConfirm
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: context.sanadDim,
            ),
            onPressed: onToggleConfirm,
          ),
          hint: '••••••••',
        ),
        const SizedBox(height: 32),
        LoginScreenActionButton(
          text: isArabic ? 'حفظ' : 'Save',
          loading: loading,
          onTap: onSubmit,
          isArabic: isArabic,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: Text(
              isArabic ? 'رجوع' : 'Back',
              style: t(color: context.sanadDim, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
