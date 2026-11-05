import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';
import '../auth/otp_input.dart';

class OtpVerificationContent extends StatelessWidget {
  const OtpVerificationContent({
    super.key,
    required this.title,
    required this.description,
    required this.whatsAppLabel,
    required this.phoneNumber,
    required this.codeLabel,
    required this.inputKey,
    required this.errorText,
    required this.digitLabel,
    required this.onCodeChanged,
    required this.resendLabel,
    required this.isArabic,
    required this.canResend,
    required this.onResend,
  });

  final String title;
  final String description;
  final String whatsAppLabel;
  final String phoneNumber;
  final String codeLabel;
  final Key inputKey;
  final String? errorText;
  final String Function(int index) digitLabel;
  final ValueChanged<String> onCodeChanged;
  final String resendLabel;
  final bool isArabic;
  final bool canResend;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColor.otpText,
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$description '),
              TextSpan(text: whatsAppLabel),
              const TextSpan(text: ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    phoneNumber,
                    style: const TextStyle(
                      color: AppColor.otpText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          style: const TextStyle(
            color: AppColor.otpSupportingText,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          codeLabel,
          style: const TextStyle(
            color: AppColor.otpText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        OtpInput(
          key: inputKey,
          errorText: errorText,
          digitLabel: digitLabel,
          onChanged: onCodeChanged,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
          child: TextButton(
            onPressed: canResend ? onResend : null,
            child: Text(resendLabel),
          ),
        ),
      ],
    );
  }
}
