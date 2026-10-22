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
    required this.canResend,
    required this.onResend,
    required this.statusText,
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
  final bool canResend;
  final VoidCallback onResend;
  final String statusText;

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
        Text(
          description,
          style: const TextStyle(
            color: AppColor.otpSupportingText,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 21,
              color: AppColor.otpText,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                whatsAppLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColor.otpSupportingText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              phoneNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: AppColor.otpText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
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
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: canResend ? onResend : null,
            child: Text(resendLabel),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          statusText,
          style: const TextStyle(
            color: AppColor.otpStatusText,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
