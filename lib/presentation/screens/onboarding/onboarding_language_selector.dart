import 'package:flutter/material.dart';

import '../../../core/localization/locale_scope.dart';
import '../../../core/theme/app_color.dart';

class OnboardingLanguageSelector extends StatelessWidget {
  const OnboardingLanguageSelector();

  @override
  Widget build(BuildContext context) {
    final controller = context.localeController;
    final isArabic = controller.locale.languageCode == 'ar';
    final target = isArabic ? 'en' : 'ar';
    return TextButton(
      key: ValueKey('language-option-$target'),
      onPressed: () => controller.setLocale(Locale(target)),
      style: TextButton.styleFrom(
        foregroundColor: AppColor.textPrimary,
        minimumSize: const Size(88, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Text(
            isArabic ? 'English' : 'عربي',
            style: TextStyle(
              fontFamily: isArabic ? 'Poppins' : 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          ExcludeSemantics(
            child: Text(
              isArabic ? '🇬🇧' : '🇸🇦',
              style: const TextStyle(fontSize: 19),
            ),
          ),
        ],
      ),
    );
  }
}
