import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../application/auth/auth_service.dart';
import '../../../application/auth/auth_scope.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/caregiving_localizations.dart';
import '../../../core/localization/locale_scope.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/user_role.dart';
import '../../../utils/routes.dart';
import '../../widgets/home_widgets/health_dashboard.dart';
import '../../widgets/home_widgets/reference_ui.dart';
import '../../widgets/home_widgets/sanad_bottom_navigation.dart';

const _muted = Color(0xFF85858B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.authService, this.initialUser});
  final AuthService? authService;
  final AppUser? initialUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService _auth = widget.authService ?? AuthScope.read(context);
  late Future<AppUser?> _profile;
  final ValueNotifier<double> _settingsScrollOffset = ValueNotifier(0);
  bool _signingOut = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialUser == null
        ? _loadProfile()
        : Future.value(widget.initialUser);
  }

  Future<AppUser?> _loadProfile() => _auth.getCurrentUserProfile().then((user) {
    if (user == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      });
    }
    return user;
  });

  void _selectTab(int tab) {
    if (tab == 4) _settingsScrollOffset.value = 0;
    setState(() => _tab = tab);
  }

  @override
  void dispose() {
    _settingsScrollOffset.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.signOutFailed)));
      setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ReferenceUi.theme(Theme.of(context), context.l10n.isArabic),
    child: Builder(builder: _buildHome),
  );

  Widget _buildHome(BuildContext context) {
    final ar = context.l10n.isArabic;
    String tr(String en, String arabic) => ar ? arabic : en;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_tab == 4) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset + 190,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo by Nappy on Unsplash (free under Unsplash License).
                  Opacity(
                    opacity: .72,
                    child: Image.asset(
                      'assets/images/settings_care_poster.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0x14FFFFFF)),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 82,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0xBFFFFFFF),
                              Colors.white,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: _settingsScrollOffset,
              builder: (context, offset, child) => Positioned(
                top: (topInset + 230 - offset).clamp(
                  0.0,
                  MediaQuery.sizeOf(context).height,
                ),
                left: 0,
                right: 0,
                bottom: 0,
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          ],
          SafeArea(
            top: _tab != 4,
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: FutureBuilder<AppUser?>(
                  future: _profile,
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final loading =
                        snapshot.connectionState != ConnectionState.done;
                    final failed =
                        !loading && (snapshot.hasError || user == null);

                    return NotificationListener<ScrollNotification>(
                      key: ValueKey('dashboard-scroll-$_tab'),
                      onNotification: (notification) {
                        if (_tab == 4 &&
                            notification.depth == 0 &&
                            notification.metrics.axis == Axis.vertical) {
                          _settingsScrollOffset.value =
                              notification.metrics.pixels;
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          _tab == 4 ? 0 : 10,
                          18,
                          SanadBottomNavigation.height +
                              SanadBottomNavigation.bottomSpacing +
                              SanadBottomNavigation.contentClearance +
                              bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 80),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6750A4),
                                  ),
                                ),
                              )
                            else if (failed) ...[
                              Text(
                                tr(
                                  'Could not load your profile',
                                  'تعذر تحميل بيانات حسابك',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF171719),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: OutlinedButton.icon(
                                  onPressed: () => setState(() {
                                    _profile = _loadProfile();
                                  }),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 19,
                                    color: Color(0xFF171719),
                                  ),
                                  label: Text(
                                    tr('Try again', 'إعادة المحاولة'),
                                    style: const TextStyle(
                                      color: Color(0xFF171719),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (_tab != 4) ...[
                              HealthDashboard(
                                tab: _tab,
                                userName: user?.name,
                                userId: user?.uid,
                                onOpenProfile: () => _selectTab(4),
                                onOpenTab: _selectTab,
                              ),
                            ] else if (user != null) ...[
                              _settingsProfileHero(context, user, ar),
                              const SizedBox(height: 20),
                              _settingsSection(
                                tr('YOUR CARE', 'رعايتك'),
                                _settingsGroup([
                                  _settingsRow(
                                    icon: Icons.groups_2_outlined,
                                    label: user.role == UserRole.patient
                                        ? context.l10n.caregiversTitle
                                        : context.l10n.caregivingTitle,
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.caregiverLinks),
                                  ),
                                  _settingsRow(
                                    icon: Icons.medication_outlined,
                                    label: tr(
                                      'Medication schedule',
                                      'جدول الأدوية',
                                    ),
                                    onTap: () => _selectTab(1),
                                  ),
                                  _settingsRow(
                                    icon: Icons.monitor_heart_outlined,
                                    label: tr('Health overview', 'ملخص الصحة'),
                                    onTap: () => _selectTab(2),
                                  ),
                                  _settingsRow(
                                    icon: Icons.verified_user_outlined,
                                    label: tr(
                                      'Account security',
                                      'أمان الحساب',
                                    ),
                                    onTap: () => _showInfo(
                                      context,
                                      tr('Account security', 'أمان الحساب'),
                                      tr(
                                        'Sign-in is protected with a WhatsApp verification code.',
                                        'تسجيل الدخول محمي برمز تحقق عبر واتساب.',
                                      ),
                                    ),
                                    last: true,
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 18),
                              _settingsSection(
                                tr('APP & SUPPORT', 'التطبيق والدعم'),
                                _settingsGroup([
                                  _settingsRow(
                                    icon: Icons.shield_moon_outlined,
                                    label: tr(
                                      'Privacy & security',
                                      'الخصوصية والأمان',
                                    ),
                                    onTap: () => _showInfo(
                                      context,
                                      tr(
                                        'Privacy & security',
                                        'الخصوصية والأمان',
                                      ),
                                      tr(
                                        'Your health information is private to your SANAD account.',
                                        'بياناتك الصحية خاصة بحسابك في سند.',
                                      ),
                                    ),
                                  ),
                                  _settingsRow(
                                    icon: Icons.support_agent_outlined,
                                    label: tr(
                                      'Help & support',
                                      'المساعدة والدعم',
                                    ),
                                    onTap: () => _showInfo(
                                      context,
                                      tr('Help & support', 'المساعدة والدعم'),
                                      tr(
                                        'For help with SANAD, contact the support team.',
                                        'للمساعدة في استخدام سند، تواصل مع فريق الدعم.',
                                      ),
                                    ),
                                  ),
                                  _settingsRow(
                                    icon: Icons.rate_review_outlined,
                                    label: tr('Feedback', 'إرسال ملاحظات'),
                                    onTap: () => _showInfo(
                                      context,
                                      tr('Feedback', 'إرسال ملاحظات'),
                                      tr(
                                        'Feedback options will be available soon.',
                                        'إرسال الملاحظات سيكون متاحًا قريبًا.',
                                      ),
                                    ),
                                  ),
                                  _settingsRow(
                                    icon: Icons.translate_rounded,
                                    label: tr('Language', 'اللغة'),
                                    trailing: Text(
                                      tr('English', 'العربية'),
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onTap: () =>
                                        _showLanguagePicker(context, ar),
                                    last: true,
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: _settingsRow(
                                  icon: Icons.logout_rounded,
                                  label: tr('Sign out', 'تسجيل الخروج'),
                                  labelColor: const Color(0xFFD9534F),
                                  showChevron: false,
                                  onTap: _signingOut ? null : _signOut,
                                  last: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SanadBottomNavigation(
              selectedIndex: _tab,
              isArabic: ar,
              onSelected: _selectTab,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsAccountTile(
    BuildContext context,
    AppUser user,
    bool ar,
  ) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _showAccountDetails(context, user, ar),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(15, 14, 14, 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF0A8), Color(0xFFFFD1C1)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFF8E0),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🧑🏻‍🦱', style: TextStyle(fontSize: 39)),
                ),
                PositionedDirectional(
                  end: -1,
                  bottom: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF36B780),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.25,
                      color: Color(0xFF171719),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: _muted),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role == UserRole.patient
                              ? context.l10n.patient
                              : context.l10n.caregiver,
                          style: const TextStyle(
                            color: Color(0xFF64646B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        ar ? 'الحساب الشخصي' : 'Personal account',
                        style: const TextStyle(
                          color: Color(0xFF9A9AA1),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF0F0F2)),
              ),
              child: Icon(
                ar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                color: const Color(0xFF4D4D54),
                size: 22,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _settingsProfileHero(BuildContext context, AppUser user, bool ar) {
    final topInset = MediaQuery.paddingOf(context).top;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: topInset + 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: OverflowBox(
              minWidth: screenWidth,
              maxWidth: screenWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: screenWidth,
                height: topInset + 230,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .24, .40, .56, 1],
                        colors: [
                          Color(0x00FFFFFF),
                          Color(0x2EFFFFFF),
                          Color(0xA6FFFFFF),
                          Colors.white,
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _settingsAccountTile(context, user, ar),
          ),
        ],
      ),
    );
  }

  Widget _settingsGroup(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFB),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFECECEF), width: .8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Column(mainAxisSize: MainAxisSize.min, children: rows),
  );

  Widget _settingsSection(String title, Widget content) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 5, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF88888E),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .75,
          ),
        ),
      ),
      content,
    ],
  );

  Widget _settingsRow({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Widget? trailing,
    Color labelColor = const Color(0xFF29292D),
    bool showChevron = true,
    bool last = false,
  }) => Column(
    children: [
      SizedBox(
        height: 60,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              _settingsRowIcon(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
              if (showChevron) ...[
                if (trailing != null) const SizedBox(width: 5),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 21,
                  color: Color(0xFF66666B),
                ),
              ],
            ],
          ),
        ),
      ),
      if (!last)
        const Divider(height: 1, thickness: .6, color: Color(0xFFE9E9EC)),
    ],
  );

  Widget _settingsRowIcon(IconData icon) {
    final asset = switch (icon) {
      Icons.groups_2_outlined => 'user.svg',
      Icons.medication_outlined => 'calendar.svg',
      Icons.monitor_heart_outlined => 'chart-histogram.svg',
      Icons.verified_user_outlined => 'smartphone.svg',
      Icons.tune_rounded => 'apps.svg',
      Icons.shield_moon_outlined => 'info.svg',
      Icons.support_agent_outlined => 'comment.svg',
      Icons.rate_review_outlined => 'comment.svg',
      Icons.translate_rounded => 'globe.svg',
      Icons.logout_rounded => 'sign-out.svg',
      _ => null,
    };
    if (asset == null) {
      return Icon(icon, size: 22, color: const Color(0xFF77777D));
    }
    return SvgPicture.asset(
      'assets/icons/flaticon/$asset',
      width: 21,
      height: 21,
      colorFilter: const ColorFilter.mode(Color(0xFF77777D), BlendMode.srcIn),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    bool ar,
  ) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ar ? 'لغة التطبيق' : 'App language',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Text('🇸🇦'),
                title: Text(ar ? 'العربية' : 'Arabic'),
                trailing: ar ? const Icon(Icons.check_rounded) : null,
                onTap: () async {
                  await context.localeController.setLocale(const Locale('ar'));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Text('🇬🇧'),
                title: Text(ar ? 'الإنجليزية' : 'English'),
                trailing: !ar ? const Icon(Icons.check_rounded) : null,
                onTap: () async {
                  await context.localeController.setLocale(const Locale('en'));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _showInfo(BuildContext context, String title, String message) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.isArabic ? 'حسنًا' : 'OK'),
            ),
          ],
        ),
      );

  Future<void> _showAccountDetails(
    BuildContext context,
    AppUser user,
    bool ar,
  ) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ar ? 'بيانات الحساب' : 'Account details',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _accountDetail(ar ? 'البريد الإلكتروني' : 'Email', user.email),
              _accountDetail(
                ar ? 'واتساب' : 'WhatsApp',
                user.phoneNumber ?? '—',
              ),
              _accountDetail(
                ar ? 'الدور' : 'Role',
                user.role == UserRole.patient
                    ? context.l10n.patient
                    : context.l10n.caregiver,
              ),
              _accountDetail(ar ? 'المنطقة' : 'Region', user.region ?? '—'),
              _accountDetail(ar ? 'العنوان' : 'Address', user.address ?? '—'),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _signOut();
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(ar ? 'تسجيل الخروج' : 'Sign out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _accountDetail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
