import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/application/auth/auth_failure.dart';
import 'package:sanad/data/network/api_exception.dart';

void main() {
  test(
    'preserves backend OTP codes and safely falls back for unknown failures',
    () {
      for (final code in [
        'invalid-code',
        'invalid-challenge',
        'otp-expired',
        'challenge-used',
        'account-changed',
        'profile-incomplete',
        'otp-service-unavailable',
      ]) {
        expect(ApiException.fromResponse(409, {'code': code}).code, code);
      }
      final unknown = ApiException.fromResponse(500, {
        'code': 'private-token',
        'message': 'private-token',
        'exception': 'SQL details',
      });
      expect(unknown.code, 'server-error');
      expect(unknown.toString(), isNot(contains('private-token')));
      expect(ApiException.fromResponse(429, null).code, 'too-many-requests');
    },
  );

  test(
    'maps existing auth categories without changing localized screen contracts',
    () {
      final cases = {
        'email-already-in-use': AuthFailureType.emailAlreadyInUse,
        'invalid-email': AuthFailureType.invalidEmail,
        'weak-password': AuthFailureType.weakPassword,
        'invalid-credentials': AuthFailureType.invalidCredentials,
        'network-request-failed': AuthFailureType.network,
        'request-timeout': AuthFailureType.network,
        'too-many-requests': AuthFailureType.tooManyRequests,
        'otp-expired': AuthFailureType.unknown,
      };
      for (final entry in cases.entries) {
        expect(ApiException(code: entry.key).toAuthFailure().type, entry.value);
      }
    },
  );

  test(
    'field errors are immutable and malformed field entries are ignored',
    () {
      final exception = ApiException.fromResponse(422, {
        'code': 'validation-failed',
        'error_codes': {
          'email': ['invalid-email'],
          'password': 123,
          'other': [true],
        },
        'errors': 'malformed',
      });
      expect(exception.fieldCodes, {
        'email': ['invalid-email'],
      });
      expect(exception.fieldErrors, isEmpty);
      expect(
        () => exception.fieldCodes['email']!.add('changed'),
        throwsUnsupportedError,
      );
      expect(
        () => exception.fieldCodes['password'] = [],
        throwsUnsupportedError,
      );
    },
  );
}
