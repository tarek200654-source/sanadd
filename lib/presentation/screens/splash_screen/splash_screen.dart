import 'package:flutter/material.dart';

import '../../../application/auth/auth_service.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
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
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      user == null ? AppRoutes.onboarding : AppRoutes.home,
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
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColor.background,
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  constraints.maxHeight < 600 ? 18 : 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.splashCopyrightEnglish,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColor.mutedText,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.splashCopyrightArabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: AppColor.mutedText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
