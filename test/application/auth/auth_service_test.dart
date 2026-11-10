import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import '../../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  setUp(() => f = LaravelAuthFixture());
  tearDown(() => f.close());
  test('incomplete server profile cannot restore authentication', () async {
    await f.tokens.save(
      SanctumToken(
        value: 'test-token',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    f.override = (_) => Future.value(
      f.response('user-retrieved', {
        'user': {...f.user, 'phone_number': null},
      }),
    );
    await expectLater(
      f.auth.restoreCurrentUser(),
      throwsA(isA<ApiException>()),
    );
    expect(f.auth.currentUser, isNull);
    expect(await f.tokens.read(), isNotNull);
  });
  test(
    'unknown role or malformed profile never grants an authenticated session',
    () async {
      await f.tokens.save(
        SanctumToken(
          value: 'test-token',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      for (final profile in [
        {...f.user, 'role': 'admin'},
        <String, dynamic>{},
      ]) {
        f.override = (_) =>
            Future.value(f.response('user-retrieved', {'user': profile}));
        await expectLater(
          f.auth.restoreCurrentUser(),
          throwsA(isA<ApiException>()),
        );
        expect(f.auth.currentUser, isNull);
      }
    },
  );
  test(
    'malformed preparation response never becomes a pending login',
    () async {
      f.override = (_) => Future.value(
        http.Response(
          jsonEncode({
            'code': 'login-prepared',
            'data': {'authenticated': false},
          }),
          200,
        ),
      );
      await expectLater(
        f.auth.startLogin(
          email: 'amina@example.com',
          password: 'ValidPass1!',
          language: 'en',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(await f.tokens.read(), isNull);
      expect(f.auth.login.pendingAttempt, isNull);
    },
  );
  test('an expired saved token cannot fetch protected data', () async {
    f.tokens.value = SanctumToken(
      value: 'expired-token',
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    expect(await f.auth.restoreCurrentUser(), isNull);
    expect(f.requests, isEmpty);
  });
}
