import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sanad/data/network/api_client.dart';
import 'package:sanad/data/network/api_config.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/domain/repositories/token_store.dart';

class MemoryTokens implements TokenStore {
  SanctumToken? token;
  int clears = 0;

  @override
  Future<SanctumToken?> read() async => token;
  @override
  Future<void> save(SanctumToken token) async {
    this.token = token;
  }

  @override
  Future<void> clear() async {
    token = null;
    clears++;
  }

  @override
  Future<void> clearIfMatches(SanctumToken expected) async {
    if (token?.value == expected.value) {
      await clear();
    }
  }
}

void main() {
  late MemoryTokens tokens;
  final now = DateTime.utc(2026, 11, 7);
  SanctumToken token(String value) =>
      SanctumToken(value: value, expiresAt: now.add(const Duration(days: 1)));
  ApiClient client(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 20),
  }) {
    final result = ApiClient(
      config: ApiConfig(baseUrl: 'http://127.0.0.1:8000', timeout: timeout),
      tokenStore: tokens,
      httpClient: MockClient(handler),
      now: () => now,
    );
    addTearDown(result.close);
    return result;
  }

  setUp(() {
    tokens = MemoryTokens();
  });

  test(
    'serializes Unicode JSON and parses the actual response envelope',
    () async {
      final api = client((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://127.0.0.1:8000/api/auth/availability/email',
        );
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.followRedirects, isFalse);
        expect(jsonDecode(request.body), {'email': 'أمينة@example.com'});
        return http.Response(
          jsonEncode({
            'code': 'availability-checked',
            'data': {'available': true},
          }),
          200,
        );
      });
      final response = await api.post(
        '/api/auth/availability/email',
        body: {'email': 'أمينة@example.com'},
      );
      expect(response?['data'], {'available': true});
    },
  );

  test('attaches Bearer only when explicitly authenticated', () async {
    tokens.token = token('1|test-token');
    var calls = 0;
    final api = client((request) async {
      expect(
        request.headers['Authorization'],
        calls++ == 0 ? null : 'Bearer 1|test-token',
      );
      return http.Response('{}', 200);
    });
    await api.post(
      '/api/auth/login/start',
      body: {'email': 'test@example.com', 'password': 'test'},
    );
    await api.get('/api/user', authenticated: true);
  });

  test('authenticated 401 invalidates the rejected token', () async {
    tokens.token = token('1|test-token');
    final api = client(
      (_) async => http.Response(
        '{"code":"unauthenticated","message":"Authentication is required."}',
        401,
      ),
    );
    await expectLater(
      api.get('/api/user', authenticated: true),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'unauthenticated'),
      ),
    );
    expect(tokens.token, isNull);
    expect(tokens.clears, 1);
  });

  test(
    'non-JSON proxy 401 still invalidates only the attached token',
    () async {
      tokens.token = token('test-token');
      final api = client(
        (_) async => http.Response('<html>Unauthorized</html>', 401),
      );
      await expectLater(
        api.get('/api/user', authenticated: true),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'unauthenticated'),
        ),
      );
      expect(tokens.token, isNull);
    },
  );

  test('late 401 cannot erase a newly saved token', () async {
    tokens.token = token('old-token');
    final api = client((_) async {
      await tokens.save(token('new-token'));
      return http.Response('{}', 401);
    });
    await expectLater(
      api.get('/api/user', authenticated: true),
      throwsA(isA<ApiException>()),
    );
    expect(tokens.token?.value, 'new-token');
  });

  test(
    'public invalid credentials never deletes an existing session',
    () async {
      tokens.token = token('existing-token');
      final api = client(
        (_) async => http.Response('{"code":"invalid-credentials"}', 401),
      );
      await expectLater(
        api.post('/api/auth/login/start', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'invalid-credentials',
          ),
        ),
      );
      expect(tokens.clears, 0);
    },
  );

  test(
    'missing or expired credentials prevent authenticated HTTP requests',
    () async {
      var calls = 0;
      final api = client((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      await expectLater(
        api.get('/api/user', authenticated: true),
        throwsA(isA<ApiException>()),
      );
      tokens.token = SanctumToken(value: 'expired-token', expiresAt: now);
      await expectLater(
        api.get('/api/user', authenticated: true),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'token-expired'),
        ),
      );
      expect(calls, 0);
      expect(tokens.token, isNull);
    },
  );

  test(
    'parses Laravel validation codes without replacing localization',
    () async {
      final api = client(
        (_) async => http.Response(
          jsonEncode({
            'code': 'validation-failed',
            'message': 'The submitted data is invalid.',
            'errors': {
              'email': ['Already registered'],
            },
            'error_codes': {
              'email': ['email-already-in-use'],
              'password': ['weak-password'],
            },
          }),
          422,
        ),
      );
      await expectLater(
        api.post('/api/auth/signup/start', body: {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'validation-failed')
              .having((e) => e.fieldCodes['email'], 'email code', [
                'email-already-in-use',
              ])
              .having((e) => e.fieldErrors['email'], 'email error', [
                'Already registered',
              ]),
        ),
      );
    },
  );

  test(
    'network failures and timeouts retain the session and redact details',
    () async {
      tokens.token = token('private-token');
      final api = client(
        (_) async =>
            throw http.ClientException('private-token and private response'),
      );
      try {
        await api.get('/api/user', authenticated: true);
        fail('Expected error');
      } on ApiException catch (error) {
        expect(error.code, 'network-request-failed');
        expect(error.toString(), isNot(contains('private-token')));
      }
      final slow = client((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return http.Response('{}', 200);
      }, timeout: const Duration(milliseconds: 2));
      await expectLater(
        slow.get('/api/user', authenticated: true),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'request-timeout'),
        ),
      );
      expect(tokens.clears, 0);
    },
  );

  test('handles no-content logout and raw health JSON', () async {
    final api = client(
      (r) async => r.url.path.endsWith('logout')
          ? http.Response('', 204)
          : http.Response('{"success":true}', 200),
    );
    expect(await api.post('/api/auth/logout', body: {}), isNull);
    expect(await api.get('/api/health'), {'success': true});
  });

  test('malformed JSON and non-object payloads fail safely', () async {
    for (final body in ['<html>private-token</html>', '[1,2]', 'null', '']) {
      final api = client((_) async => http.Response(body, 200));
      await expectLater(
        api.get('/api/health'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'invalid-response'),
        ),
      );
    }
  });

  test(
    'server failures keep status and token without echoing debug payload',
    () async {
      tokens.token = token('private-token');
      for (final status in [302, 429, 503]) {
        final api = client(
          (_) async => http.Response('private debug SQL and token', status),
        );
        await expectLater(
          api.get('/api/user', authenticated: true),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', status),
          ),
        );
      }
      expect(tokens.clears, 0);
    },
  );
}
