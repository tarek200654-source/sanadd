import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sanad/application/auth/laravel_login_service.dart';
import 'package:sanad/data/network/api_client.dart';
import 'package:sanad/data/network/api_config.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/data/storage/secure_token_store.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/domain/repositories/token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 11, 7, 13);
  const id = '79e6b581-b223-4c55-b180-878f6dbc159a';
  final attemptSecret = List.filled(64, 'a').join();
  late SecureTokenStore tokens;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) handler;
  late LaravelLoginService login;
  late ApiClient api;

  Map<String, dynamic> attempt() => {
    'attempt_id': id,
    'attempt_token': attemptSecret,
    'purpose': 'login',
    'otp_started': false,
    'authenticated': false,
    'expires_at': now.add(const Duration(minutes: 10)).toIso8601String(),
  };
  Map<String, dynamic> dispatch() => {
    'attempt_id': id,
    'otp_started': true,
    'authenticated': false,
    'expires_at': now.add(const Duration(minutes: 5)).toIso8601String(),
    'resend_at': now.add(const Duration(minutes: 1)).toIso8601String(),
  };
  Map<String, dynamic> session() => {
    'authenticated': true,
    'token': '1|server-test-token',
    'token_type': 'Bearer',
    'expires_at': now.add(const Duration(days: 7)).toIso8601String(),
    'user': {
      'id': '7',
      'name': 'Amina Hassan',
      'email': 'amina@example.com',
      'role': 'patient',
      'username': 'Amina_1',
      'first_name': 'Amina',
      'last_name': 'Hassan',
      'phone_number': '+201012345678',
      'country': 'Egypt',
      'region': 'Cairo',
      'address': 'Test',
      'created_at': now.toIso8601String(),
    },
  };
  http.Response success(
    String code,
    Map<String, dynamic> data, [
    int status = 200,
  ]) => http.Response(jsonEncode({'code': code, 'data': data}), status);
  http.Response error(String code, int status) =>
      http.Response(jsonEncode({'code': code}), status);
  Future<void> begin() => login.start(
    email: ' AMINA@EXAMPLE.COM ',
    password: ' ValidPass1! ',
    language: 'ar',
  );
  Future<void> existingSession() => tokens.save(
    SanctumToken(
      value: 'existing-session',
      expiresAt: now.add(const Duration(days: 1)),
    ),
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    tokens = SecureTokenStore(now: () => now);
    requests = [];
    handler = (request) async => switch (request.url.path) {
      '/api/auth/login/start' => success('login-started', attempt(), 201),
      '/api/auth/otp/send' => success('otp-sent', dispatch(), 202),
      '/api/auth/otp/verify' => success('authenticated', session()),
      _ => throw StateError('Unexpected endpoint in mocked login test'),
    };
    api = ApiClient(
      config: ApiConfig(
        baseUrl: 'http://127.0.0.1:8000',
        timeout: const Duration(milliseconds: 80),
      ),
      tokenStore: tokens,
      httpClient: MockClient((request) {
        requests.add(request);
        return handler(request);
      }),
      now: () => now,
    );
    login = LaravelLoginService(api: api, tokenStore: tokens, now: () => now);
  });
  tearDown(() => api.close());

  test(
    'starts login without persisting credentials or authenticating',
    () async {
      await begin();
      expect(jsonDecode(requests.single.body), {
        'email': 'amina@example.com',
        'password': ' ValidPass1! ',
        'language': 'ar',
      });
      expect(login.pendingAttempt?.id, id);
      expect(login.pendingAttempt.toString(), isNot(contains(attemptSecret)));
      expect(await tokens.read(), isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      expect(requests.single.headers['Authorization'], isNull);
    },
  );

  test(
    'sends and resends only the server-owned attempt, retaining timing',
    () async {
      await begin();
      final delivery = await login.sendOtp();
      expect(jsonDecode(requests.last.body), {
        'attempt_id': id,
        'attempt_token': attemptSecret,
      });
      expect(delivery.attemptId, id);
      expect(delivery.expiresAt, now.add(const Duration(minutes: 5)));
      expect(delivery.resendAt, now.add(const Duration(minutes: 1)));
      expect(await tokens.read(), isNull);
      await login.sendOtp();
      expect(requests.length, 3);
    },
  );

  test(
    'accepts server OTP success, securely stores token then returns AppUser',
    () async {
      await begin();
      await login.sendOtp();
      final user = await login.verifyOtp('123456');
      expect(user.uid, '7');
      expect(user.role, UserRole.patient);
      expect(jsonDecode(requests.last.body), {
        'attempt_id': id,
        'attempt_token': attemptSecret,
        'purpose': 'login',
        'code': '123456',
      });
      expect((await tokens.read())?.value, '1|server-test-token');
      expect(
        (await tokens.read())?.expiresAt,
        now.add(const Duration(days: 7)),
      );
      expect(login.pendingAttempt, isNull);
      expect(
        requests.every(
          (r) =>
              r.headers['Authorization'] == null && r.url.host == '127.0.0.1',
        ),
        isTrue,
      );
      final saved =
          (await const FlutterSecureStorage().readAll()).values.single;
      expect(saved, isNot(contains(attemptSecret)));
      expect(saved, isNot(contains('ValidPass1!')));
      await expectLater(
        login.verifyOtp('123456'),
        throwsA(isA<ApiException>()),
      );
      expect(requests.length, 3);
    },
  );

  test(
    'stored token supports existing authenticated GET user client',
    () async {
      await begin();
      await login.verifyOtp('123456');
      handler = (request) async {
        expect(request.url.path, '/api/user');
        expect(request.headers['Authorization'], 'Bearer 1|server-test-token');
        return success('user-retrieved', {'user': session()['user']});
      };
      expect(
        (await api.get('/api/user', authenticated: true))?['code'],
        'user-retrieved',
      );
    },
  );

  test(
    'incorrect password leaves existing session intact and no pending login',
    () async {
      await existingSession();
      handler = (_) async => error('invalid-credentials', 401);
      await expectLater(
        begin(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'invalid-credentials',
          ),
        ),
      );
      expect(login.pendingAttempt, isNull);
      expect((await tokens.read())?.value, 'existing-session');
    },
  );

  test('invalid OTP can be retried without premature token storage', () async {
    await begin();
    handler = (_) async => error('invalid-code', 422);
    await expectLater(
      login.verifyOtp('000000'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'invalid-code'),
      ),
    );
    expect(login.pendingAttempt, isNotNull);
    expect(await tokens.read(), isNull);
    handler = (_) async => success('authenticated', session());
    expect((await login.verifyOtp('123456')).uid, '7');
  });

  test(
    'expiry rate limiting and provider failures preserve backend codes and session',
    () async {
      await existingSession();
      for (final failure in {
        'otp-expired': 410,
        'too-many-requests': 429,
        'otp-service-unavailable': 503,
      }.entries) {
        await begin();
        handler = (_) async => error(failure.key, failure.value);
        await expectLater(
          login.verifyOtp('123456'),
          throwsA(
            isA<ApiException>().having((e) => e.code, 'code', failure.key),
          ),
        );
        expect((await tokens.read())?.value, 'existing-session');
        handler = (_) async => success('login-started', attempt(), 201);
      }
    },
  );

  test(
    'send failure remains retryable without losing pending credentials',
    () async {
      await begin();
      handler = (_) async => error('otp-service-unavailable', 503);
      await expectLater(
        login.sendOtp(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'otp-service-unavailable',
          ),
        ),
      );
      expect(login.pendingAttempt?.id, id);
      expect(await tokens.read(), isNull);
      handler = (_) async => success('otp-sent', dispatch(), 202);
      expect((await login.sendOtp()).attemptId, id);
    },
  );

  test(
    'network errors and timeouts do not clear an existing session',
    () async {
      await existingSession();
      await begin();
      handler = (_) async =>
          throw http.ClientException('Simulated network error');
      await expectLater(
        login.sendOtp(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'network-request-failed',
          ),
        ),
      );
      handler = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        return success('authenticated', session());
      };
      await expectLater(
        login.verifyOtp('123456'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'request-timeout'),
        ),
      );
      expect((await tokens.read())?.value, 'existing-session');
      expect(login.pendingAttempt?.id, id);
    },
  );

  test(
    'malformed or cross-purpose start responses cannot become pending login',
    () async {
      for (final data in [
        <String, dynamic>{},
        {...attempt(), 'purpose': 'signup'},
        {...attempt(), 'authenticated': true},
        {...attempt(), 'otp_started': true},
      ]) {
        handler = (_) async => success('login-started', data, 201);
        await expectLater(
          begin(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.code,
              'code',
              'invalid-response',
            ),
          ),
        );
        expect(login.pendingAttempt, isNull);
        expect(await tokens.read(), isNull);
      }
      handler = (_) async => http.Response('', 204);
      await expectLater(
        begin(),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'invalid-response'),
        ),
      );
    },
  );

  test(
    'send rejects wrong attempt and malformed send acknowledgements',
    () async {
      await begin();
      for (final data in [
        {...dispatch(), 'attempt_id': 'other'},
        {...dispatch(), 'authenticated': true},
        {...dispatch(), 'resend_at': null},
      ]) {
        handler = (_) async => success('otp-sent', data, 202);
        await expectLater(
          login.sendOtp(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.code,
              'code',
              'invalid-response',
            ),
          ),
        );
        expect(await tokens.read(), isNull);
      }
    },
  );

  test(
    'unconfirmed malformed incomplete or expired authenticated results never save tokens',
    () async {
      await existingSession();
      for (final data in [
        <String, dynamic>{},
        {...session(), 'authenticated': false},
        {...session(), 'token': null},
        {...session(), 'expires_at': now.toIso8601String()},
        {
          ...session(),
          'user': {...session()['user'] as Map, 'phone_number': null},
        },
      ]) {
        handler = (_) async => success('login-started', attempt(), 201);
        await begin();
        handler = (_) async => success('authenticated', data);
        await expectLater(
          login.verifyOtp('123456'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.code,
              'code',
              'invalid-response',
            ),
          ),
        );
        expect((await tokens.read())?.value, 'existing-session');
      }
    },
  );

  test(
    'preparation or signup proof cannot replace server login success',
    () async {
      await begin();
      handler = (_) async => success('signup-verified', {
        'authenticated': false,
        'verification_proof': attemptSecret,
      });
      await expectLater(
        login.verifyOtp('123456'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'invalid-response'),
        ),
      );
      expect(await tokens.read(), isNull);
    },
  );

  test(
    'duplicate verification and overlapping start/send are rejected before HTTP',
    () async {
      await begin();
      handler = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return success('authenticated', session());
      };
      final first = login.verifyOtp('123456');
      await expectLater(
        login.verifyOtp('123456'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'auth-operation-in-progress',
          ),
        ),
      );
      await expectLater(begin(), throwsA(isA<ApiException>()));
      await expectLater(login.sendOtp(), throwsA(isA<ApiException>()));
      expect((await first).uid, '7');
      expect(requests.length, 2);
    },
  );

  test(
    'discarding pending login does not log out or erase a valid stored token',
    () async {
      await existingSession();
      await begin();
      login.discardPendingAttempt();
      expect(login.pendingAttempt, isNull);
      await expectLater(
        login.sendOtp(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'invalid-challenge',
          ),
        ),
      );
      expect((await tokens.read())?.value, 'existing-session');
      expect(requests.length, 1);
    },
  );

  test(
    'terminal server errors retire pending state and release the busy guard',
    () async {
      for (final code in [
        'invalid-challenge',
        'challenge-used',
        'account-changed',
      ]) {
        handler = (_) async => success('login-started', attempt(), 201);
        await begin();
        handler = (_) async =>
            error(code, code == 'invalid-challenge' ? 404 : 409);
        await expectLater(
          login.verifyOtp('123456'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', code)),
        );
        expect(login.pendingAttempt, isNull);
        expect(login.isBusy, isFalse);
        expect(await tokens.read(), isNull);
      }
    },
  );

  test('failed replacement login cannot keep an old pending account', () async {
    await begin();
    handler = (_) async => error('invalid-credentials', 401);
    await expectLater(
      login.start(email: 'other@example.com', password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
    expect(login.pendingAttempt, isNull);
    expect(login.isBusy, isFalse);
  });

  test(
    'malformed verification JSON retires a potentially consumed challenge',
    () async {
      await begin();
      handler = (_) async =>
          http.Response('<html>Unexpected response</html>', 200);
      await expectLater(
        login.verifyOtp('123456'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'invalid-response'),
        ),
      );
      expect(login.pendingAttempt, isNull);
      expect(await tokens.read(), isNull);
    },
  );

  test(
    'storage failure never returns an authenticated user or repeats consumed OTP',
    () async {
      login = LaravelLoginService(
        api: api,
        tokenStore: FailingTokens(),
        now: () => now,
      );
      await begin();
      await expectLater(
        login.verifyOtp('123456'),
        throwsA(isA<TokenStorageException>()),
      );
      expect(login.pendingAttempt, isNull);
      await expectLater(
        login.verifyOtp('123456'),
        throwsA(isA<ApiException>()),
      );
      expect(requests.length, 2);
    },
  );
}

class FailingTokens implements TokenStore {
  @override
  Future<SanctumToken?> read() async => null;
  @override
  Future<void> save(SanctumToken token) async =>
      throw const TokenStorageException();
  @override
  Future<void> clear() async => throw StateError('Must not clear tokens');
  @override
  Future<void> clearIfMatches(SanctumToken expected) async =>
      throw StateError('Must not clear tokens');
}
