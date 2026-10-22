import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../application/auth/auth_failure.dart';
import '../../../application/auth/auth_service.dart';
import '../../../application/auth/auth_service_exception.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/auth/sanad_auth_logo.dart';
import '../../../utils/routes.dart';
import '../../widgets/login_screen_widgets/forgot_password_form.dart';
import '../../widgets/login_screen_widgets/login_footer_links.dart';
import '../../widgets/shared_widgets/auth_screen_styles.dart';
import '../../widgets/login_screen_widgets/login_form.dart';
import '../../widgets/login_screen_widgets/login_otp_form.dart';
import '../../widgets/login_screen_widgets/reset_password_form.dart';

enum _AuthView { login, otpVerify, forgotPassword, resetNewPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.arguments, this.authService});

  static const routeName = '/login';

  final AuthRouteArguments arguments;
  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  _AuthView _view = _AuthView.login;
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

  bool _obscureLogin = true, _obscureReset = true, _obscureResetConfirm = true;
  int _loginUserShake = 0, _loginPassShake = 0, _forgotEmailShake = 0;
  bool _loginUserErr = false, _loginPassErr = false, _forgotEmailErr = false;
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
    _resetNewPass.addListener(_validateResetPassword);
    _resetNewConfirm.addListener(_validateResetPassword);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localeInitialized) {
      _isArabic = context.l10n.isArabic;
      _localeInitialized = true;
    }
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

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    _resendTimer?.cancel();
    _loginUsername.dispose();
    _loginPassword.dispose();
    _otpCode.dispose();
    _forgotEmail.dispose();
    _resetNewPass.dispose();
    _resetNewConfirm.dispose();
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
          color: AppColor.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: success
                  ? AppColor.loginToastSuccessBackground
                  : AppColor.loginToastErrorBackground,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: AppColor.loginToastShadow,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  color: AppColor.surface,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: t(
                      color: AppColor.surface,
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
    });
  }

  Future<void> _signIn() async {
    if (_loading) return;
    final email = _loginUsername.text.trim();
    final validEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!validEmail || _loginPassword.text.isEmpty) {
      _showToast(
        !validEmail
            ? (_isArabic
                  ? 'أدخل بريدًا إلكترونيًا صحيحًا'
                  : 'Enter a valid email address')
            : (_isArabic ? 'أدخل كلمة المرور' : 'Enter your password'),
        success: false,
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await (widget.authService ?? AuthService.firebase()).signIn(
        email: email,
        password: _loginPassword.text,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      final message = switch (error.type) {
        AuthFailureType.invalidCredentials ||
        AuthFailureType.invalidEmail => context.l10n.authInvalidCredentials,
        AuthFailureType.network => context.l10n.authNetworkError,
        _ => context.l10n.authGenericError,
      };
      _showToast(message, success: false);
    } on AuthServiceException {
      if (mounted) _showToast(context.l10n.authGenericError, success: false);
    } catch (_) {
      if (mounted) _showToast(context.l10n.authGenericError, success: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _demoAction(String action, {String? email}) {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _loading = false);
      if (action == 'login') {
        _showToast(
          _isArabic
              ? 'واجهة تجريبية فقط، لم يتم إرسال البيانات'
              : 'Preview only. No data was sent.',
          success: true,
        );
      } else if (action == 'forgot_request' || action == 'verify_otp') {
        setState(() {
          _otpPurpose = action == 'forgot_request' ? 'reset' : 'login';
          _otpEmailMasked = email ?? _loginUsername.text;
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

  Widget _buildBrandHeader(BuildContext context) {
    return const SanadAuthLogo(artworkWidth: 100);
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.loginErrorBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.loginErrorBorder, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColor.loginError,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(
                color: AppColor.loginError,
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
              if (didPop || _view == _AuthView.otpVerify) return;
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
                              _AuthView.login => LoginForm(
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
                                onToggle: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.signup,
                                  arguments: widget.arguments,
                                ),
                                onForgot: () => _go(_AuthView.forgotPassword),
                                onSubmit: _signIn,
                              ),
                              _AuthView.otpVerify => LoginOtpForm(
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
                              _AuthView.forgotPassword => Align(
                                alignment: Alignment.topCenter,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                  ),
                                  child: ForgotPasswordForm(
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
                              ),
                              _AuthView.resetNewPassword =>
                                SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                  ),
                                  child: ResetPasswordForm(
                                    isArabic: _isArabic,
                                    loading: _loading,
                                    pass: _resetNewPass,
                                    confirm: _resetNewConfirm,
                                    obscure: _obscureReset,
                                    obscureConfirm: _obscureResetConfirm,
                                    minLen: _resetMinLen,
                                    hasUpper: _resetHasUpper,
                                    hasNum: _resetHasNumber,
                                    hasSpec: _resetHasSpecial,
                                    passMatch: _resetPassMatch,
                                    onToggleObscure: () => setState(
                                      () => _obscureReset = !_obscureReset,
                                    ),
                                    onToggleConfirm: () => setState(
                                      () => _obscureResetConfirm =
                                          !_obscureResetConfirm,
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
                            child: LoginFooterLinks(isArabic: _isArabic),
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
