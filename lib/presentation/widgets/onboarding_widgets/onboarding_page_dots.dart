import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

class OnboardingPageDots extends StatelessWidget {
  const OnboardingPageDots({
    super.key,
    required this.activeIndex,
    required this.itemCount,
  });

  final int activeIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == activeIndex ? 28 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? AppColor.indicatorActive
                : AppColor.onboardingIndicatorInactive,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }
}
