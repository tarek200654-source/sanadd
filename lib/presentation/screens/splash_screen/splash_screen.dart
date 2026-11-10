import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../application/auth/auth_service.dart';
import '../../../application/auth/auth_scope.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/api_error_message.dart';
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
  Object? _restoreError;
  bool _restoring = false;
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _restoreError = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      final user = await _loadCurrentUser();
      SharedPreferences? preferences;
      var onboardingCompleted = false;
      try {
        preferences = await SharedPreferences.getInstance();
        onboardingCompleted =
            preferences.getBool(
              AppConstants.onboardingCompletedPreferenceKey,
            ) ??
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
    } catch (error) {
      if (mounted) setState(() => _restoreError = error);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<AppUser?> _loadCurrentUser() =>
      (widget.authService ?? AuthScope.read(context)).restoreCurrentUser();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              if (_restoreError != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        apiErrorMessage(context.l10n, _restoreError!),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: _restoring ? null : _restoreSession,
                        child: Text(
                          context.l10n.isArabic ? 'إعادة المحاولة' : 'Retry',
                        ),
                      ),
                    ],
                  ),
                ),
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
