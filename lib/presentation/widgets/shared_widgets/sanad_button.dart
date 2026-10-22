import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

class SanadButton extends StatelessWidget {
  const SanadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.fontSize = 14,
    this.height = 60,
    this.cornerRadius,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double fontSize;
  final double height;
  final double? cornerRadius;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final resolvedIcon = icon != null && textDirection == TextDirection.rtl
        ? Icons.arrow_back_rounded
        : icon;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: cornerRadius == null
              ? const StadiumBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cornerRadius!),
                ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: textDirection,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (resolvedIcon != null) ...[
              const SizedBox(width: 8),
              Icon(resolvedIcon, size: 19),
            ],
          ],
        ),
      ),
    );
  }
}
