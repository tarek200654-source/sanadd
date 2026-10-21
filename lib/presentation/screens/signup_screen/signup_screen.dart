import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/auth/validation/auth_validators.dart';
import '../../../presentation/widgets/auth/auth_header.dart';
import '../../../presentation/widgets/auth/auth_text_field.dart';
import '../../../presentation/widgets/auth/password_requirements.dart';
import '../../../presentation/widgets/sanad_button.dart';
import '../../../utils/routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.arguments});

  static const routeName = '/signup';

  final AuthRouteArguments arguments;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  String _countryCode = '+20';
  bool _termsAccepted = false;
  bool _passwordFocused = false;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _fieldError(
    AppLocalizations l10n,
    AuthValidationError? error, {
    required String field,
  }) {
    return switch (error) {
      null => null,
      AuthValidationError.required => l10n.fieldRequired(field),
      AuthValidationError.invalidEmail => l10n.invalidEmailMessage,
      AuthValidationError.invalidPhone => l10n.invalidPhoneMessage,
      AuthValidationError.tooLong => l10n.nameTooLongMessage,
      AuthValidationError.invalidPassword => l10n.passwordRequirementsMessage,
      AuthValidationError.passwordMismatch => l10n.passwordMismatchMessage,
    };
  }

  void _validateAndContinue() {
    final l10n = context.l10n;
    final nameError = AuthValidators.validateFullName(_nameController.text);
    final phoneError = AuthValidators.validatePhone(
      _countryCode,
      _phoneController.text,
    );
    final emailError = AuthValidators.validateEmail(_emailController.text);
    final passwordError = AuthValidators.validatePassword(
      _passwordController.text,
    );
    final confirmError = AuthValidators.validateConfirmation(
      password: _passwordController.text,
      confirmation: _confirmPasswordController.text,
    );
    final termsError = _termsAccepted ? null : AuthValidationError.required;

    setState(() {
      _nameError = _fieldError(l10n, nameError, field: l10n.fullNameLabel);
      _phoneError = _fieldError(l10n, phoneError, field: l10n.phoneLabel);
      _emailError = _fieldError(l10n, emailError, field: l10n.emailLabel);
      _passwordError = _fieldError(
        l10n,
        passwordError,
        field: l10n.passwordLabel,
      );
      _confirmPasswordError = _fieldError(
        l10n,
        confirmError,
        field: l10n.confirmPasswordLabel,
      );
      _termsError = termsError == null ? null : l10n.termsRequiredMessage;
      _passwordFocused =
          _passwordFocused || _passwordController.text.isNotEmpty;
    });

    if ([
      nameError,
      phoneError,
      emailError,
      passwordError,
      confirmError,
      termsError,
    ].any((error) => error != null)) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: widget.arguments.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: AuthValidators.normalizedPhone(
          _countryCode,
          _phoneController.text,
        ),
      ),
    );
  }

  void _setPasswordFocus(bool hasFocus) {
    if (_passwordFocused == hasFocus) return;
    setState(() => _passwordFocused = hasFocus);
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'name':
          _nameError = null;
        case 'phone':
          _phoneError = null;
        case 'email':
          _emailError = null;
        case 'password':
          _passwordError = null;
        case 'confirm':
          _confirmPasswordError = null;
      }
    });
  }

  void _returnToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.login, arguments: widget.arguments);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final passwordValidation = PasswordValidation.evaluate(
      _passwordController.text,
    );
    final showPasswordRequirements =
        _passwordFocused ||
        (_passwordController.text.isNotEmpty && !passwordValidation.isValid) ||
        _passwordError != null;

    return AuthPageLayout(
      header: AuthHeader(
        title: l10n.signupWelcomeTitle,
        subtitle: l10n.createAccountSubtitle,
        onBack: () => Navigator.maybePop(context),
        topBarTitle: l10n.createAccountTitle,
        trailingIcon: Icons.person_outline_rounded,
        titleFontSize: 24,
        compact: true,
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SanadButton(
            key: const ValueKey('signup-submit'),
            label: l10n.createAccountLabel,
            onPressed: _validateAndContinue,
            fontSize: 15,
            height: 54,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  l10n.alreadyHaveAccountPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: _returnToLogin,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  l10n.signInLabel,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              key: const ValueKey('signup-name-field'),
              controller: _nameController,
              label: l10n.fullNameLabel,
              hintText: l10n.exampleFullName,
              labelAbove: true,
              compact: true,
              errorText: _nameError,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              maxLength: AuthValidators.maxNameLength,
              autofillHints: const [AutofillHints.name],
              suffixIcon: const Icon(
                Icons.badge_outlined,
                size: 20,
                color: AppColor.textSecondary,
              ),
              onChanged: (_) => _clearError('name'),
            ),
            const SizedBox(height: 12),
            _PhoneField(
              countryCode: _countryCode,
              phoneController: _phoneController,
              label: l10n.phoneLabel,
              hintText: l10n.examplePhoneNumber,
              countryCodeLabel: l10n.countryCodeLabel,
              errorText: _phoneError,
              onCountryChanged: (value) => setState(() => _countryCode = value),
              onChanged: (_) => _clearError('phone'),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              key: const ValueKey('signup-email-field'),
              controller: _emailController,
              label: l10n.emailLabel,
              hintText: l10n.exampleEmail,
              labelAbove: true,
              compact: true,
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.email],
              suffixIcon: const Icon(
                Icons.alternate_email_rounded,
                size: 20,
                color: AppColor.textSecondary,
              ),
              onChanged: (_) => _clearError('email'),
            ),
            const SizedBox(height: 12),
            AuthPasswordField(
              key: const ValueKey('signup-password-field'),
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: l10n.passwordLabel,
              labelAbove: true,
              compact: true,
              errorText: _passwordError,
              showPasswordLabel: l10n.showPasswordLabel,
              hidePasswordLabel: l10n.hidePasswordLabel,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) {
                _clearError('password');
                setState(() {});
              },
              onFocusChanged: _setPasswordFocus,
            ),
            PasswordRequirements(
              validation: passwordValidation,
              visible: showPasswordRequirements,
            ),
            const SizedBox(height: 12),
            AuthPasswordField(
              key: const ValueKey('signup-confirm-password-field'),
              controller: _confirmPasswordController,
              label: l10n.confirmPasswordLabel,
              labelAbove: true,
              compact: true,
              errorText: _confirmPasswordError,
              showPasswordLabel: l10n.showPasswordLabel,
              hidePasswordLabel: l10n.hidePasswordLabel,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => _clearError('confirm'),
            ),
            const SizedBox(height: 8),
            _Reassurance(text: l10n.privacyReassurance),
            const SizedBox(height: 6),
            _TermsField(
              key: const ValueKey('signup-terms-field'),
              accepted: _termsAccepted,
              label: l10n.termsAcknowledgement,
              errorText: _termsError,
              onChanged: (value) => setState(() {
                _termsAccepted = value;
                if (value) _termsError = null;
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.countryCode,
    required this.phoneController,
    required this.label,
    required this.hintText,
    required this.countryCodeLabel,
    required this.errorText,
    required this.onCountryChanged,
    required this.onChanged,
  });

  final String countryCode;
  final TextEditingController phoneController;
  final String label;
  final String hintText;
  final String countryCodeLabel;
  final String? errorText;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onChanged;

  static const _countryCodes = ['+20', '+966', '+971', '+1', '+44'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: AppColor.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 54,
              child: Semantics(
                label: countryCodeLabel,
                child: Container(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 3),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: countryCode,
                      isDense: true,
                      isExpanded: true,
                      iconSize: 18,
                      onChanged: (value) {
                        if (value != null) onCountryChanged(value);
                      },
                      items: _countryCodes
                          .map(
                            (code) => DropdownMenuItem<String>(
                              value: code,
                              child: Text(
                                code,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: AppColor.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                label: label,
                textField: true,
                child: SizedBox(
                  height: 54,
                  child: AuthTextField(
                    key: const ValueKey('signup-phone-field'),
                    controller: phoneController,
                    label: '',
                    hintText: hintText,
                    compact: true,
                    errorText: null,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 +()\-]')),
                    ],
                    onChanged: onChanged,
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColor.alert, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}

class _TermsField extends StatelessWidget {
  const _TermsField({
    super.key,
    required this.accepted,
    required this.label,
    required this.errorText,
    required this.onChanged,
  });

  final bool accepted;
  final String label;
  final String? errorText;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: accepted,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onChanged(!accepted),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: const ValueKey('signup-terms-checkbox'),
                  value: accepted,
                  onChanged: (value) => onChanged(value ?? false),
                  activeColor: AppColor.primary,
                  visualDensity: VisualDensity.standard,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      label,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, top: 2),
              child: Text(
                errorText!,
                style: const TextStyle(color: AppColor.alert, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _Reassurance extends StatelessWidget {
  const _Reassurance({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColor.border.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColor.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 19,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColor.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
