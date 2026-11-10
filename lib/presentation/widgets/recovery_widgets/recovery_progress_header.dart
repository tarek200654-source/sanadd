import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../shared_widgets/app_back_button.dart';
import '../shared_widgets/auth_screen_styles.dart';

enum RecoveryStep { email, phone, otp, resetPassword }

class RecoveryProgressHeader extends StatelessWidget {
  const RecoveryProgressHeader({
    super.key,
    required this.step,
    required this.onBack,
    this.horizontalPadding = 28,
  });

  final RecoveryStep step;
  final VoidCallback onBack;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppBackButton(
            onPressed: onBack,
            tooltip: context.l10n.back,
            buttonSize: 40,
            imageSize: 14,
            borderColor: context.sanadBorder,
            foregroundColor: context.sanadText,
          ),
          Row(
            children: List.generate(
              4,
              (index) => Semantics(
                label: context.l10n.isArabic
                    ? 'الخطوة ${index + 1} من 4'
                    : 'Step ${index + 1} of 4',
                selected: index <= step.index,
                child: AnimatedContainer(
                  key: ValueKey('recovery-progress-segment-$index'),
                  duration: const Duration(milliseconds: 400),
                  width: index == step.index ? 24 : 10,
                  height: 4,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: index <= step.index
                        ? context.sanadText
                        : context.sanadBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
