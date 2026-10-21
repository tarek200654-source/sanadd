import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/auth/sanad_auth_logo.dart';
import '../../../utils/routes.dart';

extension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get sanadBg => isDark ? const Color(0xFF0D0D0D) : Colors.white;
  Color get sanadText => isDark ? Colors.white : Colors.black;
  Color get sanadDim => isDark ? Colors.white54 : Colors.black54;
  Color get sanadBorder =>
      isDark ? Colors.white10 : Colors.black.withOpacity(0.08);
  Color get sanadCardInner =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9);
}

enum _AuthView { login, register, otpVerify, forgotPassword, resetNewPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.arguments});

  static const routeName = '/login';

  final AuthRouteArguments arguments;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  _AuthView _view = _AuthView.login;
  int _regStep = 0;
  bool _loading = false;
  String? _error;
  bool _isArabic = false;
  bool _localeInitialized = false;
  String? _otpEmailMasked;
  String _otpPurpose = 'login';

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();
  final _otpCode = TextEditingController();
  final _forgotEmail = TextEditingController();
  final _resetNewPass = TextEditingController();
  final _resetNewConfirm = TextEditingController();

  final List<FocusNode> _otpFocus = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _otpDigits = List.generate(
    4,
    (_) => TextEditingController(),
  );

  final _regFirst = TextEditingController();
  final _regLast = TextEditingController();
  final _regUsername = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regAddress = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();

  String _selectedCountry = 'Egypt';
  String _selectedCountryCode = '+20';
  int _expectedPhoneLength = 10;
  String? _selectedGovernorate;
  bool _agreeTerms = true;

  bool _obscureLogin = true, _obscureReg = true, _obscureConfirm = true;
  int _loginUserShake = 0,
      _loginPassShake = 0,
      _regUserShake = 0,
      _regEmailShake = 0,
      _forgotEmailShake = 0;
  bool _loginUserErr = false,
      _loginPassErr = false,
      _regUserErr = false,
      _regEmailErr = false,
      _forgotEmailErr = false;

  Timer? _checkUserDebounce, _checkEmailDebounce;
  bool _checkingUsername = false, _checkingEmail = false;
  bool? _usernameTaken, _emailTaken;
  String? _usernameHint, _emailHint;

  bool _hasUpper = false,
      _hasNumber = false,
      _hasSpecial = false,
      _hasMinLen = false,
      _passMatch = false;
  bool _resetHasUpper = false,
      _resetHasNumber = false,
      _resetHasSpecial = false,
      _resetMinLen = false,
      _resetPassMatch = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _resendLeft = 0;
  Timer? _resendTimer;

  final Map<String, dynamic> _countryConfigs = {
    'Egypt': {'code': '+20', 'len': 10, 'flag': '🇪🇬'},
    'Saudi Arabia': {'code': '+966', 'len': 9, 'flag': '🇸🇦'},
    'UAE': {'code': '+971', 'len': 9, 'flag': '🇦🇪'},
    'Kuwait': {'code': '+965', 'len': 8, 'flag': '🇰🇼'},
    'Qatar': {'code': '+974', 'len': 8, 'flag': '🇶🇦'},
    'Oman': {'code': '+968', 'len': 8, 'flag': '🇴🇲'},
    'Bahrain': {'code': '+973', 'len': 8, 'flag': '🇧🇭'},
    'Jordan': {'code': '+962', 'len': 9, 'flag': '🇯🇴'},
    'USA': {'code': '+1', 'len': 10, 'flag': '🇺🇸'},
    'UK': {'code': '+44', 'len': 10, 'flag': '🇬🇧'},
  };

  static const Map<String, List<String>> _govsAr = {
    'Egypt': [
      'القاهرة',
      'الإسكندرية',
      'الجيزة',
      'الدقهلية',
      'البحر الأحمر',
      'البحيرة',
      'الفيوم',
      'الغربية',
      'الإسماعيلية',
      'المنوفية',
      'المنيا',
      'القليوبية',
      'الوادي الجديد',
      'الشرقية',
      'سوهاج',
      'جنوب سيناء',
      'السويس',
      'الأقصر',
      'قنا',
      'بني سويف',
      'بورسعيد',
      'دمياط',
      'مطروح',
      'شمال سيناء',
      'كفر الشيخ',
      'أسيوط',
      'أسوان',
    ],
    'Saudi Arabia': [
      'الرياض',
      'مكة المكرمة',
      'المدينة المنورة',
      'المنطقة الشرقية',
      'القصيم',
      'تبوك',
      'حائل',
      'جازان',
      'عسير',
      'نجران',
      'الجوف',
      'الحدود الشمالية',
      'الباحة',
    ],
    'UAE': [
      'أبو ظبي',
      'دبي',
      'الشارقة',
      'عجمان',
      'أم القيوين',
      'رأس الخيمة',
      'الفجيرة',
    ],
    'Kuwait': [
      'العاصمة',
      'حولي',
      'الأحمدي',
      'الجهراء',
      'الفروانية',
      'مبارك الكبير',
    ],
    'Qatar': [
      'الدوحة',
      'الريان',
      'الوكرة',
      'الخور',
      'الشمال',
      'الظعاين',
      'أم صلال',
      'الشيحانية',
    ],
    'Oman': [
      'مسقط',
      'ظفار',
      'مسندم',
      'البريمي',
      'الداخلية',
      'الظاهرة',
      'شمال الباطنة',
      'جنوب الباطنة',
      'شمال الشرقية',
      'جنوب الشرقية',
      'الوسطى',
    ],
    'Bahrain': ['العاصمة', 'المحرق', 'الشمالية', 'الجنوبية'],
    'Jordan': [
      'عمان',
      'إربد',
      'الزرقاء',
      'المفرق',
      'عجلون',
      'جرش',
      'مادبا',
      'البلقاء',
      'الكرك',
      'الطفيلة',
      'معان',
      'العقبة',
    ],
    'USA': [
      'ألاباما',
      'ألاسكا',
      'أريزونا',
      'أركنساس',
      'كاليفورنيا',
      'كولورادو',
      'كونيتيكت',
      'ديلاوير',
      'فلوريدا',
      'جورجيا',
      'هاواي',
      'أيداهو',
      'إلينوي',
      'إنديانا',
      'أيووا',
      'كانساس',
      'كنتاكي',
      'لويزيانا',
      'مين',
      'ماريلاند',
      'ماساتشوستس',
      'ميشيغان',
      'مينيسوتا',
      'ميسيسيبي',
      'ميسوري',
      'مونتانا',
      'نبراسكا',
      'نيفادا',
      'نيو هامبشاير',
      'نيوجيرسي',
      'نيو مكسيكو',
      'نيويورك',
      'نورث كارولينا',
      'نورث داكوتا',
      'أوهايو',
      'أوكلاهوما',
      'أوريغون',
      'بنسلفانيا',
      'رود آيلاند',
      'ساوث كارولينا',
      'ساوث داكوتا',
      'تينيسي',
      'تكساس',
      'يوتا',
      'فيرمونت',
      'فرجينيا',
      'واشنطن',
      'فرجينيا الغربية',
      'ويسكونسن',
      'وايومنغ',
    ],
    'UK': ['إنجلترا', 'اسكتلندا', 'ويلز', 'أيرلندا الشمالية'],
  };

  static const Map<String, List<String>> _govsEn = {
    'Egypt': [
      'Cairo',
      'Alexandria',
      'Giza',
      'Dakahlia',
      'Red Sea',
      'Beheira',
      'Fayoum',
      'Gharbia',
      'Ismailia',
      'Monufia',
      'Minya',
      'Qalyubia',
      'New Valley',
      'Sharqia',
      'Sohag',
      'South Sinai',
      'Suez',
      'Luxor',
      'Qena',
      'Beni Suef',
      'Port Said',
      'Damietta',
      'Matrouh',
      'North Sinai',
      'Kafr El Sheikh',
      'Asyut',
      'Aswan',
    ],
    'Saudi Arabia': [
      'Riyadh',
      'Makkah',
      'Madinah',
      'Eastern Province',
      'Qassim',
      'Tabuk',
      'Hail',
      'Jazan',
      'Asir',
      'Najran',
      'Al Jawf',
      'Northern Borders',
      'Al Bahah',
    ],
    'UAE': [
      'Abu Dhabi',
      'Dubai',
      'Sharjah',
      'Ajman',
      'Umm Al Quwain',
      'Ras Al Khaimah',
      'Fujairah',
    ],
    'Kuwait': [
      'Al Asimah',
      'Hawalli',
      'Al Ahmadi',
      'Al Jahra',
      'Farwaniya',
      'Mubarak Al-Kabeer',
    ],
    'Qatar': [
      'Doha',
      'Al Rayyan',
      'Al Wakrah',
      'Al Khor',
      'Al Shamal',
      'Al Daayen',
      'Umm Salal',
      'Al Shahaniya',
    ],
    'Oman': [
      'Muscat',
      'Dhofar',
      'Musandam',
      'Al Buraimi',
      'Ad Dakhiliyah',
      'Ad Dhahirah',
      'Al Batinah North',
      'Al Batinah South',
      'Ash Sharqiyah North',
      'Ash Sharqiyah South',
      'Al Wusta',
    ],
    'Bahrain': ['Capital', 'Muharraq', 'Northern', 'Southern'],
    'Jordan': [
      'Amman',
      'Irbid',
      'Zarqa',
      'Mafraq',
      'Ajloun',
      'Jerash',
      'Madaba',
      'Balqa',
      'Karak',
      'Tafileh',
      'Ma\'an',
      'Aqaba',
    ],
    'USA': [
      'Alabama',
      'Alaska',
      'Arizona',
      'Arkansas',
      'California',
      'Colorado',
      'Connecticut',
      'Delaware',
      'Florida',
      'Georgia',
      'Hawaii',
      'Idaho',
      'Illinois',
      'Indiana',
      'Iowa',
      'Kansas',
      'Kentucky',
      'Louisiana',
      'Maine',
      'Maryland',
      'Massachusetts',
      'Michigan',
      'Minnesota',
      'Mississippi',
      'Missouri',
      'Montana',
      'Nebraska',
      'Nevada',
      'New Hampshire',
      'New Jersey',
      'New Mexico',
      'New York',
      'North Carolina',
      'North Dakota',
      'Ohio',
      'Oklahoma',
      'Oregon',
      'Pennsylvania',
      'Rhode Island',
      'South Carolina',
      'South Dakota',
      'Tennessee',
      'Texas',
      'Utah',
      'Vermont',
      'Virginia',
      'Washington',
      'West Virginia',
      'Wisconsin',
      'Wyoming',
    ],
    'UK': ['England', 'Scotland', 'Wales', 'Northern Ireland'],
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animController.forward();
    _regPassword.addListener(_validatePassword);
    _regConfirm.addListener(_validatePassword);
    _resetNewPass.addListener(_validateResetPassword);
    _resetNewConfirm.addListener(_validateResetPassword);
    _regUsername.addListener(_onUsernameChanged);
    _regEmail.addListener(_onEmailChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localeInitialized) {
      _isArabic = context.l10n.isArabic;
      _localeInitialized = true;
    }
  }

  void _validatePassword() {
    final pass = _regPassword.text;
    setState(() {
      _hasMinLen = pass.length >= 8;
      _hasUpper = pass.contains(RegExp(r'[A-Z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
      _hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _passMatch = pass.isNotEmpty && pass == _regConfirm.text;
    });
  }

  void _validateResetPassword() {
    final pass = _resetNewPass.text;
    setState(() {
      _resetMinLen = pass.trim().length >= 8;
      _resetHasUpper = pass.contains(RegExp(r'[A-Z]'));
      _resetHasNumber = pass.contains(RegExp(r'[0-9]'));
      _resetHasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _resetPassMatch = pass.isNotEmpty && pass == _resetNewConfirm.text;
    });
  }

  void _onUsernameChanged() {
    final v = _regUsername.text.trim();
    _checkUserDebounce?.cancel();
    setState(() {
      _usernameTaken = null;
      _usernameHint = null;
      _checkingUsername = v.isNotEmpty;
      _regUserErr = false;
    });
    if (v.length < 3) {
      if (v.isNotEmpty)
        setState(() {
          _checkingUsername = false;
        });
      return;
    }
    _checkUserDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _regUsername.text.trim() != v) return;
      setState(() {
        _checkingUsername = false;
        _usernameTaken = false;
        _usernameHint = _isArabic ? 'متاح للمعاينة' : 'Available for preview';
      });
    });
  }

  void _onEmailChanged() {
    final v = _regEmail.text.trim();
    _checkEmailDebounce?.cancel();
    setState(() {
      _emailTaken = null;
      _emailHint = null;
      _checkingEmail = v.isNotEmpty;
      _regEmailErr = false;
    });
    bool isComplete =
        v.contains('.') && v.substring(v.lastIndexOf('.')).length >= 3;
    if (!isComplete) {
      setState(() => _checkingEmail = false);
      return;
    }
    _checkEmailDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _regEmail.text.trim() != v) return;
      final valid =
          v.contains('@') && v.substring(v.lastIndexOf('.')).length >= 3;
      setState(() {
        _checkingEmail = false;
        _emailTaken = !valid;
        _emailHint = valid
            ? (_isArabic ? 'صالح للمعاينة' : 'Valid for preview')
            : (_isArabic ? 'تحقق من البريد' : 'Check the email');
      });
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    _resendTimer?.cancel();
    _checkUserDebounce?.cancel();
    _checkEmailDebounce?.cancel();
    _loginUsername.dispose();
    _loginPassword.dispose();
    _otpCode.dispose();
    _forgotEmail.dispose();
    _resetNewPass.dispose();
    _resetNewConfirm.dispose();
    _regFirst.dispose();
    _regLast.dispose();
    _regUsername.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regAddress.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    for (final c in _otpDigits) c.dispose();
    for (final f in _otpFocus) f.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _syncOtpCode() {
    _otpCode.text = _otpDigits.map((e) => e.text.trim()).join();
  }

  void _clearOtpInputs() {
    for (final c in _otpDigits) c.clear();
    _otpCode.clear();
  }

  void _startResendTimer([int seconds = 30]) {
    _resendTimer?.cancel();
    setState(() => _resendLeft = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendLeft <= 1) {
        t.cancel();
        setState(() => _resendLeft = 0);
        return;
      }
      setState(() => _resendLeft--);
    });
  }

  void _showToast(String message, {required bool success}) {
    if (!mounted) return;
    final msg = message.trim();
    if (msg.isEmpty) return;
    _toastTimer?.cancel();
    _toastEntry?.remove();
    final t = _isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    _toastEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 18,
        left: 14,
        right: 14,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: success
                  ? const Color(0xFF0F2A1A)
                  : const Color(0xFF2A0F0F),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: t(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_toastEntry!);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  void _go(_AuthView view) {
    setState(() {
      _error = null;
      _view = view;
      _regStep = 0;
    });
  }

  void _demoAction(String action, {String? email}) {
    if (_loading) return;
    if (action == 'register') {
      Navigator.pushNamed(
        context,
        AppRoutes.otpVerification,
        arguments: widget.arguments.copyWith(
          email: _regEmail.text.trim(),
          name: '${_regFirst.text.trim()} ${_regLast.text.trim()}'.trim(),
          password: _regPassword.text,
          phoneNumber:
              '$_selectedCountryCode${_regPhone.text.replaceAll(RegExp(r'\D'), '')}',
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _loading = false);
      if (action == 'login' || action == 'register') {
        _showToast(
          _isArabic
              ? 'واجهة تجريبية فقط، لم يتم إرسال البيانات'
              : 'Preview only. No data was sent.',
          success: true,
        );
      } else if (action == 'forgot_request' || action == 'verify_otp') {
        setState(() {
          _otpPurpose = action == 'forgot_request' ? 'reset' : 'login';
          _otpEmailMasked = email ?? _regEmail.text;
        });
        _clearOtpInputs();
        _startResendTimer();
        _go(_AuthView.otpVerify);
      } else if (action == 'forgot_verify') {
        _go(_AuthView.resetNewPassword);
      } else if (action == 'forgot_set_password') {
        _showToast(
          _isArabic ? 'تمت المعاينة' : 'Preview complete',
          success: true,
        );
        _go(_AuthView.login);
      }
    });
  }

  void _showGovPicker() {
    final list = _isArabic
        ? _govsAr[_selectedCountry]
        : _govsEn[_selectedCountry];
    if (list == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SimplePicker(
        title: _isArabic ? 'اختر المنطقة' : 'Select Area',
        items: list,
        isArabic: _isArabic,
        onSelected: (v) => setState(() => _selectedGovernorate = v),
      ),
    );
  }

  void _showCountryPicker() {
    final list = _countryConfigs.keys
        .map((k) => '${_countryConfigs[k]['flag']} $k')
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SimplePicker(
        title: _isArabic ? 'اختر الدولة' : 'Select Country',
        items: list,
        isArabic: _isArabic,
        onSelected: (v) {
          final name = v.split(' ').sublist(1).join(' ');
          setState(() {
            _selectedCountry = name;
            _selectedCountryCode = _countryConfigs[name]['code'];
            _expectedPhoneLength = _countryConfigs[name]['len'];
            _regPhone.clear();
            _selectedGovernorate = null;
          });
        },
      ),
    );
  }

  void _showCountryCodePicker() {
    final list = _countryConfigs.keys
        .map(
          (k) => '${_countryConfigs[k]['flag']} ${_countryConfigs[k]['code']}',
        )
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SimplePicker(
        title: _isArabic ? 'كود الدولة' : 'Country Code',
        items: list,
        isArabic: _isArabic,
        onSelected: (v) {
          final code = v.split(' ')[1];
          final name = _countryConfigs.keys.firstWhere(
            (k) => _countryConfigs[k]['code'] == code,
          );
          setState(() {
            _selectedCountryCode = code;
            _selectedCountry = name;
            _expectedPhoneLength = _countryConfigs[name]['len'];
            _regPhone.clear();
          });
        },
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return const SanadAuthLogo(artworkWidth: 100);
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool showHeader =
        (_view == _AuthView.login ||
        _view == _AuthView.forgotPassword ||
        _view == _AuthView.resetNewPassword);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: PopScope(
            canPop: _view == _AuthView.login,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_view == _AuthView.register && _regStep > 0)
                setState(() => _regStep--);
              // Block back on OTP
              else if (_view == _AuthView.otpVerify)
                return;
              else
                _go(_AuthView.login);
            },
            child: Scaffold(
              backgroundColor: context.sanadBg,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            child: Row(
                              children: [
                                _buildBrandHeader(context),
                                const Spacer(),
                              ],
                            ),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: _buildErrorCard(),
                          ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            child: switch (_view) {
                              _AuthView.login => _MasterLoginForm(
                                isArabic: _isArabic,
                                loading: _loading,
                                username: _loginUsername,
                                password: _loginPassword,
                                obscure: _obscureLogin,
                                usernameError: _loginUserErr,
                                passwordError: _loginPassErr,
                                usernameShake: _loginUserShake,
                                passwordShake: _loginPassShake,
                                onToggleObscure: () => setState(
                                  () => _obscureLogin = !_obscureLogin,
                                ),
                                onToggle: () => _go(_AuthView.register),
                                onForgot: () => _go(_AuthView.forgotPassword),
                                onSubmit: () {
                                  final email = _loginUsername.text.trim();
                                  final validEmail = RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(email);
                                  if (!validEmail ||
                                      _loginPassword.text.isEmpty) {
                                    _showToast(
                                      !validEmail
                                          ? (_isArabic
                                                ? 'أدخل بريدًا إلكترونيًا صحيحًا'
                                                : 'Enter a valid email address')
                                          : (_isArabic
                                                ? 'أدخل كلمة المرور'
                                                : 'Enter your password'),
                                      success: false,
                                    );
                                    return;
                                  }
                                  _demoAction('login');
                                },
                              ),
                              _AuthView.register => _MasterRegisterForm(
                                regStep: _regStep,
                                isArabic: _isArabic,
                                loading: _loading,
                                first: _regFirst,
                                last: _regLast,
                                username: _regUsername,
                                email: _regEmail,
                                phone: _regPhone,
                                address: _regAddress,
                                password: _regPassword,
                                confirm: _regConfirm,
                                selectedGov: _selectedGovernorate,
                                selectedCountry: _selectedCountry,
                                selectedCountryCode: _selectedCountryCode,
                                expectedPhoneLength: _expectedPhoneLength,
                                agreeTerms: _agreeTerms,
                                onStepNext: () {
                                  if (_regStep < 6)
                                    setState(() => _regStep++);
                                  else {
                                    _demoAction('register');
                                  }
                                },
                                onStepBack: () {
                                  if (_regStep > 0)
                                    setState(() => _regStep--);
                                  else
                                    _go(_AuthView.login);
                                },
                                onAgreeToggle: (v) =>
                                    setState(() => _agreeTerms = v),
                                onToggleObscure: () =>
                                    setState(() => _obscureReg = !_obscureReg),
                                onToggleConfirm: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                onGovTap: _showGovPicker,
                                onCountryTap: _showCountryPicker,
                                onCountryCodeTap: _showCountryCodePicker,
                                onToggle: () => _go(_AuthView.login),
                                usernameError: _regUserErr,
                                emailError: _regEmailErr,
                                usernameShake: _regUserShake,
                                emailShake: _regEmailShake,
                                usernameChecking: _checkingUsername,
                                emailChecking: _checkingEmail,
                                usernameHint: _usernameHint,
                                emailHint: _emailHint,
                                usernameTaken: _usernameTaken,
                                emailTaken: _emailTaken,
                                obscure: _obscureReg,
                                obscureConfirm: _obscureConfirm,
                                hasUpper: _hasUpper,
                                hasNum: _hasNumber,
                                hasSpec: _hasSpecial,
                                hasMinLen: _hasMinLen,
                                passMatch: _passMatch,
                              ),
                              _AuthView.otpVerify => _MasterOtpForm(
                                isArabic: _isArabic,
                                loading: _loading,
                                digits: _otpDigits,
                                focusNodes: _otpFocus,
                                subtitle: _otpEmailMasked,
                                resendLeft: _resendLeft,
                                onDigitChanged: _syncOtpCode,
                                onSubmit: () {
                                  _syncOtpCode();
                                  if (_otpCode.text.length != 4) return;
                                  _demoAction(
                                    _otpPurpose == 'reset'
                                        ? 'forgot_verify'
                                        : 'verify_otp',
                                  );
                                },
                                onResend: () {
                                  _clearOtpInputs();
                                  _startResendTimer();
                                  _showToast(
                                    _isArabic
                                        ? 'معاينة فقط، لم يتم إرسال كود'
                                        : 'Preview only. No code was sent.',
                                    success: true,
                                  );
                                },
                              ),
                              _AuthView.forgotPassword => SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: _MasterForgotForm(
                                  isArabic: _isArabic,
                                  loading: _loading,
                                  email: _forgotEmail,
                                  emailError: _forgotEmailErr,
                                  emailShake: _forgotEmailShake,
                                  onBack: () => _go(_AuthView.login),
                                  onSubmit: () => _demoAction(
                                    'forgot_request',
                                    email: _forgotEmail.text.trim(),
                                  ),
                                ),
                              ),
                              _AuthView.resetNewPassword =>
                                SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                  ),
                                  child: _MasterResetNewPassForm(
                                    isArabic: _isArabic,
                                    loading: _loading,
                                    pass: _resetNewPass,
                                    confirm: _resetNewConfirm,
                                    obscure: _obscureReg,
                                    obscureConfirm: _obscureConfirm,
                                    minLen: _resetMinLen,
                                    hasUpper: _resetHasUpper,
                                    hasNum: _resetHasNumber,
                                    hasSpec: _resetHasSpecial,
                                    passMatch: _resetPassMatch,
                                    onToggleObscure: () => setState(
                                      () => _obscureReg = !_obscureReg,
                                    ),
                                    onToggleConfirm: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    onBack: () => _go(_AuthView.login),
                                    onSubmit: () =>
                                        _demoAction('forgot_set_password'),
                                  ),
                                ),
                            },
                          ),
                        ),
                        if (showHeader && !isKeyboardVisible)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24, top: 20),
                            child: _FooterLinks(isArabic: _isArabic),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MasterRegisterForm extends StatelessWidget {
  final int regStep;
  final VoidCallback onStepNext, onStepBack;
  final bool isArabic,
      loading,
      obscure,
      obscureConfirm,
      hasUpper,
      hasNum,
      hasSpec,
      hasMinLen,
      passMatch,
      agreeTerms;
  final String? selectedGov, selectedCountry, selectedCountryCode;
  final int expectedPhoneLength;
  final TextEditingController first,
      last,
      username,
      email,
      phone,
      address,
      password,
      confirm;
  final bool usernameError, emailError;
  final int usernameShake, emailShake;
  final bool usernameChecking, emailChecking;
  final String? usernameHint, emailHint;
  final bool? usernameTaken, emailTaken;
  final VoidCallback onToggle,
      onToggleObscure,
      onToggleConfirm,
      onGovTap,
      onCountryTap,
      onCountryCodeTap;
  final Function(bool) onAgreeToggle;
  const _MasterRegisterForm({
    required this.regStep,
    required this.onStepNext,
    required this.onStepBack,
    required this.isArabic,
    required this.loading,
    required this.first,
    required this.last,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
    required this.password,
    required this.confirm,
    required this.onToggle,
    this.selectedGov,
    this.selectedCountry,
    this.selectedCountryCode,
    required this.expectedPhoneLength,
    required this.agreeTerms,
    required this.onAgreeToggle,
    required this.onToggleObscure,
    required this.onToggleConfirm,
    required this.onGovTap,
    required this.onCountryTap,
    required this.onCountryCodeTap,
    required this.hasUpper,
    required this.hasNum,
    required this.hasSpec,
    required this.hasMinLen,
    required this.passMatch,
    required this.obscure,
    required this.obscureConfirm,
    this.usernameError = false,
    this.emailError = false,
    this.usernameShake = 0,
    this.emailShake = 0,
    this.usernameChecking = false,
    this.emailChecking = false,
    this.usernameHint,
    this.emailHint,
    this.usernameTaken,
    this.emailTaken,
  });

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool isCompact = MediaQuery.sizeOf(context).height < 720;
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final String title = switch (regStep) {
      0 => isArabic ? 'أهلاً بك، ابدأ ببريدك' : 'Welcome, Start with email',
      1 => isArabic ? 'اسم المستخدم' : 'Choose username',
      2 => isArabic ? 'ما هو اسمك؟' : 'What is your name?',
      3 => isArabic ? 'كلمة المرور' : 'Secure account',
      4 => isArabic ? 'رقم الهاتف' : 'Phone number',
      5 => isArabic ? 'أين تسكن؟' : 'Where do you live?',
      6 => isArabic ? 'الخطوة الأخيرة' : 'Almost there',
      _ => '',
    };
    bool canNext = switch (regStep) {
      0 => email.text.contains('@') && emailTaken == false,
      1 => username.text.length >= 3 && usernameTaken == false,
      2 => first.text.isNotEmpty && last.text.isNotEmpty,
      3 => passMatch && hasMinLen,
      4 => phone.text.trim().length == expectedPhoneLength,
      5 => selectedCountry != null && selectedGov != null,
      6 => address.text.isNotEmpty,
      _ => false,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onStepBack,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.sanadBorder),
                  ),
                  child: Transform.flip(
                    flipX: isArabic,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: context.sanadText,
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  7,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: i == regStep ? 24 : 10,
                    height: 4,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: i <= regStep
                          ? context.sanadText
                          : context.sanadBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        SizedBox(height: isKeyboardVisible ? 12 : (isCompact ? 18 : 32)),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isKeyboardVisible ? 0.3 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: context.sanadText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'يرجى إكمال البيانات للمتابعة'
                      : 'Please complete the details to continue',
                  style: t(fontSize: 15, color: context.sanadDim),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isKeyboardVisible ? 12 : (isCompact ? 18 : 32)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: AlignmentDirectional.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: _buildForm(context),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            12,
            28,
            isKeyboardVisible ? 12 : (isCompact ? 16 : 24),
          ),
          child: GestureDetector(
            onTap: canNext ? onStepNext : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: canNext ? 1.0 : 0.3,
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  color: context.sanadText,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    regStep == 6
                        ? (isArabic ? 'إنهاء التسجيل' : 'Finish')
                        : (isArabic ? 'التالي' : 'Next'),
                    style: t(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        key: ValueKey(regStep),
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (regStep) {
            0 => _MasterInput(
              label: isArabic ? 'البريد' : 'Email',
              controller: email,
              isArabic: isArabic,
              icon: Icons.mail_outline_rounded,
              error: emailError,
              helperText: emailHint,
              helperColor: emailTaken == true ? Colors.redAccent : Colors.green,
              hint: 'example@email.com',
            ),
            1 => _MasterInput(
              label: isArabic ? 'اسم المستخدم' : 'Username',
              controller: username,
              isArabic: isArabic,
              icon: Icons.alternate_email_rounded,
              error: usernameError,
              helperText: usernameHint,
              helperColor: usernameTaken == true
                  ? Colors.redAccent
                  : Colors.green,
              suffix: usernameChecking
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: context.sanadDim,
                        ),
                      ),
                    )
                  : null,
              hint: isArabic ? 'مثال: sara_ahmed' : 'e.g. sara_ahmed',
            ),
            2 => Column(
              children: [
                _MasterInput(
                  label: isArabic ? 'الاسم الأول' : 'First Name',
                  controller: first,
                  isArabic: isArabic,
                  icon: Icons.person_outline_rounded,
                  hint: 'Ahmed',
                ),
                const SizedBox(height: 20),
                _MasterInput(
                  label: isArabic ? 'الاسم الأخير' : 'Last Name',
                  controller: last,
                  isArabic: isArabic,
                  icon: Icons.person_outline_rounded,
                  hint: 'Mostafa',
                ),
              ],
            ),
            3 => Column(
              children: [
                _MasterInput(
                  label: isArabic ? 'كلمة المرور' : 'Password',
                  controller: password,
                  obscure: obscure,
                  isArabic: isArabic,
                  icon: Icons.password_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: onToggleObscure,
                  ),
                  extraLabel: _SanadStatusDots(
                    status: [hasMinLen, hasUpper, hasNum, hasSpec],
                  ),
                  hint: '********',
                ),
                const SizedBox(height: 20),
                _MasterInput(
                  label: isArabic ? 'التأكيد' : 'Confirm',
                  controller: confirm,
                  obscure: obscureConfirm,
                  isArabic: isArabic,
                  icon: Icons.password_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: onToggleConfirm,
                  ),
                  hint: '********',
                ),
              ],
            ),
            4 => _MasterInput(
              label: isArabic ? 'رقم الهاتف' : 'Phone',
              controller: phone,
              isArabic: isArabic,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(expectedPhoneLength),
                _NoLeadingZeroFormatter(),
              ],
              hint: isArabic
                  ? 'أدخل $expectedPhoneLength أرقام'
                  : 'Enter $expectedPhoneLength digits',
              prefix: GestureDetector(
                onTap: onCountryCodeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: context.sanadBorder, width: 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCountryCode ?? '+20',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            5 => Column(
              children: [
                GestureDetector(
                  onTap: onCountryTap,
                  child: AbsorbPointer(
                    child: _MasterInput(
                      label: isArabic ? 'الدولة' : 'Country',
                      controller: TextEditingController(text: selectedCountry),
                      isArabic: isArabic,
                      icon: Icons.public_rounded,
                      hint: 'Select Country',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onGovTap,
                  child: AbsorbPointer(
                    child: _MasterInput(
                      label: isArabic ? 'المنطقة' : 'Area',
                      controller: TextEditingController(text: selectedGov),
                      isArabic: isArabic,
                      icon: Icons.explore_outlined,
                      hint: 'Select Area',
                    ),
                  ),
                ),
              ],
            ),
            6 => _MasterInput(
              label: isArabic ? 'العنوان' : 'Address',
              controller: address,
              isArabic: isArabic,
              icon: Icons.location_on_outlined,
              hint: isArabic ? 'اكتب عنوانك بالتفصيل' : 'Enter your address',
              maxLines: 1,
            ),
            _ => const SizedBox(),
          },
        ],
      ),
    );
  }
}

