import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';
import '../../../presentation/widgets/onboarding_widgets/onboarding_illustrations.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.kind,
  });

  final String title;
  final String body;
  final OnboardingIllustrationKind kind;
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.data,
    required this.compact,
    required this.isActive,
  });
  final OnboardingPageData data;
  final bool compact, isActive;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
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
  void didUpdateWidget(covariant OnboardingPage oldWidget) {
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
