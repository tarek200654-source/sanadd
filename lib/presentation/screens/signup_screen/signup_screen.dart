import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../application/auth/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../domain/models/registration_data.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/auth/validation/auth_validators.dart';
import '../../../presentation/widgets/shared_widgets/auth_screen_styles.dart';
import '../../../presentation/widgets/signup_screen_widgets/signup_picker.dart';
import '../../../presentation/widgets/signup_screen_widgets/signup_steps_form.dart';
import '../../../utils/routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.arguments, this.authService});

  static const routeName = '/signup';

  final AuthRouteArguments arguments;
  final AuthService? authService;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  bool _isArabic = false;
  bool _localeInitialized = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  bool _hasMinimumLength = false;
  bool _passwordsMatch = false;
  bool _usernameError = false;
  bool _emailError = false;
  bool _checkingUsername = false;
  bool? _usernameTaken;
  bool? _emailInvalid;
  String? _usernameHint;
  String? _emailHint;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  String _country = AppConstants.defaultCountryName;
  String _countryCode = AppConstants.defaultCountryCallingCode;
  int _nationalNumberLength = AppConstants.defaultNationalNumberLength;
  String? _governorate;

  Timer? _usernameDebounce;
  Timer? _emailDebounce;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.8, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
    _firstName.addListener(_refreshForm);
    _lastName.addListener(_refreshForm);
    _phone.addListener(_refreshForm);
    _address.addListener(_refreshForm);
    _password.addListener(_validatePassword);
    _confirmation.addListener(_validatePassword);
    _username.addListener(_onUsernameChanged);
    _email.addListener(_onEmailChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localeInitialized) return;
    _isArabic = context.l10n.isArabic;
    _localeInitialized = true;
  }

  void _validatePassword() {
    final password = _password.text;
    final validation = PasswordValidation.evaluate(password);
    setState(() {
      _hasMinimumLength = validation.hasMinimumLength;
      _hasUppercase = validation.hasUppercase;
      _hasNumber = validation.hasDigit;
      _hasSpecial = validation.hasSpecialCharacter;
      _passwordsMatch = password.isNotEmpty && password == _confirmation.text;
    });
  }

  void _refreshForm() {
    if (mounted) setState(() {});
  }

  void _onUsernameChanged() {
    final value = _username.text.trim();
    _usernameDebounce?.cancel();
    final validation = AuthValidators.validateUsername(value);
    setState(() {
      _usernameTaken = null;
      _usernameHint = null;
      _checkingUsername = validation == null;
      _usernameError = false;
    });
    if (validation != null) {
      if (value.isNotEmpty) {
        setState(() {
          _checkingUsername = false;
          _usernameError = true;
          _usernameHint = switch (validation) {
            AuthValidationError.tooShort =>
              _isArabic ? '4 أحرف على الأقل' : 'At least 4 characters',
            AuthValidationError.tooLong =>
              _isArabic ? '15 حرفًا كحد أقصى' : 'Up to 15 characters',
            AuthValidationError.invalidUsername =>
              _isArabic
                  ? 'استخدم الإنجليزية والأرقام و . و _ فقط'
                  : 'Use English letters, numbers, . and _ only',
            _ => null,
          };
        });
      }
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted || _username.text.trim() != value) return;
      try {
        final available = await (widget.authService ?? AuthService.firebase())
            .isUsernameAvailable(value);
        if (!mounted || _username.text.trim() != value) return;
        setState(() {
          _checkingUsername = false;
          _usernameTaken = !available;
          _usernameError = !available;
          _usernameHint = available
              ? (_isArabic ? 'اسم المستخدم متاح' : 'Username is available')
              : (_isArabic ? 'اسم المستخدم مستخدم' : 'Username is taken');
        });
      } catch (error) {
        if (!mounted || _username.text.trim() != value) return;
        final diagnostic = error is UserRepositoryException
            ? '${error.code}: ${error.cause ?? error}'
            : error;
        debugPrint('Username availability check failed: $diagnostic');
        setState(() {
          _checkingUsername = false;
          _usernameError = true;
          _usernameHint = _isArabic
              ? 'تعذر التحقق الآن'
              : 'Could not check availability';
        });
      }
    });
  }

  void _onEmailChanged() {
    final value = _email.text.trim();
    _emailDebounce?.cancel();
    setState(() {
      _emailInvalid = null;
      _emailHint = null;
      _emailError = false;
    });
    if (AuthValidators.validateEmail(value) != null) {
      return;
    }
    _emailDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _email.text.trim() != value) return;
      setState(() {
        _emailInvalid = false;
        _emailHint = _isArabic ? 'صالح للمعاينة' : 'Valid for preview';
      });
    });
  }

  void _showGovernoratePicker() {
    final governorates = _isArabic
        ? AppConstants.governoratesArByCountry[_country]
        : AppConstants.governoratesEnByCountry[_country];
    if (governorates == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.transparent,
      isScrollControlled: true,
      builder: (_) => SignupPicker(
        title: _isArabic ? 'اختر المنطقة' : 'Select Area',
        items: governorates,
        isArabic: _isArabic,
        onSelected: (value) => setState(() => _governorate = value),
      ),
    );
  }

  void _showCountryPicker() {
    final countries = AppConstants.countries.entries
        .map((entry) => '${entry.value.flag} ${entry.key}')
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.transparent,
      isScrollControlled: true,
      builder: (_) => SignupPicker(
        title: _isArabic ? 'اختر الدولة' : 'Select Country',
        items: countries,
        isArabic: _isArabic,
        onSelected: (value) {
          final name = value.split(' ').skip(1).join(' ');
          final country = AppConstants.countries[name]!;
          setState(() {
            _country = name;
            _countryCode = country.callingCode;
            _nationalNumberLength = country.nationalNumberLength;
            _phone.clear();
            _governorate = null;
          });
        },
      ),
    );
  }

  void _showCountryCodePicker() {
    final codes = AppConstants.countries.values
        .map((country) => '${country.flag} ${country.callingCode}')
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColor.transparent,
      isScrollControlled: true,
      builder: (_) => SignupPicker(
        title: _isArabic ? 'كود الدولة' : 'Country Code',
        items: codes,
        isArabic: _isArabic,
        onSelected: (value) {
          final code = value.split(' ')[1];
          final entry = AppConstants.countries.entries.firstWhere(
            (entry) => entry.value.callingCode == code,
          );
          setState(() {
            _countryCode = code;
            _country = entry.key;
            _nationalNumberLength = entry.value.nationalNumberLength;
            _phone.clear();
          });
        },
      ),
    );
  }

  void _nextStep() {
    if (_step < 6) {
      FocusScope.of(context).unfocus();
      setState(() => _step++);
      return;
    }
    _submitRegistration();
  }

  void _previousStep() {
    if (_step > 0) {
      FocusScope.of(context).unfocus();
      setState(() => _step--);
      return;
    }
    _returnToLogin();
  }

  void _submitRegistration() {
    final registration = RegistrationData(
      username: _username.text.trim(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: widget.arguments.role,
      country: _country,
      region: _governorate!,
      address: _address.text.trim(),
      phoneNumber: AuthValidators.normalizedPhone(_countryCode, _phone.text),
    );
    Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: widget.arguments.copyWith(
        email: registration.email,
        name: registration.fullName,
        password: registration.password,
        phoneNumber: registration.phoneNumber,
        registrationData: registration,
      ),
    );
  }

  void _returnToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.login, arguments: widget.arguments);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirmation.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: PopScope<void>(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) _previousStep();
            },
            child: Scaffold(
              backgroundColor: context.sanadBg,
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            child: SignupStepsForm(
                              regStep: _step,
                              isArabic: _isArabic,
                              first: _firstName,
                              last: _lastName,
                              username: _username,
                              email: _email,
                              phone: _phone,
                              address: _address,
                              password: _password,
                              confirm: _confirmation,
                              selectedGov: _governorate,
                              selectedCountry: _country,
                              selectedCountryCode: _countryCode,
                              expectedPhoneLength: _nationalNumberLength,
                              onStepNext: _nextStep,
                              onStepBack: _previousStep,
                              onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onToggleConfirm: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              onGovTap: _showGovernoratePicker,
                              onCountryTap: _showCountryPicker,
                              onCountryCodeTap: _showCountryCodePicker,
                              usernameError: _usernameError,
                              emailError: _emailError,
                              usernameChecking: _checkingUsername,
                              usernameHint: _usernameHint,
                              emailHint: _emailHint,
                              usernameTaken: _usernameTaken,
                              emailInvalid: _emailInvalid,
                              obscure: _obscurePassword,
                              obscureConfirm: _obscureConfirmation,
                              hasUpper: _hasUppercase,
                              hasNum: _hasNumber,
                              hasSpec: _hasSpecial,
                              hasMinLen: _hasMinimumLength,
                              passMatch: _passwordsMatch,
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
        ),
      ),
    );
  }
}
