import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sanad/application/auth/auth_service.dart';
import 'package:sanad/application/auth/auth_scope.dart';
import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/data/network/api_client.dart';
import 'package:sanad/data/network/api_config.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/domain/repositories/token_store.dart';
import 'package:sanad/utils/routes.dart';

class LaravelAuthFixture {
  LaravelAuthFixture() {
    FlutterSecureStorage.setMockInitialValues({});
    tokens = TestTokenStore();
    api = ApiClient(
      config: ApiConfig(baseUrl: 'http://127.0.0.1:8000'),
      tokenStore: tokens,
      httpClient: MockClient((r) {
        requests.add(r);
        return override?.call(r) ?? respond(r);
      }),
    );
    auth = AuthService(api: api, tokenStore: tokens);
  }
  late final TestTokenStore tokens;
  late final ApiClient api;
  late final AuthService auth;
  final requests = <http.Request>[];
  String role = 'caregiver';
  String purpose = 'login';
  String recoveryPhoneNumber = '+201012345678';
  int? failureStatus;
  String? failureCode;
  String? failurePath;
  Future<http.Response> Function(http.Request)? override;
  static const id = '79e6b581-b223-4c55-b180-878f6dbc159a';
  final secret = List.filled(64, 'a').join();
  Map<String, dynamic> get user => {
    'id': '7',
    'name': 'Amina Hassan',
    'email': 'amina@example.com',
    'role': role,
    'username': 'Amina_1',
    'first_name': 'Amina',
    'last_name': 'Hassan',
    'phone_number': '+201012345678',
    'country': 'Egypt',
    'region': 'Cairo',
    'address': 'Test address',
    'created_at': DateTime.now().toUtc().toIso8601String(),
  };
  http.Response response(
    String code,
    Map<String, dynamic> data, [
    int status = 200,
  ]) => http.Response(jsonEncode({'code': code, 'data': data}), status);
  Map<String, dynamic> get session => {
    'authenticated': true,
    'user': user,
    'token': '7|test-only-token',
    'token_type': 'Bearer',
    'expires_at': DateTime.now()
        .toUtc()
        .add(const Duration(days: 7))
        .toIso8601String(),
  };
  Future<http.Response> respond(http.Request r) async {
    if (failureStatus != null &&
        (failurePath == null || failurePath == r.url.path)) {
      return http.Response(jsonEncode({'code': failureCode}), failureStatus!);
    }
    switch (r.url.path) {
      case '/api/auth/password/eligibility':
        return response('recovery-eligibility-checked', {
          'eligible':
              (jsonDecode(r.body) as Map)['email'] != 'unknown@example.com',
        });
      case '/api/auth/login/start':
      case '/api/auth/signup/start':
      case '/api/auth/password/forgot':
        if (r.url.path == '/api/auth/password/forgot') {
          final input = jsonDecode(r.body) as Map;
          if (input['email'] == 'unknown@example.com' ||
              input['phone_number'] != recoveryPhoneNumber) {
            return response('recovery-not-eligible', {}, 422);
          }
        }
        purpose = r.url.path.contains('signup')
            ? 'signup'
            : r.url.path.contains('password')
            ? 'password_reset'
            : 'login';
        return response(
          purpose == 'signup'
              ? 'signup-started'
              : purpose == 'login'
              ? 'login-started'
              : 'password-recovery-started',
          {
            'attempt_id': id,
            'attempt_token': secret,
            'purpose': purpose,
            if (purpose == 'password_reset') 'recovery_confirmed': true,
            if (purpose == 'login') 'masked_phone_number': '+20 ****** 5678',
            'otp_started': false,
            'authenticated': false,
            'expires_at': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 10))
                .toIso8601String(),
          },
          purpose == 'password_reset' ? 202 : 201,
        );
      case '/api/auth/otp/send':
      case '/api/auth/password/otp/send':
        return response(
          purpose == 'password_reset'
              ? 'recovery-request-accepted'
              : 'otp-sent',
          {
            'attempt_id': id,
            'otp_started': true,
            if (purpose == 'password_reset') 'recovery_confirmed': true,
            'authenticated': false,
            'expires_at': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 5))
                .toIso8601String(),
            'resend_at': DateTime.now()
                .toUtc()
                .add(const Duration(seconds: 60))
                .toIso8601String(),
          },
          202,
        );
      case '/api/auth/otp/verify':
      case '/api/auth/password/otp/verify':
        if ((jsonDecode(r.body) as Map)['code'] != '123456') {
          return http.Response('{"code":"invalid-code"}', 422);
        }
        if (purpose == 'login') return response('authenticated', session);
        return response(
          purpose == 'signup'
              ? 'signup-verified'
              : 'password-recovery-verified',
          {
            'authenticated': false,
            purpose == 'signup' ? 'verification_proof' : 'reset_proof': secret,
            'expires_at': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 5))
                .toIso8601String(),
          },
        );
      case '/api/auth/register':
        return response('registered', session, 201);
      case '/api/auth/password/reset':
        return response('password-reset', {
          'authenticated': false,
          'login_required': true,
        });
      case '/api/auth/availability/email':
      case '/api/auth/availability/username':
        return response('availability-checked', {'available': true});
      case '/api/user':
        return response('user-retrieved', {'user': user});
      case '/api/auth/logout':
        return http.Response('', 204);
      default:
        throw StateError('Unexpected mocked API endpoint');
    }
  }

  Widget app(
    Widget home, {
    String language = 'en',
    Map<String, WidgetBuilder>? routes,
  }) => AuthScope(
    auth: auth,
    child: MaterialApp(
      theme: AppColor.theme(isArabic: language == 'ar'),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: AppRoutes.onGenerateRoute,
      routes: routes ?? {},
      home: home,
      builder: (context, child) => Directionality(
        textDirection: language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
    ),
  );
  void close() => api.close();
}

class TestTokenStore implements TokenStore {
  SanctumToken? value;
  @override
  Future<SanctumToken?> read() async =>
      value?.isExpired(DateTime.now()) == true ? null : value;
  @override
  Future<void> save(SanctumToken token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<void> clearIfMatches(SanctumToken expected) async {
    if (value?.value == expected.value) value = null;
  }
}
