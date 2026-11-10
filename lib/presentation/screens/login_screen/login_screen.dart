import '../../auth/validation/auth_validators.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../application/auth/auth_service.dart';
import '../../../application/auth/auth_scope.dart';
import '../../../data/network/api_exception.dart';
import '../../auth/api_error_message.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';

import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/auth/sanad_auth_logo.dart';
import '../../../presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import '../recovery_phone_screen/recovery_phone_screen.dart';
import '../../../utils/routes.dart';
import '../../widgets/login_screen_widgets/forgot_password_form.dart';
import '../../widgets/login_screen_widgets/login_footer_links.dart';
import '../../widgets/shared_widgets/auth_screen_styles.dart';
import '../../widgets/recovery_widgets/recovery_progress_header.dart';
import '../../widgets/login_screen_widgets/login_form.dart';
import '../../widgets/login_screen_widgets/reset_password_form.dart';

enum _AuthView { login, forgotPassword, resetNewPassword }

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

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();
  final _forgotEmail = TextEditingController();
  final _resetNewPass = TextEditingController();
  final _resetNewConfirm = TextEditingController();
  String? _lastRecoveryPhone;

  bool _obscureLogin = true, _obscureReset = true, _obscureResetConfirm = true;
  final int _loginUserShake = 0, _loginPassShake = 0, _forgotEmailShake = 0;
  final bool _loginUserErr = false,
      _loginPassErr = false,
      _forgotEmailErr = false;
  bool _resetHasUpper = false,
      _resetHasNumber = false,
      _resetHasSpecial = false,
      _resetMinLen = false,
      _resetPassMatch = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
    final policy = PasswordValidation.evaluate(pass);
    setState(() {
      _resetMinLen = policy.hasMinimumLength;
      _resetHasUpper = policy.hasUppercase && policy.hasLowercase;
      _resetHasNumber = policy.hasDigit;
      _resetHasSpecial = policy.hasSpecialCharacter;
      _resetPassMatch = pass.isNotEmpty && pass == _resetNewConfirm.text;
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();

    _toastEntry?.remove();
    _loginUsername.dispose();
    _loginPassword.dispose();
    _forgotEmail.dispose();
    _resetNewPass.dispose();
    _resetNewConfirm.dispose();
    _animController.dispose();
    super.dispose();
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
      final auth = widget.authService ?? AuthScope.read(context);
      final attempt = await auth.startLogin(
        email: email,
        password: _loginPassword.text,
        language: _isArabic ? 'ar' : 'en',
      );
      if (!mounted) return;
      _loginPassword.clear();
      final otpArguments = AuthRouteArguments(
        role: widget.arguments.role,
        email: email,
        isLoginVerification: true,
        phoneNumber: attempt.maskedPhoneNumber,
      );
      final result = await Navigator.of(context).push<String>(
        AppRoutes.transition<String>(
          settings: RouteSettings(
            name: AppRoutes.otpVerification,
            arguments: otpArguments,
          ),
          builder: (_) =>
              OtpVerificationScreen(arguments: otpArguments, authService: auth),
        ),
      );
      if (mounted && result is String) {
        _showToast(
          apiErrorMessage(context.l10n, ApiException(code: result)),
          success: false,
        );
      }
    } catch (error) {
      if (mounted) {
        _showToast(apiErrorMessage(context.l10n, error), success: false);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  AuthService get _auth => widget.authService ?? AuthScope.read(context);

  void _backFromRecovery() {
    if (_loading) return;
    _auth.discardRecovery();
    if (_view == _AuthView.resetNewPassword) {
      _resetNewPass.clear();
      _resetNewConfirm.clear();
      _go(_AuthView.forgotPassword);
      _recover('start');
    } else {
      _go(_AuthView.login);
    }
  }

  Future<void> _recover(String action) async {
    if (_loading) return;
    if (action == 'start' &&
        AuthValidators.validateEmail(_forgotEmail.text) != null) {
      _showToast(context.l10n.invalidEmailMessage, success: false);
      return;
    }
    if (action == 'reset' &&
        (AuthValidators.validatePassword(_resetNewPass.text) != null ||
            _resetNewPass.text != _resetNewConfirm.text)) {
      _showToast(
        _isArabic
            ? 'راجع شروط كلمة المرور وتأكيدها.'
            : 'Check the password requirements and confirmation.',
        success: false,
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (action == 'start') {
        final submittedEmail = _forgotEmail.text.trim().toLowerCase();
        final eligible = await _auth.checkRecoveryEligibility(submittedEmail);
        if (!mounted) return;
        if (_forgotEmail.text.trim().toLowerCase() != submittedEmail) return;
        if (!eligible) throw ApiException(code: 'recovery-not-eligible');
        final result = await Navigator.of(context).push<String>(
          AppRoutes.transition<String>(
            settings: const RouteSettings(name: RecoveryPhoneScreen.routeName),
            builder: (_) => RecoveryPhoneScreen(
              email: submittedEmail,
              role: widget.arguments.role,
              initialPhoneNumber: _lastRecoveryPhone,
              authService: _auth,
            ),
          ),
        );
        if (!mounted) return;
        if (result != null && _auth.hasVerifiedRecovery) {
          _lastRecoveryPhone = result;
          _go(_AuthView.resetNewPassword);
        } else {
          _auth.discardRecovery();
          _go(_AuthView.forgotPassword);
          if (result != null) {
            _error = apiErrorMessage(context.l10n, ApiException(code: result));
          }
        }
      } else {
        await _auth.resetPassword(_resetNewPass.text, _resetNewConfirm.text);
        if (mounted) {
          _resetNewPass.clear();
          _resetNewConfirm.clear();
          _forgotEmail.clear();
          _loginPassword.clear();
          _lastRecoveryPhone = null;
          _go(_AuthView.login);
        }
      }
    } catch (error) {
      if (!mounted) return;
      if (!_auth.hasPendingRecovery && action != 'start') {
        _resetNewPass.clear();
        _resetNewConfirm.clear();
        _view = _AuthView.forgotPassword;
      }
      setState(() => _error = apiErrorMessage(context.l10n, error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
            canPop: !_loading && _view == _AuthView.login,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop || _loading) return;
              _backFromRecovery();
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
                        if (_view != _AuthView.login)
                          RecoveryProgressHeader(
                            step: _view == _AuthView.forgotPassword
                                ? RecoveryStep.email
                                : RecoveryStep.resetPassword,
                            onBack: _backFromRecovery,
                          ),
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
                                onToggle: () {
                                  if (!_loading) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.roleSelection,
                                    );
                                  }
                                },
                                onForgot: () {
                                  if (!_loading) _go(_AuthView.forgotPassword);
                                },
                                onSubmit: _signIn,
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
                                    onSubmit: () => _recover('start'),
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
                                    onBack: _backFromRecovery,
                                    onSubmit: () => _recover('reset'),
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