class _MasterOtpForm extends StatelessWidget {
  final bool isArabic, loading;
  final List<TextEditingController> digits;
  final List<FocusNode> focusNodes;
  final String? subtitle;
  final int resendLeft;
  final VoidCallback onDigitChanged, onSubmit;
  final VoidCallback? onResend;
  const _MasterOtpForm({
    required this.isArabic,
    required this.loading,
    required this.digits,
    required this.focusNodes,
    required this.onSubmit,
    required this.onDigitChanged,
    this.subtitle,
    this.onResend,
    this.resendLeft = 0,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Column(
      key: const ValueKey('otp'),
      children: [
        const SizedBox(height: 40),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isKeyboardVisible ? 0.3 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'كود التحقق' : 'OTP Verification',
                        style: t(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: context.sanadText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic
                            ? 'أدخل الكود المكون من 4 أرقام المرسل لبريدك:\n$subtitle'
                            : 'Enter the 4-digit code sent to your email:\n$subtitle',
                        style: t(
                          fontSize: 16,
                          color: context.sanadDim,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: context.sanadCardInner,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: focusNodes[i].hasFocus
                                  ? context.sanadText
                                  : context.sanadBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: TextField(
                              controller: digits[i],
                              focusNode: focusNodes[i],
                              enabled: !loading,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: t(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: context.sanadText,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              onChanged: (v) {
                                if (v.isNotEmpty && i < 3)
                                  focusNodes[i + 1].requestFocus();
                                if (v.isEmpty && i > 0)
                                  focusNodes[i - 1].requestFocus();
                                onDigitChanged();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _MasterActionBtn(
                  text: isArabic ? 'استمرار' : 'Continue',
                  loading: loading,
                  onTap: onSubmit,
                  isArabic: isArabic,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TextButton(
                    onPressed: (loading || resendLeft > 0) ? null : onResend,
                    child: Text(
                      resendLeft > 0
                          ? (isArabic
                                ? 'إرسال خلال ${resendLeft}ث'
                                : 'Resend in ${resendLeft}s')
                          : (isArabic ? 'إعادة إرسال الكود' : 'Resend Code'),
                      style: t(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.sanadText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MasterLoginForm extends StatelessWidget {
  final bool isArabic, loading, obscure;
  final TextEditingController username, password;
  final bool usernameError, passwordError;
  final int usernameShake, passwordShake;
  final VoidCallback onToggle, onForgot, onSubmit, onToggleObscure;
  const _MasterLoginForm({
    required this.isArabic,
    required this.loading,
    required this.username,
    required this.password,
    required this.onToggle,
    required this.onForgot,
    required this.onSubmit,
    required this.obscure,
    required this.onToggleObscure,
    this.usernameError = false,
    this.passwordError = false,
    this.usernameShake = 0,
    this.passwordShake = 0,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        key: const ValueKey('login'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isKeyboardVisible ? 0.3 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تسجيل الدخول' : 'Log in to your account',
                  style: t(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: context.sanadText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic
                      ? 'أهلاً بك مجدداً! من فضلك أدخل بياناتك.'
                      : 'Welcome back! Please enter your details.',
                  style: t(fontSize: 16, color: context.sanadDim, height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(height: isKeyboardVisible ? 20 : 40),
          Expanded(
            child: SingleChildScrollView(
              physics: isKeyboardVisible
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  _MasterInput(
                    label: isArabic ? 'البريد الإلكتروني' : 'Email',
                    controller: username,
                    isArabic: isArabic,
                    icon: Icons.alternate_email_rounded,
                    inputKey: const ValueKey('auth-email-field'),
                    error: usernameError,
                    keyboardType: TextInputType.emailAddress,
                    hint: isArabic ? 'أدخل بريدك الإلكتروني' : 'you@email.com',
                  ),
                  const SizedBox(height: 24),
                  _MasterInput(
                    label: isArabic ? 'كلمة المرور' : 'Password',
                    controller: password,
                    obscure: obscure,
                    isArabic: isArabic,
                    icon: Icons.password_rounded,
                    inputKey: const ValueKey('auth-password-field'),
                    suffix: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 22,
                        color: context.sanadDim,
                      ),
                      onPressed: onToggleObscure,
                    ),
                    error: passwordError,
                    hint: '••••••••',
                  ),
                  Align(
                    alignment: isArabic
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: TextButton(
                      onPressed: onForgot,
                      child: Text(
                        isArabic ? 'نسيت كلمة المرور؟' : 'Forgot password?',
                        style: t(
                          color: context.sanadText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _MasterActionBtn(
                    key: const ValueKey('login-submit'),
                    text: isArabic ? 'تسجيل الدخول' : 'Sign in',
                    loading: loading,
                    onTap: onSubmit,
                    isArabic: isArabic,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isArabic
                              ? 'ليس لديك حساب؟ '
                              : "Don't have an account? ",
                          style: t(fontSize: 14, color: context.sanadDim),
                        ),
                        TextButton(
                          onPressed: onToggle,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isArabic ? 'أنشئ حساباً' : 'Sign up',
                            style: t(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.sanadText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldV,
    TextEditingValue newV,
  ) {
    if (newV.text.startsWith('0')) return oldV;
    return newV;
  }
}

class _SimplePicker extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool isArabic;
  final Function(String) onSelected;
  const _SimplePicker({
    required this.title,
    required this.items,
    required this.isArabic,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: context.sanadBg.withOpacity(0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: context.sanadBorder),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.sanadBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
              child: Row(
                children: [
                  Text(
                    title,
                    style: t(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.sanadText,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.sanadCardInner,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: context.sanadText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: context.sanadCardInner.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Text(
                        items[i],
                        style: t(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.sanadText,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: context.sanadDim,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      onTap: () {
                        onSelected(items[i]);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterForgotForm extends StatelessWidget {
  final bool isArabic, loading;
  final TextEditingController email;
  final bool emailError;
  final int emailShake;
  final VoidCallback onBack, onSubmit;
  const _MasterForgotForm({
    required this.isArabic,
    required this.loading,
    required this.email,
    this.emailError = false,
    this.emailShake = 0,
    required this.onBack,
    required this.onSubmit,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Column(
      key: const ValueKey('forgot'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
          style: t(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: context.sanadText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isArabic
              ? 'أدخل بريدك الإلكتروني لإرسال كود استعادة الحساب.'
              : 'Enter your email to receive account recovery code.',
          style: t(fontSize: 16, color: context.sanadDim, height: 1.5),
        ),
        const SizedBox(height: 40),
        _MasterInput(
          label: isArabic ? 'البريد الإلكتروني' : 'Email',
          controller: email,
          isArabic: isArabic,
          icon: Icons.mail_outline_rounded,
          error: emailError,
          hint: 'name@example.com',
        ),
        const SizedBox(height: 32),
        _MasterActionBtn(
          text: isArabic ? 'إرسال الكود' : 'Send Code',
          loading: loading,
          onTap: onSubmit,
          isArabic: isArabic,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: Text(
              isArabic ? 'رجوع' : 'Back',
              style: t(color: context.sanadDim, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _MasterResetNewPassForm extends StatelessWidget {
  final bool isArabic,
      loading,
      obscure,
      obscureConfirm,
      minLen,
      hasUpper,
      hasNum,
      hasSpec,
      passMatch;
  final TextEditingController pass, confirm;
  final VoidCallback onBack, onSubmit, onToggleObscure, onToggleConfirm;
  const _MasterResetNewPassForm({
    required this.isArabic,
    required this.loading,
    required this.pass,
    required this.confirm,
    required this.obscure,
    required this.obscureConfirm,
    required this.minLen,
    required this.hasUpper,
    required this.hasNum,
    required this.hasSpec,
    required this.passMatch,
    required this.onBack,
    required this.onSubmit,
    required this.onToggleObscure,
    required this.onToggleConfirm,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Column(
      key: const ValueKey('reset'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'كلمة مرور جديدة' : 'New Password',
          style: t(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: context.sanadText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isArabic
              ? 'من فضلك أدخل كلمة مرور قوية وجديدة.'
              : 'Please enter a strong new password.',
          style: t(fontSize: 16, color: context.sanadDim, height: 1.5),
        ),
        const SizedBox(height: 40),
        _MasterInput(
          label: isArabic ? 'كلمة المرور' : 'Password',
          controller: pass,
          obscure: obscure,
          isArabic: isArabic,
          icon: Icons.password_rounded,
          suffix: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: context.sanadDim,
            ),
            onPressed: onToggleObscure,
          ),
          extraLabel: _SanadStatusDots(
            status: [minLen, hasUpper, hasNum, hasSpec],
          ),
          hint: '********',
        ),
        const SizedBox(height: 20),
        _MasterInput(
          label: isArabic ? 'تأكيد كلمة المرور' : 'Confirm',
          controller: confirm,
          obscure: obscureConfirm,
          isArabic: isArabic,
          icon: Icons.password_rounded,
          suffix: IconButton(
            icon: Icon(
              obscureConfirm
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: context.sanadDim,
            ),
            onPressed: onToggleConfirm,
          ),
          hint: '••••••••',
        ),
        const SizedBox(height: 32),
        _MasterActionBtn(
          text: isArabic ? 'حفظ' : 'Save',
          loading: loading,
          onTap: onSubmit,
          isArabic: isArabic,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: Text(
              isArabic ? 'رجوع' : 'Back',
              style: t(color: context.sanadDim, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _SanadStatusDots extends StatelessWidget {
  final List<bool> status;
  const _SanadStatusDots({required this.status});
  @override
  Widget build(BuildContext context) {
    int metCount = status.where((e) => e).length;
    Color color = metCount == 0
        ? context.sanadBorder
        : metCount < 3
        ? Colors.orangeAccent
        : Colors.greenAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        status.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: status[i] ? 14 : 8,
          height: 4,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: status[i] ? color : context.sanadBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _MasterInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure, isArabic;
  final IconData? icon;
  final Widget? suffix, extraLabel, prefix;
  final bool error;
  final String? helperText, hint;
  final Color? helperColor;
  final Key? inputKey;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  const _MasterInput({
    this.inputKey,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.isArabic = false,
    this.icon,
    this.suffix,
    this.extraLabel,
    this.prefix,
    this.error = false,
    this.helperText,
    this.helperColor,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: t(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.sanadText.withOpacity(0.9),
                ),
              ),
              if (extraLabel != null) extraLabel!,
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.sanadCardInner,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error ? Colors.redAccent : context.sanadBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null) prefix!,
              Expanded(
                child: TextField(
                  key: inputKey,
                  controller: controller,
                  maxLines: maxLines,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  cursorColor: context.sanadText,
                  style: t(color: context.sanadText, fontSize: 16),
                  onChanged: (_) => (context as Element).markNeedsBuild(),
                  decoration: InputDecoration(
                    prefixIcon: icon != null
                        ? Icon(icon, color: context.sanadDim, size: 22)
                        : null,
                    suffixIcon: suffix,
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (helperText != null && helperText!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              helperText!,
              style: t(
                fontSize: 12,
                color: helperColor ?? context.sanadDim,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _MasterActionBtn extends StatelessWidget {
  final String text;
  final bool loading, isArabic;
  final VoidCallback onTap;
  const _MasterActionBtn({
    super.key,
    required this.text,
    required this.loading,
    required this.onTap,
    required this.isArabic,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Container(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.sanadText,
          foregroundColor: context.sanadBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: t(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: loading ? const _SquaresLoading() : Text(text),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  final bool isArabic;
  const _FooterLinks({required this.isArabic});
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final s = t(
      fontSize: 13,
      color: context.sanadDim,
      fontWeight: FontWeight.w600,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy', style: s),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('|', style: s.copyWith(color: context.sanadBorder)),
        ),
        Text(isArabic ? 'الشروط والأحكام' : 'Terms', style: s),
      ],
    );
  }
}

class _SquaresLoading extends StatefulWidget {
  final Color? color;
  const _SquaresLoading({this.color});
  @override
  State<_SquaresLoading> createState() => _SquaresLoadingState();
}

class _SquaresLoadingState extends State<_SquaresLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? context.sanadBg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            double value = (_anim.value - (i * 0.2)) % 1.0;
            double scale = value < 0.5
                ? 1.0 + (value * 0.6)
                : 1.3 - ((value - 0.5) * 0.6);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
