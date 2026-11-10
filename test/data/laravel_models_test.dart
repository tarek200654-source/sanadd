import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/data/mappers/laravel_user_mapper.dart';
import 'package:sanad/data/mappers/laravel_registration_mapper.dart';
import 'package:sanad/data/models/auth_session.dart';
import 'package:sanad/domain/models/otp_attempt.dart';
import 'package:sanad/domain/models/otp_proof.dart';
import 'package:sanad/domain/models/registration_data.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/domain/models/user_role.dart';

Map<String, dynamic> profile() => {
  'id': '7',
  'name': 'Amina Hassan',
  'email': 'amina@example.com',
  'username': 'Amina_1',
  'first_name': 'Amina',
  'last_name': 'Hassan',
  'role': 'caregiver',
  'phone_number': '+201012345678',
  'country': 'Egypt',
  'region': 'Cairo',
  'address': 'Test',
  'created_at': '2026-11-07T13:00:00.000000Z',
};

void main() {
  test(
    'maps Laravel profile into existing AppUser and back without Firebase names',
    () {
      final user = LaravelUserMapper.fromJson(profile());
      expect(user.uid, '7');
      expect(user.role, UserRole.caregiver);
      expect(user.firstName, 'Amina');
      expect(user.phoneNumber, '+201012345678');
      expect(user.createdAt, DateTime.utc(2026, 11, 7, 13));
      expect(user.hasCompleteRegistrationProfile, isTrue);
      expect(LaravelUserMapper.toJson(user)['first_name'], 'Amina');
      expect(LaravelUserMapper.toJson(user).containsKey('uid'), isFalse);
    },
  );
  test(
    'retains nullable legacy profile fields but rejects invalid identity and role',
    () {
      expect(
        LaravelUserMapper.fromJson({
          ...profile(),
          'phone_number': null,
        }).phoneNumber,
        isNull,
      );
      for (final change in [
        {'id': 7},
        {'role': 'admin'},
        {'email': ''},
        {'created_at': 'not-a-date'},
        {'first_name': 2},
      ]) {
        expect(
          () => LaravelUserMapper.fromJson({...profile(), ...change}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'token expiry accepts explicit zones, rejects missing zones and redacts value',
    () {
      final token = SanctumToken.fromJson({
        'token': '1|test-token',
        'token_type': 'Bearer',
        'expires_at': '2026-11-07T15:00:00+02:00',
      });
      expect(token.expiresAt, DateTime.utc(2026, 11, 7, 13));
      expect(token.isExpired(DateTime.utc(2026, 11, 7, 13)), isTrue);
      expect(token.toString(), isNot(contains('test-token')));
      for (final fields in [
        {'expires_at': '2026-11-07 13:00:00'},
        {'token': 'bad\r\nheader'},
        {'token_type': 'Basic'},
      ]) {
        expect(
          () => SanctumToken.fromJson({
            'token': 'test-token',
            'token_type': 'Bearer',
            'expires_at': '2026-11-07T13:00:00Z',
            ...fields,
          }),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'authenticated response requires user, token and authenticated true',
    () {
      final data = {
        'authenticated': true,
        'user': profile(),
        'token': 'test-token',
        'token_type': 'Bearer',
        'expires_at': '2026-11-14T13:00:00Z',
      };
      expect(AuthSession.fromJson(data).user.uid, '7');
      expect(
        AuthSession.fromJson(data).toString(),
        isNot(contains('test-token')),
      );
      expect(
        () => AuthSession.fromJson({...data, 'authenticated': false}),
        throwsFormatException,
      );
      expect(
        () => AuthSession.fromJson({
          'authenticated': false,
          'otp_required': true,
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'OTP attempts cover signup, login and neutral recovery without creating sessions',
    () {
      for (final purpose in ['signup', 'login', 'password_reset']) {
        final data = {
          'attempt_id': '79e6b581-b223-4c55-b180-878f6dbc159a',
          'attempt_token': List.filled(64, 'a').join(),
          'purpose': purpose,
          'expires_at': '2026-11-07T13:10:00Z',
          'authenticated': false,
        };
        final attempt = OtpAttempt.fromJson(data);
        expect(attempt.purpose.value, purpose);
        expect(attempt.toString(), isNot(contains(data['attempt_token'])));
        expect(
          () => OtpAttempt.fromJson({...data, 'authenticated': true}),
          throwsFormatException,
        );
        expect(
          () => OtpAttempt.fromJson({...data, 'purpose': 'admin'}),
          throwsFormatException,
        );
      }
    },
  );
  test('signup and reset proofs remain distinct and non-authenticated', () {
    final data = {
      'authenticated': false,
      'expires_at': '2026-11-07T13:05:00Z',
      'reset_proof': List.filled(64, 'a').join(),
    };
    expect(
      OtpProof.fromJson(data, purpose: OtpPurpose.passwordReset).purpose,
      OtpPurpose.passwordReset,
    );
    expect(
      () => OtpProof.fromJson(data, purpose: OtpPurpose.signup),
      throwsFormatException,
    );
    expect(
      () => OtpProof.fromJson(data, purpose: OtpPurpose.login),
      throwsFormatException,
    );
  });
  test(
    'serializes registration snake_case while preserving password bytes and selected role',
    () {
      const registration = RegistrationData(
        username: ' Amina_1 ',
        firstName: ' Amina ',
        lastName: ' Hassan ',
        email: ' AMINA@EXAMPLE.COM ',
        password: '  ValidPass1!  ',
        role: UserRole.patient,
        country: ' Egypt ',
        region: ' Cairo ',
        address: ' Test ',
        phoneNumber: ' +201012345678 ',
      );
      final body = LaravelRegistrationMapper.toJson(
        registration,
        passwordConfirmation: '  ValidPass1!  ',
      );
      expect(body['password'], registration.password);
      expect(body['password_confirmation'], registration.password);
      expect(body['role'], 'patient');
      expect(body['email'], 'amina@example.com');
      expect(body['first_name'], 'Amina');
    },
  );
}
