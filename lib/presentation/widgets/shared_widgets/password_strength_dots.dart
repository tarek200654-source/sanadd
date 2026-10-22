import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';
import 'auth_screen_styles.dart';

class PasswordStrengthDots extends StatelessWidget {
  final List<bool> status;
  const PasswordStrengthDots({required this.status});
  @override
  Widget build(BuildContext context) {
    int metCount = status.where((e) => e).length;
    Color color = metCount == 0
        ? context.sanadBorder
        : metCount < 3
        ? AppColor.loginStatusWarning
        : AppColor.loginStatusSuccess;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        status.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: status[i] ? 14 : 8,
          height: 4,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: status[i] ? color : context.sanadBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
