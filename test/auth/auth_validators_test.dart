import 'package:flutter_test/flutter_test.dart';

import 'package:sanad/presentation/auth/validation/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test(
      'rejects empty and whitespace-only names, accepts Unicode punctuation',
      () {
        expect(
          AuthValidators.validateFullName('   '),
          AuthValidationError.required,
        );
        expect(AuthValidators.validateFullName('أحمد بن علي'), isNull);
        expect(AuthValidators.validateFullName("O'Neill-Smith"), isNull);
      },
    );

    test('validates email after trimming surrounding whitespace', () {
      expect(AuthValidators.validateEmail(' user@example.com '), isNull);
      expect(
        AuthValidators.validateEmail('missing-at.example.com'),
        AuthValidationError.invalidEmail,
      );
      expect(AuthValidators.validateEmail(''), AuthValidationError.required);
    });

    test('validates usernames and exposes a canonical lookup key', () {
      expect(AuthValidators.validateUsername('Ab_9.name'), isNull);
      expect(AuthValidators.canonicalUsername('Ab_9.name'), 'ab_9.name');
      expect(
        AuthValidators.validateUsername('abc'),
        AuthValidationError.tooShort,
      );
      expect(
        AuthValidators.validateUsername('a' * 16),
        AuthValidationError.tooLong,
      );
      expect(
        AuthValidators.validateUsername('user name'),
        AuthValidationError.invalidUsername,
      );
      expect(
        AuthValidators.validateUsername('مستخدم'),
        AuthValidationError.invalidUsername,
      );
    });

    test('validates a displayed phone number using its normalized digits', () {
      expect(AuthValidators.validatePhone('+20', '010 1234 5678'), isNull);
      expect(
        AuthValidators.normalizedPhone('+20', '(010) 1234-5678'),
        '+201012345678',
      );
      expect(
        AuthValidators.validatePhone('+20', '123'),
        AuthValidationError.invalidPhone,
      );
    });

    test(
      'handles explicit international prefixes without duplicating them',
      () {
        expect(AuthValidators.validatePhone('+20', '+201012345678'), isNull);
        expect(
          AuthValidators.normalizedPhone('+20', '+201012345678'),
          '+201012345678',
        );
        expect(
          AuthValidators.validatePhone('+20', '12345'),
          AuthValidationError.invalidPhone,
        );
        expect(
          AuthValidators.validatePhone('+20', '01+234567'),
          AuthValidationError.invalidPhone,
        );
      },
    );

    test('requires every password rule', () {
      final validation = PasswordValidation.evaluate('Abcdef12!');

      expect(validation.hasMinimumLength, isTrue);
      expect(validation.hasUppercase, isTrue);
      expect(validation.hasLowercase, isTrue);
      expect(validation.hasDigit, isTrue);
      expect(validation.hasSpecialCharacter, isTrue);
      expect(validation.isValid, isTrue);
      expect(AuthValidators.validatePassword('Abcdef12!'), isNull);
    });

    test('keeps each password rule independently observable', () {
      final validation = PasswordValidation.evaluate('abcdefghi');

      expect(validation.hasMinimumLength, isTrue);
      expect(validation.hasUppercase, isFalse);
      expect(validation.hasLowercase, isTrue);
      expect(validation.hasDigit, isFalse);
      expect(validation.hasSpecialCharacter, isFalse);
      expect(validation.isValid, isFalse);
      expect(
        AuthValidators.validatePassword('abcdefghi'),
        AuthValidationError.invalidPassword,
      );
    });

    test('uses strength as guidance separate from password validity', () {
      expect(
        PasswordValidation.evaluate('abc').strength,
        PasswordStrength.weak,
      );
      expect(
        PasswordValidation.evaluate('Abcdef12').strength,
        PasswordStrength.medium,
      );
      expect(
        PasswordValidation.evaluate('Abcdef12!secure').strength,
        PasswordStrength.strong,
      );
      expect(PasswordValidation.evaluate('Abcdef12!').isValid, isTrue);
    });

    test('requires confirmation to match exactly', () {
      expect(
        AuthValidators.validateConfirmation(
          password: 'Abcdef12!',
          confirmation: '',
        ),
        AuthValidationError.required,
      );
      expect(
        AuthValidators.validateConfirmation(
          password: 'Abcdef12!',
          confirmation: 'Abcdef12',
        ),
        AuthValidationError.passwordMismatch,
      );
      expect(
        AuthValidators.validateConfirmation(
          password: 'Abcdef12!',
          confirmation: 'Abcdef12!',
        ),
        isNull,
      );
    });
  });
}
