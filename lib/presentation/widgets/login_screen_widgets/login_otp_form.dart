import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared_widgets/auth_screen_styles.dart';
import 'login_screen_action_button.dart';

class LoginOtpForm extends StatelessWidget {
  final bool isArabic, loading;
  final List<TextEditingController> digits;
  final List<FocusNode> focusNodes;
  final String? subtitle;
  final int resendLeft;
  final VoidCallback onDigitChanged, onSubmit;
  final VoidCallback? onResend;
  const LoginOtpForm({
    required this.isArabic,
    required this.loading,
    required this.digits,
    required this.focusNodes,
    required this.onSubmit,
    required this.onDigitChanged,
    this.subtitle,
    this.onResend,
    this.resendLeft = 0,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Column(
      key: const ValueKey('otp'),
      children: [
        const SizedBox(height: 40),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isKeyboardVisible ? 0.3 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'كود التحقق' : 'OTP Verification',
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
                            ? 'أدخل الكود المكون من 4 أرقام المرسل لبريدك:\n$subtitle'
                            : 'Enter the 4-digit code sent to your email:\n$subtitle',
                        style: t(
                          fontSize: 16,
                          color: context.sanadDim,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: context.sanadCardInner,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: focusNodes[i].hasFocus
                                  ? context.sanadText
                                  : context.sanadBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: digits[i],
                              focusNode: focusNodes[i],
                              enabled: !loading,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: t(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: context.sanadText,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty && i < 3)
                                  focusNodes[i + 1].requestFocus();
                                if (v.isEmpty && i > 0)
                                  focusNodes[i - 1].requestFocus();
                                onDigitChanged();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                LoginScreenActionButton(
                  text: isArabic ? 'استمرار' : 'Continue',
                  loading: loading,
                  onTap: onSubmit,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TextButton(
                    onPressed: (loading || resendLeft > 0) ? null : onResend,
                    child: Text(
                      resendLeft > 0
                          ? (isArabic
                                ? 'إرسال خلال ${resendLeft}ث'
                                : 'Resend in ${resendLeft}s')
                          : (isArabic ? 'إعادة إرسال الكود' : 'Resend Code'),
                      style: t(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.sanadText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
