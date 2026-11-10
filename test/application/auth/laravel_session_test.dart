import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/domain/models/user_role.dart';
import '../../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  setUp(() => f = LaravelAuthFixture());
  tearDown(() => f.close());
  Future<void> saved() => f.tokens.save(
    SanctumToken(
      value: 'existing-token',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    ),
  );
  test('no token never fetches protected profile', () async {
    expect(await f.auth.restoreCurrentUser(), isNull);
    expect(f.requests, isEmpty);
  });
  test('restores server profile and actual role using Bearer', () async {
    await saved();
    final user = await f.auth.restoreCurrentUser();
    expect(user?.role, UserRole.caregiver);
    expect(f.requests.single.headers['Authorization'], 'Bearer existing-token');
    expect(f.auth.currentUser?.uid, '7');
  });
  test('revoked token clears authentication', () async {
    await saved();
    f.failureStatus = 401;
    f.failureCode = 'unauthenticated';
    expect(await f.auth.restoreCurrentUser(), isNull);
    expect(await f.tokens.read(), isNull);
    expect(f.auth.currentUser, isNull);
  });
  test(
    'temporary restore failure retains token without granting access',
    () async {
      await saved();
      f.failureStatus = 503;
      f.failureCode = 'otp-service-unavailable';
      await expectLater(
        f.auth.restoreCurrentUser(),
        throwsA(isA<ApiException>()),
      );
      expect(await f.tokens.read(), isNotNull);
      expect(f.auth.currentUser, isNull);
      f.failureStatus = null;
      expect(await f.auth.restoreCurrentUser(), isNotNull);
    },
  );
  test('logout revokes then clears saved session', () async {
    await saved();
    await f.auth.restoreCurrentUser();
    await f.auth.signOut();
    expect(f.requests.last.url.path, '/api/auth/logout');
    expect(await f.tokens.read(), isNull);
    expect(f.auth.currentUser, isNull);
  });
  test(
    'failed logout preserves existing authenticated session for retry',
    () async {
      await saved();
      await f.auth.restoreCurrentUser();
      f.failurePath = '/api/auth/logout';
      f.failureStatus = 503;
      f.failureCode = 'otp-service-unavailable';
      await expectLater(f.auth.signOut(), throwsA(isA<ApiException>()));
      expect(await f.tokens.read(), isNotNull);
      expect(f.auth.currentUser, isNotNull);
      f.failureStatus = null;
      await f.auth.signOut();
      expect(await f.tokens.read(), isNull);
    },
  );
  test('already revoked logout is safe local cleanup', () async {
    await saved();
    await f.auth.restoreCurrentUser();
    f.failurePath = '/api/auth/logout';
    f.failureStatus = 401;
    f.failureCode = 'unauthenticated';
    await f.auth.signOut();
    expect(await f.tokens.read(), isNull);
    expect(f.auth.currentUser, isNull);
  });
}
