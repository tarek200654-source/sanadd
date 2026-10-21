import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/localization/locale_scope.dart';
import '../../../presentation/widgets/onboarding_illustrations.dart';
import '../../../core/assets/app_assets.dart';
import '../../../presentation/widgets/sanad_button.dart';
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
      backgroundColor: Colors.white,
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
                                width: 88,
                                height: 56,
                                fit: BoxFit.contain,
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
                              child: _LanguageSelector(),
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
                          child: _OnboardingPage(
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
                            child: _PageDots(activeIndex: _currentPage),
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

  List<_OnboardingData> _buildPages(AppLocalizations l10n) {
    return [
      _OnboardingData(
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
        kind: OnboardingIllustrationKind.welcome,
      ),
      _OnboardingData(
        title: l10n.onboardingMonitoringTitle,
        body: l10n.onboardingMonitoringBody,
        kind: OnboardingIllustrationKind.monitoring,
      ),
      _OnboardingData(
        title: l10n.onboardingDetectionTitle,
        body: l10n.onboardingDetectionBody,
        kind: OnboardingIllustrationKind.detection,
      ),
      _OnboardingData(
        title: l10n.onboardingFamilyTitle,
        body: l10n.onboardingFamilyBody,
        kind: OnboardingIllustrationKind.family,
      ),
      _OnboardingData(
        title: l10n.onboardingIdTitle,
        body: l10n.onboardingIdBody,
        kind: OnboardingIllustrationKind.medicalId,
      ),
    ];
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.body,
    required this.kind,
  });

  final String title;
  final String body;
  final OnboardingIllustrationKind kind;
}

class _OnboardingPage extends StatefulWidget {
  const _OnboardingPage({
    super.key,
    required this.data,
    required this.compact,
    required this.isActive,
  });
  final _OnboardingData data;
  final bool compact, isActive;

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _entrance.forward();
  }

  @override
  void didUpdateWidget(covariant _OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _entrance.forward(from: 0);
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Widget _reveal(double progress, double start, Widget child, {Key? key}) {
    final t = Curves.easeOutCubic.transform(
      ((progress - start) / (1 - start)).clamp(0.0, 1.0),
    );
    return Opacity(
      key: key,
      opacity: t,
      child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        final t = reduced ? 1.0 : _entrance.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = widget.compact;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 32).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _reveal(
                      t,
                      0,
                      ExcludeSemantics(
                        child: OnboardingIllustration(
                          kind: widget.data.kind,
                          compact: compact,
                          height: compact ? 235 : 300,
                          progress: t,
                          isActive: widget.isActive,
                        ),
                      ),
                      key: ValueKey(
                        'onboarding-feature-${widget.data.kind.name}',
                      ),
                    ),
                    SizedBox(height: compact ? 24 : 34),
                    _reveal(
                      t,
                      .18,
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: Text(
                          widget.data.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: compact ? 26 : 29,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _reveal(
                      t,
                      .30,
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          widget.data.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: 15,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

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

class _PageDots extends StatelessWidget {
  const _PageDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == activeIndex ? 28 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? AppColor.indicatorActive
                : const Color(0xFFE5E9ED),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }
}
