import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import 'reference_ui.dart';

String _t(BuildContext context, String en, String ar) =>
    context.l10n.isArabic ? ar : en;

const _showReferencePreviewData = kDebugMode;

class HealthDashboard extends StatelessWidget {
  const HealthDashboard({
    super.key,
    required this.tab,
    required this.onOpenTab,
    this.userName,
    this.onOpenProfile,
  });

  final int tab;
  final ValueChanged<int> onOpenTab;
  final String? userName;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) => switch (tab) {
    1 => const ActivityContent(),
    2 => HealthContent(onOpenTrends: () => onOpenTab(3)),
    3 => const TrendsContent(),
    _ => _TodayContent(userName: userName, onOpenProfile: onOpenProfile),
  };
}

// Today follows the Fitbit reference: compact profile header, one large
// activity ring beside three metric tiles, then the sleep summary.
class _TodayContent extends StatelessWidget {
  const _TodayContent({this.userName, this.onOpenProfile});
  final String? userName;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final name = userName?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: _t(context, 'Account', 'الحساب'),
                child: InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            context,
                            'Hi, ${name?.isNotEmpty == true ? name : 'there'} 👋',
                            'أهلاً، ${name?.isNotEmpty == true ? name : 'بك'} 👋',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ReferenceUi.ink,
                          ),
                        ),
                        Text(
                          _t(
                            context,
                            'Your health, at a glance',
                            'صحتك في لمحة',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ReferenceUi.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _BandStatus(),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 11,
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _ActivityRingPainter(
                    isArabic: context.l10n.isArabic,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 112,
                        height: 126,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_showReferencePreviewData) ...[
                                  const Text.rich(
                                    TextSpan(
                                      text: '56',
                                      children: [
                                        TextSpan(
                                          text: '%',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    style: TextStyle(
                                      fontSize: 34,
                                      height: 1,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -1.5,
                                      color: ReferenceUi.ink,
                                    ),
                                  ),
                                ] else ...[
                                  ReferenceIcon(
                                    ReferenceSymbol.today,
                                    size: 17,
                                    color: ReferenceUi.secondary,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _t(context, 'Activity', 'النشاط'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: ReferenceUi.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('—', style: ReferenceUi.number),
                                  Text(
                                    _t(
                                      context,
                                      'No data yet',
                                      'لا توجد بيانات بعد',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: ReferenceUi.secondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 10,
              child: Column(
                children: [
                  _MetricTile(
                    icon: ReferenceSymbol.steps,
                    label: _t(context, 'Steps', 'الخطوات'),
                    value: _showReferencePreviewData ? '3,625' : '—',
                    color: const Color(0xFFE79A36),
                    tint: const Color(0xFFFFF3E0),
                  ),
                  const SizedBox(height: 9),
                  _MetricTile(
                    icon: ReferenceSymbol.run,
                    label: _t(context, 'Readiness', 'الجاهزية'),
                    value: _showReferencePreviewData ? '85' : '— bpm',
                    color: const Color(0xFF2C9D72),
                    tint: const Color(0xFFE8F5EE),
                  ),
                  const SizedBox(height: 9),
                  _MetricTile(
                    icon: ReferenceSymbol.moon,
                    label: _t(context, 'Sleep', 'النوم'),
                    value: _showReferencePreviewData ? '7h 14m' : '—',
                    subtitle: _showReferencePreviewData ? '72 • Fair' : null,
                    color: const Color(0xFF8D63C7),
                    tint: const Color(0xFFF1EAF9),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Surface(
          padding: const EdgeInsets.all(18),
          showBorder: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _Tag(
                    icon: ReferenceSymbol.moon,
                    text: _t(context, 'Sleep', 'النوم'),
                    color: const Color(0xFF7653B4),
                    background: const Color(0xFFF1EAF9),
                  ),
                  const Spacer(),
                  const ReferenceIcon(
                    ReferenceSymbol.menu,
                    size: 17,
                    color: ReferenceUi.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _showReferencePreviewData
                    ? _t(
                        context,
                        'Restless night, but good deep sleep',
                        'ليلة مضطربة، لكن نومك العميق جيد',
                      )
                    : _t(context, 'Your sleep summary', 'ملخص نومك'),
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: ReferenceUi.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _t(
                  context,
                  _showReferencePreviewData
                      ? 'You had a restless night, but still got restorative deep sleep. This preview shows how your recovery summary will look.'
                      : 'Sleep insights will appear here after your band is connected.',
                  _showReferencePreviewData
                      ? 'كانت ليلتك مضطربة، لكنك حصلت على نوم عميق مريح. هذه معاينة لشكل ملخص التعافي.'
                      : 'ستظهر مؤشرات النوم هنا بعد توصيل السوار.',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: ReferenceUi.secondary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: ReferenceUi.panel,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _t(context, 'Sleep duration', 'مدة النوم'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ReferenceUi.secondary,
                            ),
                          ),
                        ),
                        Text(
                          _showReferencePreviewData
                              ? '72 • Fair'
                              : _t(context, 'No readings', 'لا توجد قراءات'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ReferenceUi.secondary,
                          ),
                        ),
                      ],
                    ),
                    if (_showReferencePreviewData) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '7h 14m',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: ReferenceUi.ink,
                        ),
                      ),
                      Text(
                        _t(
                          context,
                          'Awake 1h 32m  •  REM 1h 01m  •  Deep 2h 45m',
                          'مستيقظ 1س 32د  •  حركة العين 1س 01د  •  عميق 2س 45د',
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          color: ReferenceUi.secondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const SizedBox(
                      height: 58,
                      child: CustomPaint(painter: _SleepStagesPainter()),
                    ),
                    const SizedBox(height: 8),
                    if (!_showReferencePreviewData)
                      Text(
                        _t(
                          context,
                          'Wear your band while sleeping to see your sleep stages.',
                          'ارتدِ السوار أثناء النوم لمشاهدة مراحل نومك.',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: ReferenceUi.secondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!_showReferencePreviewData) ...[
          const SizedBox(height: 18),
          _NoDataNote(
            icon: ReferenceSymbol.watch,
            title: _t(context, 'Connect your SANAD band', 'وصّل سوار سند'),
            subtitle: _t(
              context,
              'Your steps, heart rate and sleep data will show here when available.',
              'ستظهر بيانات خطواتك ونبضك ونومك هنا عند توفرها.',
            ),
          ),
        ],
      ],
    );
  }
}

class _BandStatus extends StatefulWidget {
  @override
  State<_BandStatus> createState() => _BandStatusState();
}

class _BandStatusState extends State<_BandStatus> with WidgetsBindingObserver {
  static const _channel = MethodChannel('sanad/device');
  int? _batteryLevel;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readBatteryLevel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _readBatteryLevel(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _readBatteryLevel();
  }

  Future<void> _readBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      if (mounted) setState(() => _batteryLevel = level);
    } on PlatformException {
      if (mounted) setState(() => _batteryLevel = null);
    } on MissingPluginException {
      if (mounted) setState(() => _batteryLevel = null);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F3F5),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BatteryGlyph(level: _batteryLevel ?? 96),
        const SizedBox(width: 6),
        Text(
          '${_batteryLevel ?? 96}%',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ReferenceUi.secondary,
          ),
        ),
      ],
    ),
  );
}

class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph({required this.level});

  final int? level;

  @override
  Widget build(BuildContext context) {
    final percentage = (level ?? 96).clamp(0, 100);
    final color = percentage <= 15
        ? const Color(0xFFE05252)
        : const Color(0xFF4A9B75);
    return SizedBox(
      width: 19,
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.2),
                borderRadius: BorderRadius.circular(3.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percentage / 100),
                  duration: const Duration(milliseconds: 350),
                  builder: (context, fill, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill,
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 3.5,
            bottom: 3.5,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    required this.tint,
  });
  final ReferenceSymbol icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        ReferenceIcon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: color),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: ReferenceUi.ink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: ReferenceUi.secondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ActivityContent extends StatefulWidget {
  const ActivityContent({super.key, this.heartRateOnly = false});
  final bool heartRateOnly;

  @override
  State<ActivityContent> createState() => _ActivityContentState();
}

class _ActivityContentState extends State<ActivityContent> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _t(context, 'Activity', 'النشاط'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ReferenceUi.ink,
                ),
              ),
            ),
          ),
          const ReferenceIcon(
            ReferenceSymbol.calendar,
            size: 19,
            color: ReferenceUi.secondary,
          ),
        ],
      ),
      const SizedBox(height: 25),
      if (!widget.heartRateOnly) ...[
        Text(
          _t(context, 'Active energy', 'الطاقة النشطة'),
          style: const TextStyle(fontSize: 13, color: ReferenceUi.secondary),
        ),
        const SizedBox(height: 2),
        _ValueWithUnit(
          value: _showReferencePreviewData ? '109' : '—',
          unit: 'kcal',
          size: 42,
        ),
        const SizedBox(height: 20),
      ],
      Row(
        children: [
          Expanded(
            child: _StatColumn(
              title: _t(context, 'Average heart rate', 'متوسط نبض القلب'),
              value: _showReferencePreviewData ? '144' : '—',
              unit: 'bpm',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatColumn(
              title: _t(context, 'Maximum heart rate', 'أعلى نبض'),
              value: _showReferencePreviewData ? '161' : '—',
              unit: 'bpm',
            ),
          ),
        ],
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          Expanded(
            child: Text(
              _t(context, 'Heart Rate Training Zones', 'مناطق تدريب نبض القلب'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ReferenceUi.ink,
              ),
            ),
          ),
          const ReferenceIcon(
            ReferenceSymbol.info,
            size: 15,
            color: ReferenceUi.secondary,
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (var zone = 0; zone < 6; zone++) _ZoneRow(zone: zone),
      const SizedBox(height: 2),
      Text(
        _showReferencePreviewData
            ? _t(
                context,
                'No heart rate detected for 1 minute (9%).',
                'لم يتم رصد نبض القلب لمدة دقيقة واحدة (9٪).',
              )
            : _t(
                context,
                'No heart rate readings for this period.',
                'لا توجد قراءات نبض لهذه الفترة.',
              ),
        style: const TextStyle(fontSize: 12, color: ReferenceUi.secondary),
      ),
      const SizedBox(height: 18),
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _t(context, 'Charts', 'الرسوم البيانية'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: ReferenceUi.ink,
                  ),
                ),
              ),
              const Spacer(),
              ReferenceIcon(
                _expanded
                    ? ReferenceSymbol.chevronDown
                    : ReferenceSymbol.chevronRight,
                size: 18,
                color: ReferenceUi.secondary,
              ),
            ],
          ),
        ),
      ),
      if (_expanded) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                _t(context, 'Heart rate', 'نبض القلب'),
                style: const TextStyle(
                  fontSize: 12,
                  color: ReferenceUi.secondary,
                ),
              ),
            ),
            Text(
              _showReferencePreviewData
                  ? '117–161 bpm'
                  : _t(context, 'No readings', 'لا توجد قراءات'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ReferenceUi.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _HeartRateChartPainter(
              isArabic: context.l10n.isArabic,
              showPreviewData: _showReferencePreviewData,
            ),
            child: Stack(
              children: [
                if (!_showReferencePreviewData)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _t(
                          context,
                          'Waiting for heart rate data',
                          'بانتظار بيانات النبض',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: ReferenceUi.secondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

class _ValueWithUnit extends StatelessWidget {
  const _ValueWithUnit({
    required this.value,
    required this.unit,
    this.size = 34,
  });
  final String value;
  final String unit;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: size,
          height: 1.1,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
          color: ReferenceUi.ink,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        unit,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ReferenceUi.ink,
        ),
      ),
    ],
  );
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.title,
    required this.value,
    required this.unit,
  });
  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: ReferenceUi.secondary),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: _ValueWithUnit(value: value, unit: unit, size: 32),
      ),
    ],
  );
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({required this.zone});
  final int zone;

  static const _colors = [
    Color(0xFFBFC2C7),
    Color(0xFF69B9F5),
    Color(0xFFFFC533),
    Color(0xFFF58A48),
    Color(0xFFE14D58),
    Color(0xFF7354AB),
  ];
  static const _minutes = [
    '0 min',
    '1 min',
    '5 min',
    '4 min',
    '<1 min',
    '0 min',
  ];
  static const _percents = ['0%', '13%', '39%', '35%', '1%', '0%'];
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: _showReferencePreviewData
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final fraction = switch (zone) {
                      0 || 5 => .10,
                      1 => .19,
                      2 => .40,
                      3 => .36,
                      _ => .10,
                    };
                    final barWidth = constraints.maxWidth * fraction;
                    return Row(
                      children: [
                        Container(
                          width: barWidth,
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: zone == 5
                                ? _colors[zone].withValues(alpha: .18)
                                : _colors[zone],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$zone',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: zone == 5
                                  ? _colors[zone].withValues(alpha: .42)
                                  : const Color(0xFF171719),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _minutes[zone],
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                                color: ReferenceUi.ink,
                              ),
                            ),
                            Text(
                              _percents[zone],
                              style: const TextStyle(
                                fontSize: 11,
                                color: ReferenceUi.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                )
              : Row(
                  children: [
                    Container(
                      width: 42,
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: _colors[zone].withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$zone',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _colors[zone],
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _t(context, 'No data', 'لا توجد بيانات'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: ReferenceUi.secondary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class TrendsContent extends StatefulWidget {
  const TrendsContent({super.key});

  @override
  State<TrendsContent> createState() => _TrendsContentState();
}

class _TrendsContentState extends State<TrendsContent> {
  int _selectedMonthIndex = 2;
  static const _monthsEn = ['August', 'September', 'October'];
  static const _monthsAr = ['أغسطس', 'سبتمبر', 'أكتوبر'];

  @override
  Widget build(BuildContext context) {
    final months = context.l10n.isArabic ? _monthsAr : _monthsEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _showReferencePreviewData
                    ? 'Moonbeam'
                    : _t(context, 'Health insights', 'المؤشرات الصحية'),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: ReferenceUi.ink,
                ),
              ),
            ),
            ReferenceIcon(
              _showReferencePreviewData
                  ? ReferenceSymbol.search
                  : ReferenceSymbol.calendar,
              size: 19,
              color: ReferenceUi.secondary,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < months.length; i++) ...[
                      GestureDetector(
                        onTap: () => setState(() => _selectedMonthIndex = i),
                        child: Text(
                          months[i],
                          style: TextStyle(
                            fontSize: i == _selectedMonthIndex ? 16 : 14,
                            fontWeight: i == _selectedMonthIndex
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: i == _selectedMonthIndex
                                ? ReferenceUi.ink
                                : const Color(0xFFA4A4AA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const ReferenceIcon(
              ReferenceSymbol.calendar,
              size: 17,
              color: ReferenceUi.secondary,
            ),
          ],
        ),
        const SizedBox(height: 27),
        Row(
          children: [
            Expanded(
              child: Text(
                _showReferencePreviewData
                    ? _t(
                        context,
                        'Total health events',
                        'إجمالي المؤشرات الصحية',
                      )
                    : _t(context, 'Health overview', 'نظرة عامة على الصحة'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: ReferenceUi.secondary,
                ),
              ),
            ),
            const Icon(
              Icons.remove_circle_outline,
              size: 13,
              color: Color(0xFFB6B6BB),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: _showReferencePreviewData
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.arrow_drop_up_rounded,
                          size: 17,
                          color: Color(0xFF54A95B),
                        ),
                        Text(
                          '12.45%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF54A95B),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _t(context, 'No readings', 'لا توجد قراءات'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _showReferencePreviewData
                            ? Color(0xFF54A95B)
                            : ReferenceUi.secondary,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _showReferencePreviewData ? '211.8K' : '—',
          style: ReferenceUi.number,
        ),
        const SizedBox(height: 10),
        Text(
          _showReferencePreviewData
              ? _t(
                  context,
                  'Sample monthly activity and wellness data for preview. Connect your band to replace this with your own readings.',
                  'بيانات شهرية تجريبية للنشاط والعافية للمعاينة. وصّل السوار لاستبدالها بقراءاتك الفعلية.',
                )
              : _t(
                  context,
                  'Your health trends will take shape here as SANAD receives readings from your band.',
                  'ستظهر اتجاهاتك الصحية هنا عندما يستقبل سند قراءات من السوار.',
                ),
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: ReferenceUi.secondary,
          ),
        ),
        const SizedBox(height: 25),
        Container(
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8EB),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              for (final segment in const [
                (24, Color(0xFFE55AE8)),
                (23, Color(0xFFAE65D9)),
                (9, Color(0xFF777EF1)),
                (8, Color(0xFF42DDBB)),
                (5, Color(0xFFFFC642)),
                (3, Color(0xFFF28362)),
                (2, Color(0xFFEC666B)),
                (23, Color(0xFFBFC0C4)),
              ]) ...[
                Expanded(
                  flex: segment.$1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _showReferencePreviewData
                          ? segment.$2
                          : segment.$2.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_showReferencePreviewData)
          _Surface(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Steps', 'الخطوات'),
                        value: '50,400',
                        share: '23.79%',
                        color: const Color(0xFFE55AE8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Sleep', 'النوم'),
                        value: '49,200',
                        share: '23.22%',
                        color: const Color(0xFFAE65D9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Heart rate', 'نبض القلب'),
                        value: '19,900',
                        share: '9.35%',
                        color: const Color(0xFF777EF1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Activity', 'النشاط'),
                        value: '16,100',
                        share: '7.65%',
                        color: const Color(0xFF42DDBB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Readiness', 'الجاهزية'),
                        value: '11,400',
                        share: '5.38%',
                        color: const Color(0xFFFFC642),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Oxygen', 'الأكسجين'),
                        value: '5,500',
                        share: '2.55%',
                        color: const Color(0xFFF28362),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Weight', 'الوزن'),
                        value: '3,000',
                        share: '1.42%',
                        color: const Color(0xFFEC666B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewTrendItem(
                        title: _t(context, 'Other', 'أخرى'),
                        value: '48,300',
                        share: '22.66%',
                        color: const Color(0xFF9B9BA0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          _Surface(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                _TrendMetric(
                  icon: ReferenceSymbol.steps,
                  title: _t(context, 'Steps', 'الخطوات'),
                  color: const Color(0xFFE79A36),
                ),
                const Divider(height: 1, color: ReferenceUi.divider),
                _TrendMetric(
                  icon: ReferenceSymbol.heart,
                  title: _t(context, 'Heart rate', 'نبض القلب'),
                  color: const Color(0xFFD65B62),
                ),
                const Divider(height: 1, color: ReferenceUi.divider),
                _TrendMetric(
                  icon: ReferenceSymbol.moon,
                  title: _t(context, 'Sleep', 'النوم'),
                  color: const Color(0xFF8D63C7),
                ),
                const Divider(height: 1, color: ReferenceUi.divider),
                _TrendMetric(
                  icon: ReferenceSymbol.oxygen,
                  title: _t(context, 'Oxygen', 'الأكسجين'),
                  color: const Color(0xFF4A9EAD),
                ),
              ],
            ),
          ),
        if (!_showReferencePreviewData) ...[
          const SizedBox(height: 18),
          _NoDataNote(
            icon: ReferenceSymbol.chart,
            title: _t(context, 'No trends yet', 'لا توجد اتجاهات بعد'),
            subtitle: _t(
              context,
              'Connect a compatible band to start building your health history.',
              'وصّل سوارًا متوافقًا لبدء تسجيل تاريخك الصحي.',
            ),
          ),
        ],
      ],
    );
  }
}

class _TrendMetric extends StatelessWidget {
  const _TrendMetric({
    required this.icon,
    required this.title,
    required this.color,
  });
  final ReferenceSymbol icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: ReferenceIcon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: ReferenceUi.secondary),
          ),
        ),
        Text(
          _t(context, 'No data', 'لا توجد بيانات'),
          style: const TextStyle(fontSize: 11, color: ReferenceUi.secondary),
        ),
      ],
    ),
  );
}

class _PreviewTrendItem extends StatelessWidget {
  const _PreviewTrendItem({
    required this.title,
    required this.value,
    required this.share,
    required this.color,
  });

  final String title;
  final String value;
  final String share;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: ReferenceUi.secondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                height: 1.15,
                fontWeight: FontWeight.w500,
                color: ReferenceUi.ink,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          share,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: ReferenceUi.ink,
          ),
        ),
      ),
    ],
  );
}

class HealthContent extends StatefulWidget {
  const HealthContent({super.key, required this.onOpenTrends});
  final VoidCallback onOpenTrends;

  @override
  State<HealthContent> createState() => _HealthContentState();
}

class _HealthContentState extends State<HealthContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartMonitor;

  @override
  void initState() {
    super.initState();
    _heartMonitor = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14000),
    );
    if (_showReferencePreviewData) _heartMonitor.repeat();
  }

  @override
  void dispose() {
    _heartMonitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _t(context, 'Health', 'الصحة'),
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: ReferenceUi.ink,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        _t(context, 'Your body, in one place', 'مؤشرات جسمك في مكان واحد'),
        style: const TextStyle(fontSize: 13, color: ReferenceUi.secondary),
      ),
      const SizedBox(height: 22),
      AnimatedBuilder(
        animation: _heartMonitor,
        builder: (context, child) {
          final phase = _heartMonitor.value;
          final bpm = 60 + (math.sin(phase * math.pi * 2) * 2).round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _t(context, 'HEART RATE', 'نبض القلب'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .55,
                              color: ReferenceUi.secondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .82),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD85D68),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _showReferencePreviewData
                                    ? _t(context, 'SAMPLE', 'تجريبي')
                                    : _t(context, 'NO DATA', 'لا توجد قراءة'),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: .2,
                                  color: Color(0xFF9C5C64),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _showReferencePreviewData ? '$bpm' : '—',
                          style: const TextStyle(
                            fontSize: 52,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -2.8,
                            color: ReferenceUi.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'bpm',
                            style: const TextStyle(
                              fontSize: 13,
                              color: ReferenceUi.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_showReferencePreviewData)
                      Row(
                        children: [
                          Text(
                            _t(context, 'LIVE TRACE', 'مخطط النبض'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .35,
                              color: ReferenceUi.secondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _t(context, 'SAMPLE MONITOR', 'محاكاة تجريبية'),
                            style: const TextStyle(
                              fontSize: 8,
                              color: Color(0xFFAD777D),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (_showReferencePreviewData) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: SizedBox(
                    height: 76,
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        height: 76,
                        child: CustomPaint(
                          painter: _HeartRateMonitorPainter(progress: phase),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 0, 17, 13),
                  child: SizedBox(
                    height: 65,
                    child: Center(
                      child: Text(
                        _t(
                          context,
                          'Wear your band to see your heart rate trend.',
                          'ارتدِ السوار لمشاهدة تغيّر نبض القلب.',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: ReferenceUi.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 23),
      Row(
        children: [
          Expanded(
            child: Text(
              _t(context, 'Daily movement', 'حركة اليوم'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ReferenceUi.ink,
              ),
            ),
          ),
          Text(
            _t(context, 'TODAY', 'اليوم'),
            style: const TextStyle(fontSize: 10, color: ReferenceUi.secondary),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Text(
            _t(context, 'Steps', 'الخطوات'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ReferenceUi.ink,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _showReferencePreviewData ? '200' : '—',
            style: const TextStyle(
              fontSize: 43,
              height: 1,
              fontWeight: FontWeight.w600,
              letterSpacing: -2,
              color: ReferenceUi.ink,
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              _t(
                context,
                _showReferencePreviewData ? '/500 steps' : 'steps',
                _showReferencePreviewData ? '/500 خطوة' : 'خطوة',
              ),
              style: const TextStyle(
                fontSize: 13,
                color: ReferenceUi.secondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ActivityGoalChip(
            icon: ReferenceSymbol.flame,
            value: _showReferencePreviewData ? '50' : '—',
            target: '/300 kcal',
            color: const Color(0xFFE79A36),
          ),
          _ActivityGoalChip(
            icon: ReferenceSymbol.run,
            value: _showReferencePreviewData ? '0' : '—',
            target: '/30 min',
            color: const Color(0xFF47A8C2),
          ),
        ],
      ),
      const SizedBox(height: 25),
      Row(
        children: [
          Expanded(
            child: Text(
              _t(context, 'Body & recovery', 'الجسم والتعافي'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ReferenceUi.ink,
              ),
            ),
          ),
          InkWell(
            onTap: widget.onOpenTrends,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                _t(context, 'See insights', 'عرض المؤشرات'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6750A4),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _HealthSignalTile(
              title: _t(context, 'Sleep', 'النوم'),
              value: _showReferencePreviewData ? '7h 14m' : '—',
              detail: _showReferencePreviewData
                  ? _t(context, 'Score 72 · Fair', 'التقييم 72 · متوسط')
                  : _t(context, 'No reading', 'لا توجد قراءة'),
              icon: ReferenceSymbol.moon,
              color: const Color(0xFF8D63C7),
              tint: const Color(0xFFF3EFF9),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HealthSignalTile(
              title: _t(context, 'Weight', 'الوزن'),
              value: _showReferencePreviewData ? '70 kg' : '—',
              detail: _showReferencePreviewData
                  ? _t(context, 'Sample reading', 'قراءة تجريبية')
                  : _t(context, 'No reading', 'لا توجد قراءة'),
              icon: ReferenceSymbol.weight,
              color: const Color(0xFF6D63CB),
              tint: const Color(0xFFF0EFF9),
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const ReferenceIcon(
              ReferenceSymbol.oxygen,
              size: 19,
              color: Color(0xFF3C9FB0),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _t(context, 'Blood oxygen', 'أكسجين الدم'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ReferenceUi.ink,
                ),
              ),
            ),
            Text(
              _t(context, 'No reading', 'لا توجد قراءة'),
              style: const TextStyle(
                fontSize: 10,
                color: ReferenceUi.secondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HealthSignalTile extends StatelessWidget {
  const _HealthSignalTile({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String title;
  final String value;
  final String detail;
  final ReferenceSymbol icon;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 112),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ReferenceIcon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: ReferenceUi.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 21,
            height: 1,
            fontWeight: FontWeight.w600,
            letterSpacing: -.5,
            color: ReferenceUi.ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9, color: ReferenceUi.secondary),
        ),
      ],
    ),
  );
}

class _HeartRateMonitorPainter extends CustomPainter {
  const _HeartRateMonitorPainter({required this.progress});

  final double progress;

  static const _beatShape = [
    (0.00, 0.00),
    (0.12, 0.00),
    (0.18, 0.05),
    (0.22, 0.04),
    (0.28, 0.00),
    (0.31, -0.12),
    (0.34, 0.78),
    (0.37, -0.34),
    (0.41, 0.00),
    (0.55, 0.00),
    (0.63, 0.14),
    (0.70, 0.18),
    (0.77, 0.02),
    (0.84, 0.00),
    (1.00, 0.00),
  ];

  double _signalAt(double cycle) {
    for (var index = 1; index < _beatShape.length; index++) {
      final previous = _beatShape[index - 1];
      final next = _beatShape[index];
      if (cycle <= next.$1) {
        final amount = (cycle - previous.$1) / (next.$1 - previous.$1);
        return previous.$2 + (next.$2 - previous.$2) * amount;
      }
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const horizontalPadding = 0.0;
    final chartWidth = size.width - horizontalPadding * 2;
    final centerY = size.height * .56;
    final amplitude = size.height * .36;

    for (var row = 0; row < 3; row++) {
      final y = size.height * (.18 + row * .37);
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        Paint()
          ..color = const Color(0x1CD85D68)
          ..strokeWidth = .65,
      );
    }
    for (var column = 1; column < 12; column++) {
      final x = horizontalPadding + chartWidth * column / 12;
      canvas.drawLine(
        Offset(x, size.height * .12),
        Offset(x, size.height * .91),
        Paint()
          ..color = Color(column % 3 == 0 ? 0x20D85D68 : 0x0ED85D68)
          ..strokeWidth = .6,
      );
    }

    final trace = Path();
    const visibleBeats = 3.0;
    const points = 420;
    for (var index = 0; index <= points; index++) {
      final xRatio = index / points;
      final cycle = (xRatio * visibleBeats + progress * 9) % 1;
      final point = Offset(
        horizontalPadding + chartWidth * xRatio,
        centerY - _signalAt(cycle) * amplitude,
      );
      if (index == 0) {
        trace.moveTo(point.dx, point.dy);
      } else {
        trace.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      trace,
      Paint()
        ..color = const Color(0x25D85D68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      trace,
      Paint()
        ..color = const Color(0xFFD85D68)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HeartRateMonitorPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ActivityGoalChip extends StatelessWidget {
  const _ActivityGoalChip({
    required this.icon,
    required this.value,
    required this.target,
    required this.color,
  });

  final ReferenceSymbol icon;
  final String value;
  final String target;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReferenceIcon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ReferenceUi.ink,
          ),
        ),
        Text(
          target,
          style: const TextStyle(fontSize: 10, color: ReferenceUi.secondary),
        ),
      ],
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.showBorder = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showBorder;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: showBorder ? Border.all(color: const Color(0xFFE9E9EC)) : null,
    ),
    child: child,
  );
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });
  final ReferenceSymbol icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReferenceIcon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _NoDataNote extends StatelessWidget {
  const _NoDataNote({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final ReferenceSymbol icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F7F8),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        ReferenceIcon(icon, size: 20, color: ReferenceUi.secondary),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ReferenceUi.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: ReferenceUi.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActivityRingPainter extends CustomPainter {
  const _ActivityRingPainter({required this.isArabic});

  final bool isArabic;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .405;
    final strokeWidth = size.shortestSide * .12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = const Color(0xFFE5E6E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final cardioPaint = Paint()
      ..color = const Color(0xFF9BC5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    if (_showReferencePreviewData) {
      canvas.drawArc(
        rect,
        math.pi * .82,
        -math.pi * 2 * .56,
        false,
        cardioPaint,
      );

      // The capsule is the arc's rounded terminal segment, aligned to its tangent.
      const badgeAngle = math.pi * .82 - math.pi * 2 * .56;
      final badgeWidth = strokeWidth * 1.62;
      final arcEnd = Offset(
        center.dx + radius * math.cos(badgeAngle),
        center.dy + radius * math.sin(badgeAngle),
      );
      final flowAngle = badgeAngle + math.pi / 2;
      final badgeCenter = arcEnd;
      final badgeText = TextPainter(
        text: const TextSpan(
          text: '+34',
          style: TextStyle(
            color: Color(0xFF234F98),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(badgeCenter.dx, badgeCenter.dy);
      canvas.rotate(flowAngle);
      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: badgeWidth,
          height: strokeWidth,
        ),
        Radius.circular(strokeWidth / 2),
      );
      canvas.drawRRect(
        badgeRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF6FA0ED), Color(0xFF82B3F6), Color(0xFF9BC5FF)],
            stops: [0, .58, 1],
          ).createShader(badgeRect.outerRect),
      );
      // Keep the label legible while the capsule follows the arc tangent.
      canvas.rotate(math.pi);
      badgeText.paint(
        canvas,
        Offset(-badgeText.width / 2, -badgeText.height / 2),
      );
      canvas.restore();

      final labelRadius = radius - strokeWidth * .95;
      if (isArabic) {
        _paintCurvedLabel(
          canvas,
          'نشاط الأسبوع',
          center,
          labelRadius,
          -math.pi / 2,
          1,
          fontSize: size.shortestSide * .065,
          curveArabicAsWord: true,
        );
      } else {
        _paintCurvedLabel(
          canvas,
          'Weekly cardio',
          center,
          labelRadius,
          -math.pi / 2,
          1,
          fontSize: size.shortestSide * .065,
        );
      }
      _paintCurvedLabel(
        canvas,
        '222 of 384',
        center,
        labelRadius,
        math.pi / 2,
        -1,
        fontSize: size.shortestSide * .064,
      );
    }
  }

  void _paintCurvedLabel(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double middleAngle,
    int direction, {
    required double fontSize,
    bool curveArabicAsWord = false,
  }) {
    final style = TextStyle(
      color: const Color(0xFF24262B),
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      height: 1,
      letterSpacing: .1,
    );

    // Keep Arabic joined; the English reference uses individually rotated glyphs.
    if (curveArabicAsWord) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.rtl,
      )..layout();
      canvas.save();
      canvas.translate(center.dx, center.dy - radius);
      canvas.rotate(-.22);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
      return;
    }

    final glyphs = text.runes
        .map((rune) => String.fromCharCode(rune))
        .map((glyph) {
          final painter = TextPainter(
            text: TextSpan(text: glyph, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          return (painter: painter, advance: painter.width + .15);
        })
        .toList(growable: false);
    final totalAdvance = glyphs.fold<double>(
      0,
      (total, glyph) => total + glyph.advance,
    );
    var traveled = 0.0;
    for (final glyph in glyphs) {
      final along = traveled + glyph.advance / 2 - totalAdvance / 2;
      final angle = middleAngle + direction * along / radius;
      final rotation = direction == 1
          ? angle + math.pi / 2
          : angle - math.pi / 2;
      final position = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(rotation);
      glyph.painter.paint(
        canvas,
        Offset(-glyph.painter.width / 2, -glyph.painter.height / 2),
      );
      canvas.restore();
      traveled += glyph.advance;
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingPainter oldDelegate) => false;
}

class _SleepStagesPainter extends CustomPainter {
  const _SleepStagesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E2E6)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 3), Offset(x, size.height - 3), trackPaint);
    }
    final baseline = Paint()
      ..color = const Color(0xFFD8D8DD)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * .52),
      Offset(size.width, size.height * .52),
      baseline,
    );
    if (_showReferencePreviewData) {
      const segments = [
        (0.00, 0.12, 0),
        (0.12, 0.20, 2),
        (0.20, 0.24, 1),
        (0.24, 0.28, 3),
        (0.28, 0.36, 2),
        (0.36, 0.39, 0),
        (0.39, 0.50, 3),
        (0.50, 0.58, 2),
        (0.58, 0.61, 1),
        (0.61, 0.70, 3),
        (0.70, 0.79, 2),
        (0.79, 0.84, 0),
        (0.84, 1.00, 3),
      ];
      const colors = [
        Color(0xFFF184AF),
        Color(0xFF8D73C6),
        Color(0xFF75CDE2),
        Color(0xFF54B9C2),
      ];
      for (final segment in segments) {
        final y = switch (segment.$3) {
          0 => size.height * .12,
          1 => size.height * .31,
          2 => size.height * .51,
          _ => size.height * .72,
        };
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * segment.$1,
              y,
              size.width * (segment.$2 - segment.$1) - 2,
              8,
            ),
            const Radius.circular(4),
          ),
          Paint()..color = colors[segment.$3],
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SleepStagesPainter oldDelegate) => false;
}

class _HeartRateChartPainter extends CustomPainter {
  const _HeartRateChartPainter({
    required this.isArabic,
    required this.showPreviewData,
  });
  final bool isArabic;
  final bool showPreviewData;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 2.0;
    const top = 8.0;
    const rightLabelWidth = 32.0;
    const bottomLabelHeight = 22.0;
    final plotRight = size.width - rightLabelWidth;
    final plotBottom = size.height - bottomLabelHeight;
    final plotWidth = plotRight - left;
    final plotHeight = plotBottom - top;

    final grid = Paint()
      ..color = const Color(0xFFE1E2E5)
      ..strokeWidth = .8;
    for (final bpm in const [160, 120]) {
      final y = plotBottom - ((bpm - 110) / 60) * plotHeight;
      canvas.drawLine(Offset(left, y), Offset(plotRight, y), grid);
    }
    for (var tick = 0; tick <= 6; tick++) {
      final x = left + plotWidth * tick / 6;
      _drawDashedLine(
        canvas,
        Offset(x, top),
        Offset(x, plotBottom),
        Paint()
          ..color = const Color(0xFFE5E5E8)
          ..strokeWidth = .7,
      );
    }

    final averageY = plotBottom - ((144 - 110) / 60) * plotHeight;
    final average = Paint()
      ..color = const Color(0xFFB9A16A)
      ..strokeWidth = 1.1;
    canvas.drawLine(
      Offset(left, averageY),
      Offset(plotRight, averageY),
      average,
    );

    if (showPreviewData) {
      const samples = [
        (.08, .78, 0),
        (.10, .70, 0),
        (.13, .66, 0),
        (.17, .59, 0),
        (.22, .51, 1),
        (.25, .54, 1),
        (.29, .48, 1),
        (.33, .52, 1),
        (.37, .45, 1),
        (.41, .43, 1),
        (.44, .49, 1),
        (.48, .39, 2),
        (.51, .43, 2),
        (.55, .36, 2),
        (.59, .40, 2),
        (.63, .33, 2),
        (.68, .29, 2),
        (.72, .24, 3),
        (.76, .19, 3),
        (.80, .28, 3),
        (.84, .36, 2),
        (.87, .45, 1),
        (.91, .66, 0),
        (.94, .72, 0),
      ];
      const colors = [
        Color(0xFF69B9F5),
        Color(0xFFFFC533),
        Color(0xFFF58A48),
        Color(0xFFE14D58),
      ];
      for (final point in samples) {
        canvas.drawCircle(
          Offset(left + plotWidth * point.$1, top + plotHeight * point.$2),
          2.1,
          Paint()..color = colors[point.$3],
        );
      }
    }

    for (final item in const [(160, false), (144, true), (120, false)]) {
      final y = plotBottom - ((item.$1 - 110) / 60) * plotHeight;
      _paintChartLabel(
        canvas,
        '${item.$1}',
        Offset(plotRight + 5, y),
        color: item.$2 ? const Color(0xFFB99A55) : ReferenceUi.secondary,
        centeredVertically: true,
      );
    }

    final xLabels = isArabic
        ? const ['د', '2', '4', '6', '8', '10', '12']
        : const ['min', '2', '4', '6', '8', '10', '12'];
    for (var tick = 0; tick < xLabels.length; tick++) {
      final x = left + plotWidth * tick / 6;
      _paintChartLabel(
        canvas,
        xLabels[tick],
        Offset(x, plotBottom + 5),
        color: ReferenceUi.secondary,
        centeredHorizontally: true,
      );
    }
  }

  void _paintChartLabel(
    Canvas canvas,
    String value,
    Offset position, {
    required Color color,
    bool centeredHorizontally = false,
    bool centeredVertically = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(fontSize: 9, color: color),
      ),
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        position.dx - (centeredHorizontally ? painter.width / 2 : 0),
        position.dy - (centeredVertically ? painter.height / 2 : 0),
      ),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final delta = end - start;
    final distance = delta.distance;
    final direction = delta / distance;
    const dashLength = 3.0;
    const gapLength = 3.0;
    var traveled = 0.0;
    while (traveled < distance) {
      final dashEnd = math.min(traveled + dashLength, distance);
      canvas.drawLine(
        start + direction * traveled,
        start + direction * dashEnd,
        paint,
      );
      traveled += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _HeartRateChartPainter oldDelegate) =>
      oldDelegate.isArabic != isArabic ||
      oldDelegate.showPreviewData != showPreviewData;
}
