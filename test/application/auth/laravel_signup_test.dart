import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/domain/models/registration_data.dart';
import 'package:sanad/domain/models/user_role.dart';
import '../../support/laravel_auth_fixture.dart';

RegistrationData registration(UserRole role) => RegistrationData(
  username: 'Amina_1',
  firstName: 'Amina',
  lastName: 'Hassan',
  email: 'amina@example.com',
  password: 'ValidPass1!',
  role: role,
  country: 'Egypt',
  region: 'Cairo',
  address: 'Test address',
  phoneNumber: '+201012345678',
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  setUp(() => f = LaravelAuthFixture());
  tearDown(() => f.close());
  test(
    'expired finalization proof retires signup instead of retrying it forever',
    () async {
      await f.auth.startSignup(
        registration(UserRole.patient),
        passwordConfirmation: 'ValidPass1!',
        language: 'en',
      );
      f.failurePath = '/api/auth/register';
      f.failureStatus = 503;
      f.failureCode = 'otp-service-unavailable';
      await expectLater(
        f.auth.verifySignupOtp('123456'),
        throwsA(isA<ApiException>()),
      );
      f.failureStatus = 410;
      f.failureCode = 'otp-expired';
      await expectLater(
        f.auth.verifySignupOtp('123456'),
        throwsA(isA<ApiException>()),
      );
      final before = f.requests.length;
      f.failureStatus = null;
      await expectLater(
        f.auth.verifySignupOtp('123456'),
        throwsA(isA<ApiException>()),
      );
      expect(f.requests.length, before);
    },
  );
  for (final role in UserRole.values) {
    test(
      'signup ${role.name} persists only after proof and finalization',
      () async {
        f.role = role.name;
        await f.auth.startSignup(
          registration(role),
          passwordConfirmation: 'ValidPass1!',
          language: 'ar',
        );
        expect((jsonDecode(f.requests.last.body) as Map)['role'], role.name);
        expect(await f.tokens.read(), isNull);
        await f.auth.sendSignupOtp();
        expect(await f.tokens.read(), isNull);
        final user = await f.auth.verifySignupOtp('123456');
        expect(user.role, role);
        expect(await f.tokens.read(), isNotNull);
        expect(f.requests.map((r) => r.url.path).toList(), [
          '/api/auth/signup/start',
          '/api/auth/otp/send',
          '/api/auth/otp/verify',
          '/api/auth/register',
        ]);
        expect(
          (jsonDecode(f.requests.last.body) as Map)['verification_proof'],
          f.secret,
        );
      },
    );
  }
  test('availability uses Laravel and never reserves a value', () async {
    expect(await f.auth.isEmailAvailable(' AMINA@EXAMPLE.COM '), isTrue);
    expect(await f.auth.isUsernameAvailable(' Amina_1 '), isTrue);
    expect(f.requests.length, 2);
    expect(await f.tokens.read(), isNull);
  });
  test(
    'transient finalize failure retains proof without verifying OTP twice',
    () async {
      await f.auth.startSignup(
        registration(UserRole.patient),
        passwordConfirmation: 'ValidPass1!',
        language: 'en',
      );
      f.failurePath = '/api/auth/register';
      f.failureStatus = 503;
      f.failureCode = 'otp-service-unavailable';
      await expectLater(
        f.auth.verifySignupOtp('123456'),
        throwsA(isA<ApiException>()),
      );
      expect(await f.tokens.read(), isNull);
      f.failureStatus = null;
      await f.auth.verifySignupOtp('123456');
      expect(
        f.requests.where((r) => r.url.path.endsWith('/otp/verify')).length,
        1,
      );
    },
  );
  test('conflict invalidates signup proof and never signs in', () async {
    await f.auth.startSignup(
      registration(UserRole.patient),
      passwordConfirmation: 'ValidPass1!',
      language: 'en',
    );
    f.failurePath = '/api/auth/register';
    f.failureStatus = 422;
    f.failureCode = 'username-taken';
    await expectLater(
      f.auth.verifySignupOtp('123456'),
      throwsA(isA<ApiException>()),
    );
    expect(await f.tokens.read(), isNull);
    f.failureStatus = null;
    await expectLater(
      f.auth.verifySignupOtp('123456'),
      throwsA(isA<ApiException>()),
    );
  });
}
