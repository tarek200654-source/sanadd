import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

class VerificationMethodCard extends StatelessWidget {
  const VerificationMethodCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.available,
    required this.onTap,
    this.valueText,
    this.unavailableLabel,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final bool available;
  final VoidCallback onTap;
  final String? valueText;
  final String? unavailableLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      // The SMS option is unavailable as a delivery method, but the card is
      // still actionable so users can hear why it cannot be selected.
      enabled: true,
      label: [title, ?valueText, if (!available) ?unavailableLabel].join(', '),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: selected ? AppColor.surface : AppColor.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.border,
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColor.surfaceMuted : AppColor.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColor.textPrimary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    if (valueText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        valueText!,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (!available && unavailableLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        unavailableLabel!,
                        style: const TextStyle(
                          color: AppColor.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColor.primary : AppColor.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
