import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../application/auth/auth_scope.dart';
import '../../../application/auth/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../data/network/api_exception.dart';
import '../../../domain/models/user_role.dart';
import '../../../utils/routes.dart';
import '../../auth/api_error_message.dart';
import '../../auth/auth_route_arguments.dart';
import '../../auth/validation/auth_validators.dart';
import '../../widgets/recovery_widgets/recovery_country_picker.dart';
import '../../widgets/recovery_widgets/recovery_phone_form.dart';
import '../../widgets/shared_widgets/auth_screen_styles.dart';
import '../otp_verification_screen/otp_verification_screen.dart';

class RecoveryPhoneScreen extends StatefulWidget {
  const RecoveryPhoneScreen({
    super.key,
    required this.email,
    required this.role,
    this.initialPhoneNumber,
    this.authService,
  });

  static const routeName = '/password-recovery/phone';
  final String email;
  final UserRole role;
  final String? initialPhoneNumber;
  final AuthService? authService;

  @override
  State<RecoveryPhoneScreen> createState() => _RecoveryPhoneScreenState();
}

class _RecoveryPhoneScreenState extends State<RecoveryPhoneScreen>
    with SingleTickerProviderStateMixin {
  final _phone = TextEditingController();
  String _countryCode = AppConstants.defaultCountryCallingCode;
  int _numberLength = AppConstants.defaultNationalNumberLength;
  String? _attemptPhone, _error;
  bool _busy = false, _verified = false;
  late final AnimationController _animation;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  AuthService get _auth => widget.authService ?? AuthScope.read(context);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPhoneNumber;
    if (initial != null) {
      final countries = AppConstants.countries.values.toList()
        ..sort((a, b) => b.callingCode.length.compareTo(a.callingCode.length));
      for (final country in countries) {
        if (initial.startsWith(country.callingCode)) {
          _countryCode = country.callingCode;
          _numberLength = country.nationalNumberLength;
          _phone.text = initial.substring(_countryCode.length);
          break;
        }
      }
    }
    _phone.addListener(_refresh);
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(
      parent: _animation,
      curve: const Interval(0, 0.8, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animation,
            curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
          ),
        );
    _animation.forward();
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _phone.dispose();
    _animation.dispose();
    super.dispose();
  }

  void _back() {
    if (_busy) return;
    _auth.discardRecovery();
    Navigator.of(context).maybePop();
  }

  void _pickCountry() {
    final isArabic = context.l10n.isArabic;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.transparent,
      isScrollControlled: true,
      builder: (_) => RecoveryCountryPicker(
        title: isArabic ? 'كود الدولة' : 'Country Code',
        items: AppConstants.countries.values
            .map((country) => '${country.flag} ${country.callingCode}')
            .toList(),
        isArabic: isArabic,
        onSelected: (value) {
          final code = value.split(' ')[1];
          final country = AppConstants.countries.values.firstWhere(
            (country) => country.callingCode == code,
          );
          _auth.discardRecovery();
          setState(() {
            _countryCode = code;
            _numberLength = country.nationalNumberLength;
            _attemptPhone = null;
            _error = null;
            _phone.clear();
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_phone.text.trim().length != _numberLength ||
        AuthValidators.validatePhone(_countryCode, _phone.text) != null) {
      setState(() => _error = context.l10n.invalidPhoneMessage);
      return;
    }
    final phone = AuthValidators.normalizedPhone(_countryCode, _phone.text);
    final language = context.l10n.isArabic ? 'ar' : 'en';
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Retain the same attempt after a transient send error; retries cannot
      // reset the server's cooldown or per-attempt dispatch budget.
      if (_attemptPhone != phone || !_auth.hasPendingRecovery) {
        await _auth.startRecovery(
          widget.email,
          language: language,
          phoneNumber: phone,
        );
        _attemptPhone = phone;
      }
      final resendAt = await _auth.sendRecoveryOtp();
      if (!mounted) return;
      final arguments = AuthRouteArguments(
        role: widget.role,
        phoneNumber: phone,
        isPasswordRecovery: true,
      );
      final result = await Navigator.of(context).push<String>(
        AppRoutes.transition<String>(
          settings: RouteSettings(
            name: AppRoutes.otpVerification,
            arguments: arguments,
          ),
          builder: (_) => OtpVerificationScreen(
            arguments: arguments,
            authService: _auth,
            initialRecoveryResendAt: resendAt,
          ),
        ),
      );
      if (!mounted) return;
      if (result == 'password-recovery-verified') {
        _verified = true;
        Navigator.of(context).pop(phone);
      } else {
        _auth.discardRecovery();
        _attemptPhone = null;
        if (result != null) {
          _error = apiErrorMessage(context.l10n, ApiException(code: result));
        }
      }
    } catch (error) {
      if (!mounted) return;
      if (!_auth.hasPendingRecovery) _attemptPhone = null;
      _error = apiErrorMessage(context.l10n, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Directionality(
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: PopScope<String>(
            canPop: !_busy,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop && !_verified) _auth.discardRecovery();
            },
            child: Scaffold(
              key: const ValueKey('recovery-phone-screen'),
              backgroundColor: context.sanadBg,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      children: [
                        Expanded(
                          child: AbsorbPointer(
                            absorbing: _busy,
                            child: RecoveryPhoneForm(
                              isArabic: context.l10n.isArabic,
                              phone: _phone,
                              countryCode: _countryCode,
                              expectedPhoneLength: _numberLength,
                              onBack: _back,
                              onNext: _submit,
                              onCountryCodeTap: _pickCountry,
                              errorText: _error,
                            ),
                          ),
                        ),
                        if (_busy) const LinearProgressIndicator(),
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
