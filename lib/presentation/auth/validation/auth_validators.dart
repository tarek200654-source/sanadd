import '../../../domain/validation/username_policy.dart';

enum AuthValidationError {
  required,
  tooShort,
  invalidEmail,
  invalidPhone,
  invalidUsername,
  tooLong,
  invalidPassword,
  passwordMismatch,
}

enum PasswordStrength { weak, medium, strong }

enum PasswordRequirement {
  minimumLength,
  uppercase,
  lowercase,
  digit,
  specialCharacter,
}

class PasswordValidation {
  const PasswordValidation({
    required this.hasMinimumLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialCharacter,
  });

  factory PasswordValidation.evaluate(String value) {
    return PasswordValidation(
      hasMinimumLength: value.length >= 9,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(value),
      hasLowercase: RegExp(r'[a-z]').hasMatch(value),
      hasDigit: RegExp(r'[0-9]').hasMatch(value),
      hasSpecialCharacter: _specialCharacterPattern.hasMatch(value),
    );
  }

  static final RegExp _specialCharacterPattern = RegExp(
    r'''[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>/?`~]''',
  );

  final bool hasMinimumLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialCharacter;

  bool get isValid =>
      hasMinimumLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialCharacter;

  int get score => [
    hasMinimumLength,
    hasUppercase,
    hasLowercase,
    hasDigit,
    hasSpecialCharacter,
  ].where((value) => value).length;

  PasswordStrength get strength => switch (score) {
    0 || 1 || 2 => PasswordStrength.weak,
    3 || 4 => PasswordStrength.medium,
    _ => PasswordStrength.strong,
  };

  bool satisfies(PasswordRequirement requirement) => switch (requirement) {
    PasswordRequirement.minimumLength => hasMinimumLength,
    PasswordRequirement.uppercase => hasUppercase,
    PasswordRequirement.lowercase => hasLowercase,
    PasswordRequirement.digit => hasDigit,
    PasswordRequirement.specialCharacter => hasSpecialCharacter,
  };
}

abstract final class AuthValidators {
  static const int maxNameLength = 80;
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static AuthValidationError? validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return AuthValidationError.required;
    if (username.length < UsernamePolicy.minLength) {
      return AuthValidationError.tooShort;
    }
    if (username.length > UsernamePolicy.maxLength) {
      return AuthValidationError.tooLong;
    }
    return UsernamePolicy.isValid(username)
        ? null
        : AuthValidationError.invalidUsername;
  }

  static String canonicalUsername(String username) =>
      UsernamePolicy.canonicalize(username);

  static AuthValidationError? validateFullName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AuthValidationError.required;
    if (trimmed.length > maxNameLength) return AuthValidationError.tooLong;
    return null;
  }

  static AuthValidationError? validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AuthValidationError.required;
    return _emailPattern.hasMatch(trimmed)
        ? null
        : AuthValidationError.invalidEmail;
  }

  static AuthValidationError? validatePhone(
    String countryCode,
    String? displayedNumber,
  ) {
    final displayed = displayedNumber?.trim() ?? '';
    if (displayed.isEmpty) return AuthValidationError.required;

    final plusCount = '+'.allMatches(displayed).length;
    if (plusCount > 1 || (plusCount == 1 && !displayed.startsWith('+'))) {
      return AuthValidationError.invalidPhone;
    }

    final countryDigits = countryCode.replaceAll(RegExp(r'\D'), '');
    final rawDigits = displayed.replaceAll(RegExp(r'\D'), '');
    if (plusCount == 1 && !rawDigits.startsWith(countryDigits)) {
      return AuthValidationError.invalidPhone;
    }

    final nationalDigits = _nationalDigits(
      countryDigits,
      rawDigits,
      hasExplicitCountryPrefix: plusCount == 1,
    );
    if (nationalDigits.length < 7 || nationalDigits.length > 15) {
      return AuthValidationError.invalidPhone;
    }
    return null;
  }

  static String normalizedPhone(String countryCode, String displayedNumber) {
    final countryDigits = countryCode.replaceAll(RegExp(r'\D'), '');
    final displayed = displayedNumber.trim();
    final rawDigits = displayed.replaceAll(RegExp(r'\D'), '');
    final numberDigits = _nationalDigits(
      countryDigits,
      rawDigits,
      hasExplicitCountryPrefix: displayed.startsWith('+'),
    );
    return '+$countryDigits$numberDigits';
  }

  static String _nationalDigits(
    String countryDigits,
    String rawDigits, {
    required bool hasExplicitCountryPrefix,
  }) {
    var nationalDigits =
        hasExplicitCountryPrefix && rawDigits.startsWith(countryDigits)
        ? rawDigits.substring(countryDigits.length)
        : rawDigits;
    if (nationalDigits.startsWith('0')) {
      nationalDigits = nationalDigits.substring(1);
    }
    return nationalDigits;
  }

  static AuthValidationError? validatePassword(String? value) {
    if (value == null || value.isEmpty) return AuthValidationError.required;
    return PasswordValidation.evaluate(value).isValid
        ? null
        : AuthValidationError.invalidPassword;
  }

  static AuthValidationError? validateConfirmation({
    required String? password,
    required String? confirmation,
  }) {
    if (confirmation == null || confirmation.isEmpty) {
      return AuthValidationError.required;
    }
    return password == confirmation
        ? null
        : AuthValidationError.passwordMismatch;
  }
}
