import 'package:flutter/material.dart';

import '../onboarding/onboarding_screen.dart';

// Keep existing /language links compatible with the unified onboarding flow.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const routeName = '/language';

  @override
  Widget build(BuildContext context) => const OnboardingScreen();
}
