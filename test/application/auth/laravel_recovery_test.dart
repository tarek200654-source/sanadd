import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import '../../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  setUp(() => f = LaravelAuthFixture());
  tearDown(() => f.close());
  test(
    'expired reset proof is discarded and requires a fresh attempt',
    () async {
      await f.auth.startRecovery(
        'amina@example.com',
        language: 'en',
        phoneNumber: '+201012345678',
      );
      await f.auth.verifyRecoveryOtp('123456');
      f.failurePath = '/api/auth/password/reset';
      f.failureStatus = 410;
      f.failureCode = 'otp-expired';
      await expectLater(
        f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!'),
        throwsA(isA<ApiException>()),
      );
      f.failureStatus = null;
      final before = f.requests.length;
      await expectLater(
        f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!'),
        throwsA(isA<ApiException>()),
      );
      expect(f.requests.length, before);
    },
  );
  for (final email in ['amina@example.com']) {
    test('confirmed recovery for $email never authenticates', () async {
      await f.auth.startRecovery(
        email,
        language: 'en',
        phoneNumber: '+201012345678',
      );
      final resend = await f.auth.sendRecoveryOtp();
      expect(resend.isAfter(DateTime.now()), isTrue);
      expect(await f.tokens.read(), isNull);
      await f.auth.verifyRecoveryOtp('123456');
      expect(await f.tokens.read(), isNull);
      await f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!');
      expect(
        (jsonDecode(f.requests.last.body) as Map)['reset_proof'],
        f.secret,
      );
      expect(f.auth.currentUser, isNull);
      expect(await f.tokens.read(), isNull);
    });
  }
  test(
    'eligibility alone creates no attempt and cannot authorize reset',
    () async {
      expect(
        await f.auth.checkRecoveryEligibility(' AMINA@EXAMPLE.COM '),
        isTrue,
      );
      expect(
        await f.auth.checkRecoveryEligibility('unknown@example.com'),
        isFalse,
      );
      expect(f.auth.hasPendingRecovery, isFalse);
      expect(f.auth.hasVerifiedRecovery, isFalse);
      await expectLater(
        f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!'),
        throwsA(isA<ApiException>()),
      );
      expect(
        f.requests.map((r) => r.url.path),
        everyElement('/api/auth/password/eligibility'),
      );
      expect(await f.tokens.read(), isNull);
    },
  );
  test('unknown email cannot create a recovery attempt', () async {
    await expectLater(
      f.auth.startRecovery(
        'unknown@example.com',
        language: 'en',
        phoneNumber: '+201012345678',
      ),
      throwsA(isA<ApiException>()),
    );
    expect(f.auth.hasPendingRecovery, isFalse);
    expect(f.auth.hasVerifiedRecovery, isFalse);
  });
  test(
    'invalid expired and unavailable verification never grants reset proof',
    () async {
      for (final code in [
        'invalid-code',
        'otp-expired',
        'too-many-requests',
        'otp-service-unavailable',
      ]) {
        await f.auth.startRecovery(
          'amina@example.com',
          language: 'ar',
          phoneNumber: '+201012345678',
        );
        f.failureStatus = code == 'otp-expired'
            ? 410
            : code == 'too-many-requests'
            ? 429
            : 422;
        f.failureCode = code;
        await expectLater(
          f.auth.verifyRecoveryOtp('000000'),
          throwsA(isA<ApiException>()),
        );
        f.failureStatus = null;
        await expectLater(
          f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!'),
          throwsA(isA<ApiException>()),
        );
      }
    },
  );
  test(
    'temporary reset failure retains proof; successful reset clears local old token',
    () async {
      await f.tokens.save(
        SanctumToken(
          value: 'old-token',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await f.auth.startRecovery(
        'amina@example.com',
        language: 'en',
        phoneNumber: '+201012345678',
      );
      await f.auth.verifyRecoveryOtp('123456');
      f.failurePath = '/api/auth/password/reset';
      f.failureStatus = 503;
      f.failureCode = 'otp-service-unavailable';
      await expectLater(
        f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!'),
        throwsA(isA<ApiException>()),
      );
      expect(await f.tokens.read(), isNotNull);
      f.failureStatus = null;
      await f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!');
      expect(await f.tokens.read(), isNull);
      await expectLater(
        f.auth.resetPassword('NewStrongPass1!', 'NewStrongPass1!'),
        throwsA(isA<ApiException>()),
      );
    },
  );
}
