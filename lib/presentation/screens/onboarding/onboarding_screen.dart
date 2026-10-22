import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/widgets/onboarding_widgets/onboarding_illustrations.dart';
import '../../../core/assets/app_assets.dart';
import '../../../presentation/widgets/shared_widgets/sanad_button.dart';
import '../../../presentation/widgets/onboarding_widgets/onboarding_page_dots.dart';
import 'onboarding_language_selector.dart';
import 'onboarding_page.dart';
import '../../../utils/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 5;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
  }

  Future<void> _next() async {
    if (_currentPage == _pageCount - 1) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_currentPage + 1);
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _buildPages(l10n);

    return Scaffold(
      backgroundColor: AppColor.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 680;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SizedBox(
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: Image.asset(
                                AppAssets.sanadLogo,
                                key: const ValueKey('onboarding-logo'),
                                width: 100,
                                height: 64,
                                fit: BoxFit.contain,
                                color: AppColor.logoTint,
                                colorBlendMode: BlendMode.srcIn,
                                semanticLabel: 'SANAD logo',
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: const ValueKey('onboarding-skip'),
                                onPressed: _finish,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColor.textSecondary,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                child: Text(l10n.skip),
                              ),
                            ),
                            const Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: OnboardingLanguageSelector(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: pages.length,
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        itemBuilder: (context, index) => AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            final page =
                                _pageController.hasClients &&
                                    _pageController
                                        .position
                                        .hasContentDimensions
                                ? (_pageController.page ??
                                      _currentPage.toDouble())
                                : _currentPage.toDouble();
                            final distance = (page - index).abs().clamp(
                              0.0,
                              1.0,
                            );
                            final reduced = MediaQuery.disableAnimationsOf(
                              context,
                            );
                            return Opacity(
                              opacity: reduced ? 1 : 1 - distance * .55,
                              child: Transform.scale(
                                scale: reduced ? 1 : 1 - distance * .06,
                                child: child,
                              ),
                            );
                          },
                          child: OnboardingPage(
                            key: ValueKey(index),
                            data: pages[index],
                            compact: compact,
                            isActive: index == _currentPage,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        28,
                        12,
                        28,
                        compact ? 20 : 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: l10n.stepLabel(_currentPage + 1),
                            child: OnboardingPageDots(
                              activeIndex: _currentPage,
                              itemCount: pages.length,
                            ),
                          ),
                          SizedBox(height: compact ? 24 : 28),
                          SanadButton(
                            label: _currentPage == _pageCount - 1
                                ? l10n.getStarted
                                : l10n.next,
                            onPressed: _next,
                            icon: null,
                            fontSize: 17,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<OnboardingPageData> _buildPages(AppLocalizations l10n) {
    return [
      OnboardingPageData(
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
        kind: OnboardingIllustrationKind.welcome,
      ),
      OnboardingPageData(
        title: l10n.onboardingMonitoringTitle,
        body: l10n.onboardingMonitoringBody,
        kind: OnboardingIllustrationKind.monitoring,
      ),
      OnboardingPageData(
        title: l10n.onboardingDetectionTitle,
        body: l10n.onboardingDetectionBody,
        kind: OnboardingIllustrationKind.detection,
      ),
      OnboardingPageData(
        title: l10n.onboardingFamilyTitle,
        body: l10n.onboardingFamilyBody,
        kind: OnboardingIllustrationKind.family,
      ),
      OnboardingPageData(
        title: l10n.onboardingIdTitle,
        body: l10n.onboardingIdBody,
        kind: OnboardingIllustrationKind.medicalId,
      ),
    ];
  }
}
