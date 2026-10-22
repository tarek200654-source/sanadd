import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

class OtpVerificationSubmitButton extends StatelessWidget {
  const OtpVerificationSubmitButton({
    super.key,
    required this.isBusy,
    required this.isSending,
    required this.isVerified,
    required this.verifyLabel,
    required this.verifiedLabel,
    required this.onPressed,
  });

  final bool isBusy;
  final bool isSending;
  final bool isVerified;
  final String verifyLabel;
  final String verifiedLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLoading = isBusy || isSending;

    return SizedBox(
      height: 58,
      child: FilledButton(
        key: const ValueKey('otp-verify-submit'),
        onPressed: isLoading || isVerified ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.otpText,
          foregroundColor: AppColor.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColor.surface,
                ),
              )
            : Text(isVerified ? verifiedLabel : verifyLabel),
      ),
    );
  }
}
