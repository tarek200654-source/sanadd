import 'package:flutter/material.dart';

abstract final class AppColor {
  // SANAD's new visual language is built around a calm, clinical blue-gray
  // canvas, charcoal actions, and a small mint status accent.
  static const Color primary = Color(0xFF212529);
  static const Color primaryDark = Color(0xFF111820);
  static const Color secondary = Color(0xFFE7F0F8);
  static const Color tertiary = Color(0xFF10B981);
  static const Color neutral = Color(0xFFF4F8FC);
  static const Color background = Color(0xFFF4F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFE7F0F8);
  static const Color textPrimary = Color(0xFF111820);
  static const Color textSecondary = Color(0xFF52606D);
  static const Color mutedText = Color(0xFF7B8794);
  static const Color border = Color(0xFFD6E0EA);
  static const Color indicatorActive = Color(0xFF212529);
  static const Color indicatorInactive = Color(0xFFD9E3EC);
  static const Color success = Color(0xFF10B981);
  static const Color alert = Color(0xFFEF4444);
  static const Color borderSubtle = Color(0xCCD6E0EA);
  static const Color authHeaderShadow = Color(0x0A000000);
  static const Color logoTint = Color(0xFF000000);

  // Role selection palette.
  static const Color roleAccent = Color(0xFF40566D);
  static const Color roleSelectedSurface = Color(0xFFF1F4F7);
  static const Color roleSelectedIconSurface = Color(0xFFE5EBF0);
  static const Color roleIconSurface = Color(0xFFF0F3F5);

  // Onboarding palette, including the colors used by its illustrations.
  static const Color onboardingIndicatorInactive = Color(0xFFE5E9ED);
  static const Color onboardingInk = Color(0xFF182C2A);
  static const Color onboardingGreen = Color(0xFF17836C);
  static const Color onboardingMint = Color(0xFFDDF3E9);
  static const Color onboardingLine = Color(0xFFDFE9E4);
  static const Color onboardingLabel = Color(0xFF63756C);
  static const Color onboardingSecondary = Color(0xFF819087);
  static const Color onboardingMutedSurface = Color(0xFFE3EBE6);
  static const Color onboardingCoralDark = Color(0xFFB76B62);
  static const Color onboardingMutedGreen = Color(0xFF71847B);
  static const Color onboardingGray = Color(0xFF89908F);
  static const Color onboardingBlue = Color(0xFF7186A5);
  static const Color onboardingWarmLine = Color(0xFFEAE7E3);
  static const Color onboardingCoral = Color(0xFFD17B72);
  static const Color onboardingGold = Color(0xFFC3964F);
  static const Color onboardingPortraitWarm = Color(0xFFF4E8DC);
  static const Color onboardingPortraitLavender = Color(0xFFE7E7F7);
  static const Color onboardingPortraitBlue = Color(0xFFE2EEF4);
  static const Color onboardingPortraitRose = Color(0xFFF6E9E5);
  static const Color onboardingMutedSlate = Color(0xFF87919A);
  static const Color onboardingPaper = Color(0xFFF3F1EC);
  static const Color onboardingPaperLine = Color(0xFFDCD9D1);
  static const Color onboardingPaperLineAlt = Color(0xFFD9D8D2);
  static const Color onboardingSlate = Color(0xFF596675);
  static const Color onboardingGrayGreen = Color(0xFF7B8585);
  static const Color onboardingSkinLight = Color(0xFFDDAF8C);
  static const Color onboardingSkinPeach = Color(0xFFECC3A4);
  static const Color onboardingSkinMedium = Color(0xFFBC8E71);
  static const Color onboardingSkinWarm = Color(0xFFF1CEAF);
  static const Color onboardingClothingWarm = Color(0xFFA77F6F);
  static const Color onboardingClothingLavender = Color(0xFF787596);
  static const Color onboardingClothingBlue = Color(0xFF658898);
  static const Color onboardingSilhouette = Color(0xFFAAB3AE);
  static const Color onboardingBackdrop = Color(0xFFF6F2EE);
  static const Color onboardingBackdropLine = Color(0xFFE7D8CF);
  static const Color onboardingShield = Color(0xFF344A61);
  static const Color onboardingOrbit = Color(0xFFF5F9F6);
  static const Color onboardingOrbitLine = Color(0xFFD8E1DC);
  static const Color onboardingOrbitAccent = Color(0xFF89938F);
  static const Color onboardingCallout = Color(0xFF8BA99A);
  static const Color onboardingLogoShadow = Color(0xFFD8DAD7);

  // Login screen palette. These values preserve the existing login design.
  static const Color transparent = Color(0x00000000);
  static const Color loginDarkBackground = Color(0xFF0D0D0D);
  static const Color loginLightBackground = Color(0xFFFFFFFF);
  static const Color loginDarkText = Color(0xFFFFFFFF);
  static const Color loginLightText = Color(0xFF000000);
  static const Color loginDarkSecondaryText = Color(0x8AFFFFFF);
  static const Color loginLightSecondaryText = Color(0x8A000000);
  static const Color loginDarkBorder = Color(0x1AFFFFFF);
  static const Color loginLightBorder = Color(0x14000000);
  static const Color loginDarkCard = Color(0xFF1A1A1A);
  static const Color loginLightCard = Color(0xFFF9F9F9);
  static const Color loginDarkPickerBackground = Color(0xD90D0D0D);
  static const Color loginLightPickerBackground = Color(0xD9FFFFFF);
  static const Color loginDarkPickerItemBackground = Color(0x661A1A1A);
  static const Color loginLightPickerItemBackground = Color(0x66F9F9F9);
  static const Color loginDarkInputLabel = Color(0xE6FFFFFF);
  static const Color loginLightInputLabel = Color(0xE6000000);
  static const Color loginActionForegroundDarkTheme = Color(0xFF000000);
  static const Color loginActionForegroundLightTheme = Color(0xFFFFFFFF);
  static const Color loginError = Color(0xFFFF5252);
  static const Color loginAvailable = Color(0xFF4CAF50);
  static const Color loginStatusWarning = Color(0xFFFFAB40);
  static const Color loginStatusSuccess = Color(0xFF69F0AE);
  static const Color loginShadow = Color(0x26000000);
  static const Color loginToastShadow = Color(0x42000000);
  static const Color loginToastSuccessBackground = Color(0xFF0F2A1A);
  static const Color loginToastErrorBackground = Color(0xFF2A0F0F);
  static const Color loginErrorBackground = Color(0x1AFF0000);
  static const Color loginErrorBorder = Color(0x33FF0000);

  // OTP verification palette. These values preserve the existing screen.
  static const Color otpText = Color(0xFF000000);
  static const Color otpSupportingText = Color(0xFF666666);
  static const Color otpStatusText = Color(0xFF777777);
  static const Color otpInputFill = Color(0xFFF9F9F9);
  static const Color otpInputBorder = Color(0xFFE5E5E5);

  static ThemeData theme({required bool isArabic}) {
    final fontFamily = isArabic ? 'Tajawal' : 'Poppins';

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: fontFamily,
      fontFamilyFallback: const ['Arial'],
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontFamily: fontFamily,
          fontSize: 14,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontFamily: fontFamily,
          fontSize: 12,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: surface,
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
