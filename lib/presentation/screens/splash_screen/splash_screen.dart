import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../application/auth/auth_service.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/app_user.dart';
import '../../../utils/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.authService});

  static const String routeName = AppConstants.splashRoute;
  final AuthService? authService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final user = await _loadCurrentUser();
    SharedPreferences? preferences;
    var onboardingCompleted = false;
    try {
      preferences = await SharedPreferences.getInstance();
      onboardingCompleted =
          preferences.getBool(AppConstants.onboardingCompletedPreferenceKey) ??
          false;
    } catch (_) {
      // Missing local preferences should only affect first-run onboarding.
    }
    if (!mounted) return;
    if (user != null && !onboardingCompleted) {
      try {
        await preferences?.setBool(
          AppConstants.onboardingCompletedPreferenceKey,
          true,
        );
      } catch (_) {
        // Preserve navigation even when local storage is unavailable.
      }
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      user != null
          ? AppRoutes.home
          : onboardingCompleted
          ? AppRoutes.login
          : AppRoutes.onboarding,
    );
  }

  Future<AppUser?> _loadCurrentUser() async {
    try {
      return await (widget.authService ?? AuthService.firebase())
          .restoreCurrentUser();
    } catch (_) {
      // Keep the existing first-run route available when Firebase is not ready.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              const Spacer(),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (constraints.maxWidth * .58).clamp(190.0, 280.0),
                  ),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      AppAssets.sanadLogo,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'SANAD logo',
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
