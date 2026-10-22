import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

extension AuthScreenBuildContextX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get sanadBg =>
      isDark ? AppColor.loginDarkBackground : AppColor.loginLightBackground;
  Color get sanadText =>
      isDark ? AppColor.loginDarkText : AppColor.loginLightText;
  Color get sanadDim => isDark
      ? AppColor.loginDarkSecondaryText
      : AppColor.loginLightSecondaryText;
  Color get sanadBorder =>
      isDark ? AppColor.loginDarkBorder : AppColor.loginLightBorder;
  Color get sanadCardInner =>
      isDark ? AppColor.loginDarkCard : AppColor.loginLightCard;
  Color get sanadPickerBackground => isDark
      ? AppColor.loginDarkPickerBackground
      : AppColor.loginLightPickerBackground;
  Color get sanadPickerItemBackground => isDark
      ? AppColor.loginDarkPickerItemBackground
      : AppColor.loginLightPickerItemBackground;
  Color get sanadInputLabel =>
      isDark ? AppColor.loginDarkInputLabel : AppColor.loginLightInputLabel;
}
