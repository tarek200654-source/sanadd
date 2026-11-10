import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MedicationsContent extends StatefulWidget {
  const MedicationsContent({super.key, required this.userId});

  final String userId;

  @override
  State<MedicationsContent> createState() => _MedicationsContentState();
}

class _MedicationsContentState extends State<MedicationsContent> {
  static const _secureStorage = FlutterSecureStorage();
  static const _accent = Color(0xFF212529);
  static const _success = Color(0xFF23866A);
  static const _ink = Color(0xFF171719);
  static const _muted = Color(0xFF85858B);

  late final String _storageKey = 'sanad.medications.${widget.userId}';
  List<_Medication> _medications = [];
  bool _loading = true;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _tr(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _secureStorage.read(key: _storageKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List;
      final records = decoded
          .whereType<Map>()
          .map((value) => _Medication.fromMap(Map<String, dynamic>.from(value)))
          .toList();
      if (mounted) setState(() => _medications = records);
    } catch (_) {
      // A malformed local cache should not prevent managing the medication list.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    await _secureStorage.write(
      key: _storageKey,
      value: jsonEncode(
        _medications.map((medicine) => medicine.toMap()).toList(),
      ),
    );
  }

  Future<void> _addMedication() async {
    final result = await showModalBottomSheet<_Medication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: .84,
        minChildSize: .48,
        maxChildSize: .94,
        expand: false,
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) => _MedicationForm(
          isArabic: _isArabic,
          scrollController: scrollController,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _medications = [..._medications, result]);
    await _save();
  }

  Future<void> _toggleTaken(_Medication medicine, String time) async {
    setState(() {
      medicine.setDoseStatus(
        time,
        medicine.doseStatus(time) == 'taken' ? 'pending' : 'taken',
      );
    });
    await _save();
  }

  Future<void> _skipDose(_Medication medicine, String time) async {
    setState(() => medicine.setDoseStatus(time, 'skipped'));
    await _save();
  }

  Future<void> _delete(_Medication medicine) async {
    setState(() => _medications.remove(medicine));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final dueToday = _medications.fold<int>(
      0,
      (total, medicine) => total + medicine.times.length,
    );
    final doneToday = _medications.fold<int>(
      0,
      (total, medicine) =>
          total +
          medicine.times
              .where((time) => medicine.doseStatus(time) == 'taken')
              .length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _tr('Medications', 'الأدوية'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.4,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 46),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accent,
                ),
              ),
            ),
          )
        else if (_medications.isEmpty) ...[
          _medicinesHeader(),
          const SizedBox(height: 8),
          _emptyState(),
        ] else ...[
          _summary(dueToday, doneToday),
          const SizedBox(height: 18),
          _nextDoseCard(),
          const SizedBox(height: 24),
          _medicinesHeader(),
          const SizedBox(height: 8),
          ..._sortedMedications().map(_medicineTile),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _medicinesHeader() => Row(
    children: [
      Expanded(
        child: Text(
          _tr('Your medicines', 'أدويتك'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
      TextButton.icon(
        onPressed: _addMedication,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(_tr('Add', 'إضافة')),
        style: TextButton.styleFrom(
          foregroundColor: _accent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _summary(int due, int done) {
    final progress = due == 0 ? 0.0 : (done / due).clamp(0.0, 1.0);
    final remaining = (due - done).clamp(0, due);
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('TODAY', 'اليوم'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$due',
                          style: const TextStyle(
                            fontSize: 48,
                            height: .95,
                            letterSpacing: -2,
                            fontWeight: FontWeight.w500,
                            color: _ink,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 8,
                            bottom: 5,
                          ),
                          child: Text(
                            _tr('scheduled doses', 'جرعات مجدولة'),
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  remaining == 0
                      ? Icons.check_rounded
                      : Icons.medication_outlined,
                  size: 20,
                  color: remaining == 0 ? _success : _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFDDE0E3),
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining == 0
                      ? _tr('All doses completed', 'اكتملت جرعات اليوم')
                      : _tr(
                          '$remaining ${remaining == 1 ? 'dose' : 'doses'} left',
                          'متبقي $remaining جرعة',
                        ),
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ),
              Text(
                '$done / $due',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 218,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 27,
                right: 42,
                child: Container(
                  width: 126,
                  height: 126,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 38,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F3F4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.rotate(
                angle: -.52,
                child: Container(
                  width: 151,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: const Color(0xFFD8D8D6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFFEFB),
                                    Color(0xFFECE4D8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(width: 2, color: const Color(0xFFC9BEB2)),
                          const Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFEAA096),
                                    Color(0xFFC96D63),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        left: 18,
                        right: 18,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .42),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 36,
                left: 48,
                child: _emptyBadge(
                  Icons.schedule_rounded,
                  const Color(0xFF596975),
                ),
              ),
              Positioned(
                bottom: 35,
                right: 49,
                child: _emptyBadge(
                  Icons.check_rounded,
                  const Color(0xFF47816D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _tr('A little more organized', 'خلي مواعيد أدويتك أسهل'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            height: 1.2,
            letterSpacing: -.3,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tr(
            'Add your medicines and their prescribed times. Your daily schedule will appear here.',
            'أضف أدويتك ومواعيدها الموصوفة، وهتظهر لك هنا في جدول يومي واضح.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, height: 1.55, color: _muted),
        ),
      ],
    ),
  );

  Widget _emptyBadge(IconData icon, Color color) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, size: 19, color: color),
  );

  List<_Medication> _sortedMedications() => [..._medications]
    ..sort(
      (a, b) => (a.times.isEmpty ? '99:99' : a.times.first).compareTo(
        b.times.isEmpty ? '99:99' : b.times.first,
      ),
    );

  ({_Medication medicine, String time})? _nextDose() {
    final doses = <({_Medication medicine, String time})>[];
    for (final medicine in _medications) {
      for (final time in medicine.times) {
        if (!medicine.isTimeTaken(time)) {
          doses.add((medicine: medicine, time: time));
        }
      }
    }
    if (doses.isEmpty) return null;
    doses.sort((a, b) => a.time.compareTo(b.time));
    final now = TimeOfDay.now();
    for (final dose in doses) {
      final parts = dose.time.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      if (hour > now.hour || (hour == now.hour && minute >= now.minute)) {
        return dose;
      }
    }
    return doses.first;
  }

  Widget _nextDoseCard() {
    final dose = _nextDose();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: dose == null
          ? Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _success,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Text(
                  _tr('All scheduled doses are done', 'اكتملت كل جرعات اليوم'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    dose.time,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: _ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('UP NEXT', 'الجرعة القادمة'),
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dose.medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      Text(
                        '${dose.medicine.dose} · ${dose.medicine.formLabel(_isArabic)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _tr('Mark dose as taken', 'تسجيل تناول الجرعة'),
                  onPressed: () => _toggleTaken(dose.medicine, dose.time),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE6F1EB),
                    foregroundColor: _success,
                    fixedSize: const Size(38, 38),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 19),
                ),
              ],
            ),
    );
  }

  Widget _medicineTile(_Medication medicine) {
    final takenCount = medicine.times
        .where((time) => medicine.doseStatus(time) == 'taken')
        .length;
    return Dismissible(
      key: ValueKey(medicine.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsetsDirectional.only(end: 18),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFD95757),
        ),
      ),
      onDismissed: (_) => _delete(medicine),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F9),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 18,
                color: Color(0xFF52606D),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${medicine.dose} · ${medicine.formLabel(_isArabic)}',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final time in medicine.times)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _toggleTaken(medicine, time),
                          onLongPress: () => _skipDose(medicine, time),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: medicine.doseStatus(time) == 'taken'
                                  ? const Color(0xFFE7F2EC)
                                  : medicine.doseStatus(time) == 'missed'
                                  ? const Color(0xFFFFEEEE)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  medicine.doseStatus(time) == 'taken'
                                      ? Icons.check_circle_rounded
                                      : medicine.doseStatus(time) == 'missed'
                                      ? Icons.error_outline_rounded
                                      : medicine.doseStatus(time) == 'skipped'
                                      ? Icons.remove_circle_outline_rounded
                                      : Icons.access_time_rounded,
                                  size: 12,
                                  color: medicine.doseStatus(time) == 'taken'
                                      ? _success
                                      : medicine.doseStatus(time) == 'missed'
                                      ? const Color(0xFFD95757)
                                      : _muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: medicine.isTimeTaken(time)
                                        ? _success
                                        : _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (takenCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$takenCount/${medicine.times.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _success,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Medication {
  _Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.form,
    required this.times,
    this.frequency = 'onceDaily',
    this.days = const [],
    this.intervalHours = 0,
    this.startDate,
    this.endDate,
    this.noEndDate = true,
    this.relationToMeals = 'noPreference',
    this.instructions = '',
    this.specialNotes = '',
    this.remindersEnabled = true,
    this.notifyCaregiver = false,
    this.escalationDelayMinutes = 30,
    this.takenDate,
    List<String>? takenTimes,
  }) : takenTimes = takenTimes ?? [];

  final String id;
  final String name;
  final String dose;
  final String form;
  final List<String> times;
  final String frequency;
  final List<int> days;
  final int intervalHours;
  final String? startDate;
  final String? endDate;
  final bool noEndDate;
  final String relationToMeals;
  final String instructions;
  final String specialNotes;
  final bool remindersEnabled;
  final bool notifyCaregiver;
  final int escalationDelayMinutes;
  String? takenDate;
  final List<String> takenTimes;

  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool isTimeTaken(String time) =>
      takenDate == _todayKey && takenTimes.contains(time);

  final Map<String, String> doseStatuses = {};

  String doseStatus(String time) {
    final key = '$_todayKey|$time';
    final stored = doseStatuses[key];
    if (stored != null) return stored;
    final parts = time.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      final due = DateTime.now().copyWith(
        hour: hour,
        minute: minute,
        second: 0,
      );
      if (DateTime.now().isAfter(
        due.add(Duration(minutes: escalationDelayMinutes)),
      )) {
        return 'missed';
      }
    }
    return 'pending';
  }

  void setDoseStatus(String time, String status) {
    final key = '$_todayKey|$time';
    doseStatuses[key] = status;
    if (status == 'taken') {
      if (takenDate != _todayKey) {
        takenDate = _todayKey;
        takenTimes.clear();
      }
      if (!takenTimes.contains(time)) takenTimes.add(time);
    } else {
      takenTimes.remove(time);
    }
  }

  void toggleTime(String time) {
    if (takenDate != _todayKey) {
      takenDate = _todayKey;
      takenTimes.clear();
    }
    if (!takenTimes.remove(time)) takenTimes.add(time);
  }

  String formLabel(bool ar) => switch (form) {
    'capsule' => ar ? 'كبسولة' : 'Capsule',
    'syrup' => ar ? 'شراب' : 'Syrup',
    'drops' => ar ? 'نقط' : 'Drops',
    'injection' => ar ? 'حقن' : 'Injection',
    'inhaler' => ar ? 'بخاخ' : 'Inhaler',
    'cream' => ar ? 'كريم / مرهم' : 'Cream / Ointment',
    'other' => ar ? 'أخرى' : 'Other',
    _ => ar ? 'قرص' : 'Tablet',
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'dose': dose,
    'form': form,
    'times': times,
    'frequency': frequency,
    'days': days,
    'intervalHours': intervalHours,
    'startDate': startDate,
    'endDate': endDate,
    'noEndDate': noEndDate,
    'relationToMeals': relationToMeals,
    'instructions': instructions,
    'specialNotes': specialNotes,
    'remindersEnabled': remindersEnabled,
    'notifyCaregiver': notifyCaregiver,
    'escalationDelayMinutes': escalationDelayMinutes,
    'takenDate': takenDate,
    'takenTimes': takenTimes,
    'doseStatuses': doseStatuses,
  };

  factory _Medication.fromMap(Map<String, dynamic> map) =>
      _Medication(
          id:
              map['id'] as String? ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          name: map['name'] as String? ?? '',
          dose: map['dose'] as String? ?? '',
          form: map['form'] as String? ?? 'tablet',
          times: (map['times'] as List? ?? const ['08:00'])
              .whereType<String>()
              .toList(),
          frequency: map['frequency'] as String? ?? 'onceDaily',
          days: (map['days'] as List? ?? const []).whereType<int>().toList(),
          intervalHours: map['intervalHours'] as int? ?? 0,
          startDate: map['startDate'] as String?,
          endDate: map['endDate'] as String?,
          noEndDate: map['noEndDate'] as bool? ?? true,
          relationToMeals: map['relationToMeals'] as String? ?? 'noPreference',
          instructions: map['instructions'] as String? ?? '',
          specialNotes: map['specialNotes'] as String? ?? '',
          remindersEnabled: map['remindersEnabled'] as bool? ?? true,
          notifyCaregiver: map['notifyCaregiver'] as bool? ?? false,
          escalationDelayMinutes: map['escalationDelayMinutes'] as int? ?? 30,
          takenDate: map['takenDate'] as String?,
          takenTimes: (map['takenTimes'] as List? ?? const [])
              .whereType<String>()
              .toList(),
        )
        ..doseStatuses.addAll(
          Map<String, String>.from(map['doseStatuses'] as Map? ?? const {}),
        );
}

class _MedicationForm extends StatefulWidget {
  const _MedicationForm({
    required this.isArabic,
    required this.scrollController,
  });
  final bool isArabic;
  final ScrollController scrollController;

  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  static const _accent = Color(0xFF212529);
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '4');
  final _times = <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
  final _days = <int>{};
  String _form = 'tablet';
  String _doseUnit = 'mg';
  String _frequency = 'onceDaily';
  String _relation = 'noPreference';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _reminders = true;
  bool _caregiverAlert = false;
  int _delay = 30;

  String tr(String en, String ar) => widget.isArabic ? ar : en;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _times.isEmpty
          ? const TimeOfDay(hour: 8, minute: 0)
          : _times.last,
      helpText: tr('Choose dose time', 'اختر موعد الجرعة'),
    );
    if (selected != null && !_times.contains(selected)) {
      setState(() => _times.add(selected));
      _times.sort((a, b) => a.hour * 60 + a.minute - b.hour * 60 - b.minute);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final doseValue = _doseController.text.trim();
    final dose = '$doseValue $_doseUnit';
    final needsTimes = _frequency != 'asNeeded';
    final needsDays = _frequency == 'specificDays';
    if (name.isEmpty ||
        doseValue.isEmpty ||
        (needsTimes && _times.isEmpty) ||
        (needsDays && _days.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Enter a medicine name and dose.', 'اكتب اسم الدواء والجرعة.'),
          ),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final record = _Medication(
      id: '${now.microsecondsSinceEpoch}',
      name: name,
      dose: dose,
      form: _form,
      times: needsTimes ? _times.map(_formatTime).toList() : [],
      frequency: _frequency,
      days: _days.toList()..sort(),
      intervalHours: _frequency == 'everyHours'
          ? (int.tryParse(_intervalController.text) ?? 4)
          : 0,
      startDate: _dateKey(_startDate),
      endDate: _endDate == null ? null : _dateKey(_endDate!),
      noEndDate: _endDate == null,
      relationToMeals: _relation,
      instructions: _instructionsController.text.trim(),
      specialNotes: _notesController.text.trim(),
      remindersEnabled: _reminders,
      notifyCaregiver: _caregiverAlert,
      escalationDelayMinutes: _delay,
    );
    Navigator.of(context).pop(record);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : (_endDate ?? _startDate),
      firstDate: start ? DateTime(now.year - 1) : _startDate,
      lastDate: DateTime(now.year + 15),
    );
    if (date != null) {
      setState(() {
        if (start) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(date)) _endDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _weekday(int day) => switch (day) {
    1 => tr('Mon', 'اثن'),
    2 => tr('Tue', 'ثلا'),
    3 => tr('Wed', 'أرب'),
    4 => tr('Thu', 'خمي'),
    5 => tr('Fri', 'جمع'),
    6 => tr('Sat', 'سبت'),
    _ => tr('Sun', 'أحد'),
  };

  Widget _dropdown<T>({
    required T value,
    required List<T> values,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
  }) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: values
            .map((v) => DropdownMenuItem<T>(value: v, child: Text(label(v))))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        style: const TextStyle(fontSize: 12, color: Color(0xFF171719)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9DE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    Text(
                      tr('Add a medicine', 'إضافة دواء'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171719),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tr(
                        'Add the details from your prescription.',
                        'أدخل البيانات كما وردت في الوصفة الطبية.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF85858B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(
                      tr('Medication information', 'معلومات الدواء'),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel(tr('Medicine name', 'اسم الدواء')),
                    const SizedBox(height: 7),
                    _input(
                      _nameController,
                      tr('e.g. Vitamin D', 'مثال: فيتامين د'),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('Dose', 'الجرعة')),
                              const SizedBox(height: 7),
                              _input(
                                _doseController,
                                tr('e.g. 500', 'مثال: 500'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('Form', 'الشكل')),
                              const SizedBox(height: 7),
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _form,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'tablet',
                                        child: Text(tr('Tablet', 'قرص')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'capsule',
                                        child: Text(tr('Capsule', 'كبسولة')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'syrup',
                                        child: Text(tr('Syrup', 'شراب')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'drops',
                                        child: Text(tr('Drops', 'نقط')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'injection',
                                        child: Text(tr('Injection', 'حقن')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'inhaler',
                                        child: Text(tr('Inhaler', 'بخاخ')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cream',
                                        child: Text(
                                          tr('Cream / Ointment', 'كريم / مرهم'),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'other',
                                        child: Text(tr('Other', 'أخرى')),
                                      ),
                                    ],
                                    onChanged: (value) => setState(
                                      () => _form = value ?? 'tablet',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF171719),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(height: 15),
                    _fieldLabel(tr('Dose unit', 'وحدة الجرعة')),
                    const SizedBox(height: 7),
                    _dropdown<String>(
                      value: _doseUnit,
                      values: const [
                        'mg',
                        'g',
                        'ml',
                        'mcg',
                        'IU',
                        'tablet',
                        'capsule',
                        'drop',
                        'puff',
                      ],
                      label: (v) => v,
                      onChanged: (v) => setState(() => _doseUnit = v),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle(tr('Medication schedule', 'جدول الدواء')),
                    const SizedBox(height: 12),
                    _fieldLabel(tr('Frequency', 'التكرار')),
                    const SizedBox(height: 7),
                    _dropdown<String>(
                      value: _frequency,
                      values: const [
                        'onceDaily',
                        'twiceDaily',
                        'threeDaily',
                        'specificDays',
                        'everyHours',
                        'asNeeded',
                      ],
                      label: (v) => switch (v) {
                        'onceDaily' => tr('Once Daily', 'مرة يوميًا'),
                        'twiceDaily' => tr('Twice Daily', 'مرتين يوميًا'),
                        'threeDaily' => tr(
                          'Three Times Daily',
                          'ثلاث مرات يوميًا',
                        ),
                        'specificDays' => tr('Specific Days', 'أيام محددة'),
                        'everyHours' => tr('Every X Hours', 'كل عدد ساعات'),
                        _ => tr('As Needed (PRN)', 'عند الحاجة (PRN)'),
                      },
                      onChanged: (value) => setState(() {
                        _frequency = value;
                        final count = switch (value) {
                          'twiceDaily' => 2,
                          'threeDaily' => 3,
                          _ => 1,
                        };
                        if (value != 'asNeeded' &&
                            value != 'specificDays' &&
                            value != 'everyHours') {
                          while (_times.length < count) {
                            _times.add(
                              TimeOfDay(
                                hour: 8 + (_times.length * 6),
                                minute: 0,
                              ),
                            );
                          }
                          while (_times.length > count) {
                            _times.removeLast();
                          }
                        }
                      }),
                    ),
                    if (_frequency == 'everyHours') ...[
                      const SizedBox(height: 12),
                      _fieldLabel(tr('Interval in hours', 'الفاصل بالساعات')),
                      const SizedBox(height: 7),
                      _input(
                        _intervalController,
                        '4',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (_frequency == 'specificDays') ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (var day = 1; day <= 7; day++)
                            FilterChip(
                              label: Text(_weekday(day)),
                              selected: _days.contains(day),
                              onSelected: (selected) => setState(
                                () => selected
                                    ? _days.add(day)
                                    : _days.remove(day),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    _fieldLabel(tr('Reminder times', 'مواعيد التذكير')),
                    const SizedBox(height: 7),
                    if (_frequency == 'asNeeded')
                      Text(
                        tr(
                          'No fixed reminder time for as-needed medicine.',
                          'دواء عند الحاجة لا يحتاج موعدًا ثابتًا.',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF85858B),
                        ),
                      )
                    else if (_frequency == 'everyHours') ...[
                      Text(
                        tr('Starting at', 'يبدأ من'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF85858B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final time in _times.take(1))
                            InputChip(
                              avatar: const Icon(
                                Icons.access_time_rounded,
                                size: 15,
                              ),
                              label: Text(time.format(context)),
                              onPressed: () async {
                                final selected = await showTimePicker(
                                  context: context,
                                  initialTime: time,
                                );
                                if (selected != null) {
                                  setState(() => _times[0] = selected);
                                }
                              },
                              backgroundColor: const Color(0xFFF0F3FE),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF263B70),
                              ),
                            ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr(
                                'Select one or more times',
                                'اختر موعدًا أو أكثر',
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF85858B),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addTime,
                            icon: const Icon(Icons.add_rounded, size: 17),
                            label: Text(tr('Add time', 'إضافة موعد')),
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final time in _times)
                            InputChip(
                              avatar: const Icon(
                                Icons.access_time_rounded,
                                size: 15,
                              ),
                              label: Text(time.format(context)),
                              onDeleted: _times.length == 1
                                  ? null
                                  : () => setState(() => _times.remove(time)),
                              backgroundColor: const Color(0xFFF0F3FE),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF263B70),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _fieldLabel(tr('Start date', 'تاريخ البداية')),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('Start', 'البداية')),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                onPressed: () => _pickDate(start: true),
                                child: Text(_dateLabel(_startDate)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('End', 'النهاية')),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                onPressed: _endDate == null
                                    ? () =>
                                          setState(() => _endDate = _startDate)
                                    : () => _pickDate(start: false),
                                child: Text(
                                  _endDate == null
                                      ? tr('No end date', 'بدون نهاية')
                                      : _dateLabel(_endDate!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _endDate == null
                            ? null
                            : () => setState(() => _endDate = null),
                        child: Text(
                          tr('Remove end date', 'إزالة تاريخ النهاية'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle(
                      tr('Intake instructions', 'تعليمات الاستخدام'),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel(tr('Relation to meals', 'العلاقة بالأكل')),
                    const SizedBox(height: 7),
                    _dropdown<String>(
                      value: _relation,
                      values: const [
                        'beforeFood',
                        'afterFood',
                        'withFood',
                        'noPreference',
                      ],
                      label: (v) => switch (v) {
                        'beforeFood' => tr('Before Food', 'قبل الأكل'),
                        'afterFood' => tr('After Food', 'بعد الأكل'),
                        'withFood' => tr('With Food', 'مع الأكل'),
                        _ => tr('No Preference', 'بدون تحديد'),
                      },
                      onChanged: (v) => setState(() => _relation = v),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(
                      tr('Prescription instructions', 'تعليمات الوصفة'),
                    ),
                    const SizedBox(height: 7),
                    _input(
                      _instructionsController,
                      tr('As prescribed by your clinician', 'حسب وصف الطبيب'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(tr('Special notes', 'ملاحظات خاصة')),
                    const SizedBox(height: 7),
                    _input(
                      _notesController,
                      tr('Notes from your prescription', 'ملاحظات حسب الوصفة'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(
                        'Enter instructions as prescribed by your clinician; the app does not determine dosage.',
                        'أدخل التعليمات كما وصفها الطبيب؛ التطبيق لا يحدد الجرعة.',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF85858B),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle(
                      tr(
                        'Reminders & caregiver alerts',
                        'التذكيرات وتنبيهات المرافق',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tr('Enable medication reminders', 'تفعيل تذكير الدواء'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _reminders,
                      onChanged: (v) => setState(() => _reminders = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tr(
                          'Notify caregiver if missed',
                          'تنبيه المرافق عند تفويت الجرعة',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _caregiverAlert,
                      onChanged: (v) => setState(() => _caregiverAlert = v),
                    ),
                    if (_caregiverAlert) ...[
                      _fieldLabel(
                        tr('Escalation delay', 'مدة الانتظار قبل التنبيه'),
                      ),
                      const SizedBox(height: 7),
                      _dropdown<int>(
                        value: _delay,
                        values: const [15, 30, 60],
                        label: (v) => tr('$v minutes', '$v دقيقة'),
                        onChanged: (v) => setState(() => _delay = v),
                      ),
                    ],
                    const SizedBox(height: 21),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF171719),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          tr('Save medicine', 'حفظ الدواء'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF34343A),
    ),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 1),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -.15,
        color: Color(0xFF171719),
      ),
    ),
  );

  Widget _input(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAB1)),
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
    ),
  );
}
