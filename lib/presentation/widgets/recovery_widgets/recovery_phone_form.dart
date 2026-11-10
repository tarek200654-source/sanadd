import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color.dart';
import '../shared_widgets/auth_form_input.dart';
import '../shared_widgets/auth_screen_styles.dart';
import 'recovery_progress_header.dart';

/// Recovery-owned copy of the existing phone-step presentation.
class RecoveryPhoneForm extends StatelessWidget {
  const RecoveryPhoneForm({
    super.key,
    required this.isArabic,
    required this.phone,
    required this.countryCode,
    required this.expectedPhoneLength,
    required this.onBack,
    required this.onNext,
    required this.onCountryCodeTap,
    this.errorText,
  });

  final bool isArabic;
  final TextEditingController phone;
  final String countryCode;
  final int expectedPhoneLength;
  final VoidCallback onBack, onNext, onCountryCodeTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isCompact = MediaQuery.sizeOf(context).height < 720;
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final canNext = phone.text.trim().length == expectedPhoneLength;
    return Column(
      children: [
        RecoveryProgressHeader(step: RecoveryStep.phone, onBack: onBack),
        SizedBox(height: isKeyboardVisible ? 12 : (isCompact ? 18 : 32)),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isKeyboardVisible ? 0.3 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'رقم الهاتف' : 'Phone number',
                  style: t(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: context.sanadText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'يرجى إكمال البيانات للمتابعة'
                      : 'Please complete the details to continue',
                  style: t(fontSize: 15, color: context.sanadDim),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isKeyboardVisible ? 12 : (isCompact ? 18 : 32)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthFormInput(
                    inputKey: const ValueKey('recovery-phone-field'),
                    label: isArabic ? 'رقم الهاتف' : 'Phone',
                    controller: phone,
                    isArabic: isArabic,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(expectedPhoneLength),
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) =>
                            newValue.text.startsWith('0') ? oldValue : newValue,
                      ),
                    ],
                    hint: isArabic
                        ? 'أدخل $expectedPhoneLength أرقام'
                        : 'Enter $expectedPhoneLength digits',
                    prefix: GestureDetector(
                      onTap: onCountryCodeTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: context.sanadBorder,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              countryCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: t(color: AppColor.loginError, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            12,
            28,
            isKeyboardVisible ? 12 : (isCompact ? 16 : 24),
          ),
          child: GestureDetector(
            onTap: canNext ? onNext : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: canNext ? 1 : 0.3,
              child: Container(
                key: const ValueKey('recovery-phone-next'),
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  color: context.sanadText,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColor.loginShadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isArabic ? 'التالي' : 'Next',
                    style: t(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.isDark
                          ? AppColor.loginActionForegroundDarkTheme
                          : AppColor.loginActionForegroundLightTheme,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
