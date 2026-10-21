import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import 'sanad_auth_logo.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.header,
    required this.child,
    this.footer,
  });

  final Widget header;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColor.background,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColor.background,
        systemNavigationBarDividerColor: AppColor.background,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColor.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 20, 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 16).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: footer == null
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [header, const SizedBox(height: 12), child],
                      ),
                      if (footer != null) ...[footer!],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.topBarTitle,
    this.trailingIcon,
    this.heroIcon,
    this.heroLabel,
    this.centerTitle = false,
    this.titleFontSize = 24,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final String? topBarTitle;
  final IconData? trailingIcon;
  final IconData? heroIcon;
  final String? heroLabel;
  final bool centerTitle;
  final double titleFontSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBranded = topBarTitle == null || topBarTitle == l10n.appName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: isBranded ? 54 : (compact ? 44 : 48),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (onBack != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    button: true,
                    label: l10n.back,
                    child: IconButton(
                      onPressed: onBack,
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                      ),
                      tooltip: l10n.back,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColor.surfaceMuted,
                        minimumSize: const Size(44, 44),
                        maximumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              if (trailingIcon != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ExcludeSemantics(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColor.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        trailingIcon,
                        size: 20,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ),
                ),
              _topBarContent(l10n),
            ],
          ),
        ),
        if (heroIcon != null) ...[
          const SizedBox(height: 12),
          Center(
            child: Semantics(
              image: true,
              label: heroLabel ?? l10n.verificationIllustrationLabel,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColor.border.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(heroIcon, size: 26, color: AppColor.primary),
              ),
            ),
          ),
        ],
        SizedBox(height: heroIcon == null ? (compact ? 6 : 14) : 12),
        Text(
          title,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: AppColor.textPrimary,
            fontSize: titleFontSize,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: centerTitle ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: AppColor.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _topBarContent(AppLocalizations l10n) {
    final topTitle = topBarTitle;
    if (topTitle == null || topTitle == l10n.appName) {
      return const SanadAuthLogo();
    }
    return Text(
      topTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColor.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
