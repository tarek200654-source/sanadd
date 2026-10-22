import 'package:flutter/material.dart';

import '../auth/sanad_auth_logo.dart';
import '../shared_widgets/app_back_button.dart';

class OtpVerificationHeader extends StatelessWidget {
  const OtpVerificationHeader({
    super.key,
    required this.backLabel,
    required this.onBack,
  });

  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBackButton(
          buttonSize: 44,
          imageSize: 18,
          tooltip: backLabel,
          onPressed: onBack,
        ),
        const Spacer(),
        const SanadAuthLogo(artworkWidth: 100),
        const Spacer(),
        const SizedBox(width: 44),
      ],
    );
  }
}
