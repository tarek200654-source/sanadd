import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

enum OnboardingIllustrationKind {
  welcome,
  monitoring,
  detection,
  family,
  medicalId,
}

const _ink = Color(0xFF182C2A);
const _green = Color(0xFF17836C);
const _mint = Color(0xFFDDF3E9);
const _line = Color(0xFFDFE9E4);

// A continuous illustrative rhythm, varying smoothly between 70 and 74 BPM.
double _demoRate(double seconds) => 72 + 2 * math.sin(seconds * math.pi / 5);
double _demoCycles(double seconds) =>
    1.2 * seconds + (1 - math.cos(seconds * math.pi / 5)) / (6 * math.pi);
double _ecgSignal(double beat) {
  double peak(double center, double width) =>
      math.exp(-math.pow((beat - center) / width, 2));
  return .10 * peak(.08, .04) -
      .16 * peak(.19, .018) +
      .90 * peak(.25, .022) -
      .38 * peak(.31, .025) +
      .19 * peak(.50, .07);
}

/// Flat vector scenes, with staggered layers driven by the page entrance.
class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({
    super.key,
    required this.kind,
    this.compact = false,
    this.height,
    this.progress = 1,
    this.isActive = true,
  });
  final OnboardingIllustrationKind kind;
  final bool compact;
  final double? height;
  final double progress;
  final bool isActive;

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );
  OnboardingIllustrationKind get kind => widget.kind;
  bool get compact => widget.compact;
  double? get height => widget.height;
  double get progress => widget.progress;

  void _syncMotion() {
    final shouldAnimate =
        widget.isActive &&
        (kind == OnboardingIllustrationKind.welcome ||
            kind == OnboardingIllustrationKind.family) &&
        !MediaQuery.disableAnimationsOf(context);
    if (shouldAnimate && !_motion.isAnimating) {
      _motion.repeat();
    } else if (!shouldAnimate && _motion.isAnimating) {
      _motion.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant OnboardingIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    builder: (context, _) => _buildScene(context),
  );

  Widget _buildScene(BuildContext context) {
    final ar = context.l10n.isArabic;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final phase = reduced ? 0.0 : _motion.value;
    final seconds = phase * 30;
    final bpm = _demoRate(seconds).round();
    final beat = _demoCycles(seconds) % 1;
    final pulse = reduced ? 0.0 : math.exp(-math.pow((beat - .25) / .07, 2));
    String tr(String en, String arabic) => ar ? arabic : en;
    Widget reveal(double start, Widget child, {double x = 0, double y = 22}) {
      final t = Curves.easeOutCubic.transform(
        ((progress - start) / (1 - start)).clamp(0.0, 1.0),
      );
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(x * (1 - t), y * (1 - t)),
          child: Transform.scale(scale: .94 + .06 * t, child: child),
        ),
      );
    }

    return SizedBox(
      height: height ?? (compact ? 240 : 300),
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 340,
          height: kind == OnboardingIllustrationKind.welcome ? 360 : 310,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: kind == OnboardingIllustrationKind.detection
                    ? CustomPaint(
                        painter: _DetectionBackdropPainter(progress: progress),
                      )
                    : Transform.rotate(
                        key: const ValueKey('watch-orbit-rotation'),
                        angle: kind == OnboardingIllustrationKind.welcome
                            ? phase * math.pi * 2
                            : 0,
                        child: CustomPaint(
                          painter: _OrbitPainter(
                            progress: progress,
                            family: kind == OnboardingIllustrationKind.family,
                            phase: phase,
                          ),
                        ),
                      ),
              ),
              ...switch (kind) {
                OnboardingIllustrationKind.welcome => [
                  Positioned(
                    left: -24,
                    top: 0,
                    child: reveal(
                      0,
                      SizedBox(
                        width: 300,
                        height: 335,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/whoop_band_realistic.png',
                                key: const ValueKey('realistic-whoop-band'),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            Positioned(
                              left: 160,
                              top: 89,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(0, 0, .40)
                                  ..setEntry(1, 0, .82)
                                  ..setEntry(0, 1, -.90)
                                  ..setEntry(1, 1, .09),
                                child: const _OriginalBandLogo(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const ValueKey('band-sensor-callout'),
                        painter: _SensorCalloutPainter(progress: progress),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: reveal(
                      .20,
                      SizedBox(
                        key: const ValueKey('band-readout'),
                        width: 80,
                        height: 112,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tr('HEART RATE', 'نبض القلب'),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Color(0xFF63756C),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .35,
                                    ),
                                  ),
                                ),
                                Transform.scale(
                                  key: const ValueKey('watch-heartbeat'),
                                  scale: 1 + .14 * pulse,
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: _green,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              textDirection: TextDirection.ltr,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedSwitcher(
                                  key: const ValueKey('watch-bpm'),
                                  duration: reduced
                                      ? Duration.zero
                                      : const Duration(milliseconds: 180),
                                  child: Text(
                                    '$bpm',
                                    key: ValueKey(bpm),
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                      letterSpacing: -1.2,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'BPM',
                                    style: TextStyle(
                                      color: Color(0xFF819087),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Container(
                              height: 1,
                              width: double.infinity,
                              color: const Color(0xFFE3EBE6),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 30,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _LiveWavePainter(
                                  seconds: seconds,
                                  progress: progress,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                OnboardingIllustrationKind.monitoring => [
                  Positioned(
                    left: 20,
                    right: 20,
                    top: 34,
                    child: reveal(
                      0,
                      SizedBox(
                        height: 226,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite_rounded,
                                  color: Color(0xFFB76B62),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tr('Heart rate', 'نبض القلب'),
                                  style: _label,
                                ),
                                const Spacer(),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: _green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  tr('LIVE', 'مباشر'),
                                  style: const TextStyle(
                                    color: Color(0xFF71847B),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: .5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '72',
                                  style: TextStyle(
                                    fontSize: 54,
                                    height: .95,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -2,
                                    color: _ink,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 7, bottom: 6),
                                  child: Text(
                                    'BPM',
                                    style: TextStyle(
                                      color: Color(0xFF71847B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: .4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _WavePainter(progress: progress),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: _MonitoringMetric(
                                    icon: Icons.water_drop_outlined,
                                    value: '98%',
                                    label: tr('Oxygen', 'الأكسجين'),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _MonitoringMetric(
                                    icon: Icons.directions_walk_rounded,
                                    value: '8,420',
                                    label: tr('Daily steps', 'خطوات اليوم'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                OnboardingIllustrationKind.detection => [
                  Positioned(
                    left: 117,
                    top: 12,
                    child: reveal(
                      0,
                      SizedBox(
                        width: 106,
                        height: 124,
                        child: CustomPaint(
                          painter: _ShieldPainter(progress: progress),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 34,
                    right: 28,
                    top: 143,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        reveal(
                          .22,
                          Text(
                            tr('SIGNALS WE READ', 'إشارات بنفهمها'),
                            style: const TextStyle(
                              color: Color(0xFF89908F),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .9,
                            ),
                          ),
                          y: 8,
                        ),
                        const SizedBox(height: 7),
                        reveal(
                          .31,
                          _DetectionFeature(
                            color: const Color(0xFF7186A5),
                            title: tr('Movement', 'الحركة'),
                            detail: tr(
                              'Patterns in motion',
                              'قراءة أنماط الحركة',
                            ),
                          ),
                          x: 12,
                        ),
                        const SizedBox(height: 2),
                        Container(height: 1, color: const Color(0xFFEAE7E3)),
                        reveal(
                          .42,
                          _DetectionFeature(
                            color: const Color(0xFFD17B72),
                            title: tr('Health signals', 'المؤشرات الصحية'),
                            detail: tr(
                              'Heart rate and oxygen',
                              'نبض القلب والأكسجين',
                            ),
                          ),
                          x: 12,
                        ),
                        const SizedBox(height: 2),
                        Container(height: 1, color: const Color(0xFFEAE7E3)),
                        reveal(
                          .53,
                          _DetectionFeature(
                            color: const Color(0xFFC3964F),
                            title: tr('Timely alerts', 'التنبيه المناسب'),
                            detail: tr(
                              'Support when it matters',
                              'دعم وقت الحاجة',
                            ),
                          ),
                          x: 12,
                        ),
                      ],
                    ),
                  ),
                ],
                OnboardingIllustrationKind.family => [
                  Positioned(
                    left: 122,
                    top: 80,
                    child: reveal(
                      0,
                      const _Portrait(size: 94, variant: 0, color: _mint),
                    ),
                  ),
                  Positioned(
                    left: 36,
                    top: 36,
                    child: reveal(
                      .20,
                      const _Portrait(
                        size: 66,
                        variant: 1,
                        color: Color(0xFFF4E8DC),
                      ),
                      x: -22,
                    ),
                  ),
                  Positioned(
                    right: 36,
                    top: 46,
                    child: reveal(
                      .32,
                      const _Portrait(
                        size: 70,
                        variant: 2,
                        color: Color(0xFFE7E7F7),
                      ),
                      x: 22,
                    ),
                  ),
                  Positioned(
                    left: 31,
                    top: 167,
                    child: reveal(
                      .42,
                      const _Portrait(
                        size: 62,
                        variant: 3,
                        color: Color(0xFFE2EEF4),
                      ),
                      x: -22,
                    ),
                  ),
                  Positioned(
                    right: 30,
                    top: 164,
                    child: reveal(
                      .48,
                      const _Portrait(
                        size: 64,
                        variant: 1,
                        color: Color(0xFFF4E8DC),
                      ),
                      x: 22,
                    ),
                  ),
                ],
                OnboardingIllustrationKind.medicalId => [
                  Positioned(
                    left: 30,
                    right: 30,
                    top: 28,
                    child: reveal(
                      0,
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF6E9E5),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Color(0xFFD17B72),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('Medical ID', 'الهوية الطبية'),
                                style: _label.copyWith(
                                  color: _ink,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('Emergency profile', 'ملف الطوارئ'),
                            style: const TextStyle(
                              color: Color(0xFF87919A),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 118,
                                height: 118,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF3F1EC),
                                ),
                              ),
                              Container(
                                width: 94,
                                height: 94,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFDCD9D1),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(child: _QrMark()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _medicalValue(
                                tr('BLOOD TYPE', 'فصيلة الدم'),
                                'O+',
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                ),
                                width: 1,
                                height: 32,
                                color: const Color(0xFFD9D8D2),
                              ),
                              _medicalValue(tr('EMERGENCY', 'الطوارئ'), 'ICE'),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.contactless_rounded,
                                color: Color(0xFFD17B72),
                                size: 17,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tr(
                                  'Tap or scan to open',
                                  'قرّب الجهاز أو امسح الرمز',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF596675),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}

const _label = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: _ink,
);

Widget _medicalValue(String label, String value) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      label,
      style: const TextStyle(
        color: Color(0xFF87919A),
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: .45,
      ),
    ),
    const SizedBox(height: 2),
    Text(
      value,
      style: const TextStyle(
        color: _ink,
        fontSize: 21,
        height: 1,
        fontWeight: FontWeight.w700,
      ),
    ),
  ],
);

class _QrMark extends StatelessWidget {
  const _QrMark();

  @override
  Widget build(BuildContext context) => const CustomPaint(
    size: Size(68, 68),
    painter: _QrMarkPainter(),
  );
}

class _QrMarkPainter extends CustomPainter {
  const _QrMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const count = 21;
    final cell = size.width / count;
    final module = Paint()..color = _ink;

    bool inFinder(int x, int y, int left, int top) =>
        x >= left && x < left + 7 && y >= top && y < top + 7;

    for (var y = 0; y < count; y++) {
      for (var x = 0; x < count; x++) {
        var filled = false;
        var isFinder = false;
        for (final origin in const [(0, 0), (14, 0), (0, 14)]) {
          if (inFinder(x, y, origin.$1, origin.$2)) {
            isFinder = true;
            final dx = x - origin.$1;
            final dy = y - origin.$2;
            filled =
                dx == 0 || dx == 6 || dy == 0 || dy == 6 ||
                (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4);
            break;
          }
        }
        if (!isFinder) {
          // A stable, balanced module pattern that reads as a QR at this size.
          filled = ((x * 7 + y * 11 + x * y * 3) % 9) < 4;
          if (x == 6 || y == 6) filled = (x + y).isEven;
        }
        if (filled) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell * .82, cell * .82),
            module,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMarkPainter oldDelegate) => false;
}

class _DetectionFeature extends StatelessWidget {
  const _DetectionFeature({
    required this.color,
    required this.title,
    required this.detail,
  });
  final String title, detail;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF7B8585),
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MonitoringMetric extends StatelessWidget {
  const _MonitoringMetric({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 15, color: _green),
          const SizedBox(width: 6),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF71847B),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.size,
    required this.variant,
    required this.color,
  });
  final double size;
  final int variant;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: CustomPaint(
            painter: _PortraitPainter(variant: variant, background: color),
          ),
        ),
      ),
    ),
  );
}

class _PortraitPainter extends CustomPainter {
  const _PortraitPainter({required this.variant, required this.background});
  final int variant;
  final Color background;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final skin = [
      const Color(0xFFDDAF8C),
      const Color(0xFFECC3A4),
      const Color(0xFFBC8E71),
      const Color(0xFFF1CEAF),
    ][variant];
    final clothes = [
      _green,
      const Color(0xFFA77F6F),
      const Color(0xFF787596),
      const Color(0xFF658898),
    ][variant];
    final paint = Paint()..color = clothes;
    canvas.drawOval(const Rect.fromLTWH(12, 72, 76, 65), paint);
    paint.color = skin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 60, 14, 21),
        const Radius.circular(5),
      ),
      paint,
    );
    // Hair behind the face gives each caregiver a distinct silhouette.
    paint.color = variant == 0 ? const Color(0xFFAAB3AE) : _ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          variant == 1 ? 26 : 29,
          20,
          variant == 1 ? 48 : 42,
          variant == 1 ? 59 : 45,
        ),
        const Radius.circular(22),
      ),
      paint,
    );
    paint.color = skin;
    canvas.drawOval(const Rect.fromLTWH(33, 30, 34, 40), paint);
    paint.color = variant == 0 ? const Color(0xFFAAB3AE) : _ink;
    final hair = Path()
      ..moveTo(31, 42)
      ..quadraticBezierTo(27, 17, 52, 20)
      ..quadraticBezierTo(76, 23, 68, 42)
      ..quadraticBezierTo(57, 38, 53, 29)
      ..quadraticBezierTo(46, 40, 31, 42);
    canvas.drawPath(hair, paint);
    paint
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(41, 47), const Offset(42, 47), paint);
    canvas.drawLine(const Offset(58, 47), const Offset(59, 47), paint);
    canvas.drawArc(const Rect.fromLTWH(44, 52, 12, 9), .3, 2.5, false, paint);
    if (variant == 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(36, 42, 12, 10),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(52, 42, 12, 10),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawLine(const Offset(48, 46), const Offset(52, 46), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.background != background;
}

class _DetectionBackdropPainter extends CustomPainter {
  const _DetectionBackdropPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 78);
    canvas.drawCircle(
      center,
      72,
      Paint()..color = const Color(0xFFF6F2EE).withValues(alpha: progress),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 91),
      -math.pi * .82,
      math.pi * 1.34 * progress,
      false,
      Paint()
        ..color = const Color(0xFFE7D8CF).withValues(alpha: progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      center + const Offset(66, -37),
      4,
      Paint()..color = const Color(0xFFD17B72).withValues(alpha: progress),
    );
    canvas.drawCircle(
      center + const Offset(-68, 32),
      3,
      Paint()..color = const Color(0xFF7186A5).withValues(alpha: progress),
    );
    canvas.drawCircle(
      center + const Offset(62, 36),
      3.5,
      Paint()..color = const Color(0xFFC3964F).withValues(alpha: progress),
    );
  }

  @override
  bool shouldRepaint(_DetectionBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ShieldPainter extends CustomPainter {
  const _ShieldPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 150, size.height / 174);
    final path = Path()
      ..moveTo(75, 8)
      ..cubicTo(94, 22, 115, 26, 135, 29)
      ..lineTo(132, 91)
      ..cubicTo(129, 127, 105, 151, 75, 167)
      ..cubicTo(45, 151, 21, 127, 18, 91)
      ..lineTo(15, 29)
      ..cubicTo(35, 26, 56, 22, 75, 8)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF344A61));
    final check = Path()
      ..moveTo(59, 79)
      ..lineTo(70, 90)
      ..lineTo(92, 67);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(
        0,
        metric.length * ((progress - .15) / .7).clamp(0.0, 1.0),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.progress});
  final double progress;
  final Color color = _green;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const points = [
      Offset(0, .55),
      Offset(.17, .55),
      Offset(.22, .42),
      Offset(.28, .65),
      Offset(.36, .12),
      Offset(.43, .92),
      Offset(.5, .45),
      Offset(.57, .55),
      Offset(.7, .55),
      Offset(.76, .35),
      Offset(.82, .55),
      Offset(1, .55),
    ];
    for (var i = 0; i < points.length; i++) {
      final p = Offset(points[i].dx * size.width, points[i].dy * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    for (final fraction in [.18, .55, .9]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        Paint()
          ..color = color.withValues(alpha: .08)
          ..strokeWidth = .8,
      );
    }
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.clamp(0, 1)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final end = metric
        .getTangentForOffset(metric.length * progress.clamp(0.0, 1.0))
        ?.position;
    if (end != null && progress > .15) {
      canvas.drawCircle(end, 5, Paint()..color = color.withValues(alpha: .12));
      canvas.drawCircle(end, 2.3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.progress,
    required this.family,
    required this.phase,
  });
  final double progress;
  final bool family;
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 120, Paint()..color = const Color(0xFFF5F9F6));
    final stroke = Paint()
      ..color = _line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 140),
      -.8,
      math.pi * 1.4 * progress,
      false,
      stroke,
    );
    if (family) {
      const origin = Offset(169, 127);
      const ends = [
        Offset(69, 69),
        Offset(269, 81),
        Offset(62, 198),
        Offset(278, 196),
      ];
      for (var i = 0; i < ends.length; i++) {
        final end = Offset.lerp(origin, ends[i], progress)!;
        final path = Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(end.dx, end.dy);
        final pathMetric = path.computeMetrics().first;
        canvas.drawPath(
          path,
          stroke
            ..color = const Color(0xFFD8E1DC)
            ..strokeWidth = 1.4,
        );
        if (progress > .95 && phase > 0) {
          final fill = (phase * 30 + i * .25) % 1;
          canvas.drawPath(
            pathMetric.extractPath(0, pathMetric.length * fill),
            Paint()
              ..color = const Color(0xFF89938F)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
    for (final p in [
      const Offset(26, 140),
      const Offset(286, 254),
      const Offset(256, 24),
    ]) {
      canvas.drawCircle(
        p,
        3 * progress,
        Paint()..color = _green.withValues(alpha: .35),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.family != family ||
      (family && oldDelegate.phase != phase);
}

/// Monitor sweep: a moving pen leaves a stationary up/down ECG trace.
class _LiveWavePainter extends CustomPainter {
  const _LiveWavePainter({required this.seconds, required this.progress});
  final double seconds, progress;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    const color = _green;
    const sweepSeconds = 2.5;
    final head = (seconds / sweepSeconds) % 1;
    double y(double time) =>
        size.height * (.59 - .56 * _ecgSignal(_demoCycles(time) % 1));
    final grid = Paint()
      ..color = color.withValues(alpha: .08)
      ..strokeWidth = .6;
    for (final fraction in [.2, .6, .9]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        grid,
      );
    }
    // Each position keeps its last trace until the pen reaches it again.
    for (var i = 1; i <= 240; i++) {
      final x = i / 240;
      final previousX = (i - 1) / 240;
      final age = (head - x + 1) % 1;
      if (age > .96 || x > progress) continue;
      final time = seconds - age * sweepSeconds;
      final previousAge = (head - previousX + 1) % 1;
      if ((previousAge - age).abs() > .5) continue;
      canvas.drawLine(
        Offset(previousX * size.width, y(seconds - previousAge * sweepSeconds)),
        Offset(x * size.width, y(time)),
        Paint()
          ..color = color.withValues(alpha: .25 + .75 * (1 - age))
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round,
      );
    }
    if (progress > .95) {
      final tip = Offset(head * size.width, y(seconds));
      canvas.drawCircle(
        tip,
        3.4,
        Paint()..color = color.withValues(alpha: .16),
      );
      canvas.drawCircle(tip, 1.7, Paint()..color = color);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiveWavePainter oldDelegate) =>
      oldDelegate.seconds != seconds || oldDelegate.progress != progress;
}

/// Thin editorial leader from the band's housing to its separate readout.
class _SensorCalloutPainter extends CustomPainter {
  const _SensorCalloutPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(
      ((progress - .18) / .65).clamp(0.0, 1.0),
    );
    // The sensor sits beneath the housing; keep the anchor on that lower edge,
    // centered under the hardware instead of out on the fabric strap.
    const source = Offset(155, 204);
    final path = Path()
      ..moveTo(source.dx, source.dy)
      ..lineTo(169, 204)
      ..quadraticBezierTo(182, 204, 187, 217)
      ..lineTo(253, 244);
    final metric = path.computeMetrics().first;
    final stroke = Paint()
      ..color = const Color(0xFF8BA99A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(metric.extractPath(0, metric.length * t), stroke);
    canvas.drawCircle(
      source,
      4,
      Paint()..color = Colors.white.withValues(alpha: t),
    );
    canvas.drawCircle(
      source,
      2.3,
      Paint()..color = _green.withValues(alpha: t),
    );
    if (t > .98) {
      canvas.drawPath(
        Path()
          ..moveTo(248, 241)
          ..lineTo(254, 247)
          ..lineTo(258, 240),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SensorCalloutPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Crop transparent padding only; the original logo pixels remain unchanged.
class _OriginalBandLogo extends StatelessWidget {
  const _OriginalBandLogo();
  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('original-band-logo'),
    width: 86,
    height: 38,
    child: ClipRect(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -22.2,
            top: -51.0,
            width: 130.5,
            height: 130.5,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFFD8DAD7),
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/images/sanad_logo.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
