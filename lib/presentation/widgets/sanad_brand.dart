import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';

class SanadLogoMark extends StatelessWidget {
  const SanadLogoMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(size * .25),
      ),
      child: CustomPaint(
        painter: _SanadMarkPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class SanadBrand extends StatelessWidget {
  const SanadBrand({super.key, this.markSize = 40, this.compact = false});

  final double markSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          SanadLogoMark(size: markSize),
          const SizedBox(width: 7),
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SANAD',
                style: TextStyle(
                  color: AppColor.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: .2,
                ),
              ),
              Text(
                'سند',
                style: TextStyle(
                  color: AppColor.mutedText,
                  fontSize: 8,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SanadLogoMark(size: markSize),
        const SizedBox(height: 14),
        const Text(
          'SANAD',
          style: TextStyle(
            color: AppColor.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: .2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'سند',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: AppColor.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SanadTopBar extends StatelessWidget {
  const SanadTopBar({
    super.key,
    this.stepLabel,
    this.onBack,
    this.onSkip,
    this.skipLabel,
  });

  final String? stepLabel;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String? skipLabel;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final backIcon = textDirection == TextDirection.rtl
        ? Icons.arrow_forward_rounded
        : Icons.arrow_back_rounded;
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                onPressed: onBack,
                icon: Icon(backIcon),
                color: AppColor.textPrimary,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: AppColor.surfaceMuted,
                  minimumSize: const Size(36, 36),
                  maximumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          Center(
            child: stepLabel == null
                ? const SanadBrand(markSize: 24, compact: true)
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      stepLabel!,
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          if (onSkip != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                width: 52,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.textPrimary,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    skipLabel ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SanadMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .055
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = Colors.white;
    final radius = size.width * .25;

    canvas.drawCircle(center, radius, stroke);
    canvas.drawLine(
      Offset(center.dx - radius * .58, center.dy),
      Offset(center.dx + radius * .58, center.dy),
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * .58),
      Offset(center.dx, center.dy + radius * .58),
      stroke,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * .98, center.dy - radius * .98),
      size.width * .045,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
