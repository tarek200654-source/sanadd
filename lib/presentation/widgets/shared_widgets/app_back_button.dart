import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_color.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.buttonSize = 44,
    this.imageSize = 18,
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor = AppColor.otpText,
  });

  final VoidCallback onPressed;
  final String? tooltip;
  final double buttonSize;
  final double imageSize;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final isRightToLeft = Directionality.of(context) == TextDirection.rtl;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColor.transparent,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(
          width: buttonSize,
          height: buttonSize,
        ),
        icon: Image.asset(
          isRightToLeft ? AppAssets.backToRight : AppAssets.backToLeft,
          width: imageSize,
          height: imageSize,
          color: foregroundColor,
          colorBlendMode: BlendMode.srcIn,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
