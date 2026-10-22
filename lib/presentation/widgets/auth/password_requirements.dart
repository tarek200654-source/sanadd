import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../auth/validation/auth_validators.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({
    super.key,
    required this.validation,
    required this.visible,
  });

  final PasswordValidation validation;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final l10n = context.l10n;
    final requirements = [
      (PasswordRequirement.minimumLength, l10n.passwordMinimumLength),
      (PasswordRequirement.uppercase, l10n.passwordUppercase),
      (PasswordRequirement.lowercase, l10n.passwordLowercase),
      (PasswordRequirement.digit, l10n.passwordDigit),
      (PasswordRequirement.specialCharacter, l10n.passwordSpecialCharacter),
    ];
    final rows = [
      (requirements[0], requirements[1]),
      (requirements[2], requirements[3]),
      (requirements[4], null),
    ];
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 6),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 12, 8),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...rows.map(
            (pair) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Expanded(
                    child: _RequirementRow(
                      label: pair.$1.$2,
                      satisfied: validation.satisfies(pair.$1.$1),
                    ),
                  ),
                  if (pair.$2 != null) ...[
                    const SizedBox(width: 7),
                    Expanded(
                      child: _RequirementRow(
                        label: pair.$2!.$2,
                        satisfied: validation.satisfies(pair.$2!.$1),
                      ),
                    ),
                  ] else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          _PasswordStrength(validation: validation),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      checked: satisfied,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Icon(
              satisfied
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: satisfied ? AppColor.success : AppColor.mutedText,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: satisfied
                      ? AppColor.textPrimary
                      : AppColor.textSecondary,
                  fontSize: 12,
                  fontWeight: satisfied ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.validation});

  final PasswordValidation validation;

  String _label(AppLocalizations l10n) => switch (validation.strength) {
    PasswordStrength.weak => l10n.passwordStrengthWeak,
    PasswordStrength.medium => l10n.passwordStrengthMedium,
    PasswordStrength.strong => l10n.passwordStrengthStrong,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeBars = switch (validation.strength) {
      PasswordStrength.weak => 1,
      PasswordStrength.medium => 2,
      PasswordStrength.strong => 3,
    };
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.passwordStrengthLabel,
            style: const TextStyle(
              color: AppColor.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...List.generate(
          3,
          (index) => Container(
            width: 18,
            height: 4,
            margin: const EdgeInsetsDirectional.only(start: 4),
            decoration: BoxDecoration(
              color: index < activeBars
                  ? AppColor.primary
                  : AppColor.indicatorInactive,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          _label(l10n),
          style: const TextStyle(
            color: AppColor.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
