import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import '../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture fixture;
  setUp(() => fixture = LaravelAuthFixture());
  tearDown(() => fixture.close());
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      fixture.app(
        const LoginScreen(
          arguments: AuthRouteArguments(role: UserRole.patient),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byKey(const ValueKey('auth-email-field')),
      'amina@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password-field')),
      'ValidPass1!',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('login-submit')));
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'login and OTP share pending service; backend role reaches Home',
    (tester) async {
      await open(tester);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(
        fixture.requests.where((r) => r.url.path.endsWith('/otp/send')).length,
        1,
      );
      expect(await fixture.tokens.read(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('otp-code-field')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(fixture.auth.currentUser?.role, UserRole.caregiver);
      expect(await fixture.tokens.read(), isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('login shows the masked destination supplied by the server', (
    tester,
  ) async {
    fixture.override = (request) async {
      final response = await fixture.respond(request);
      if (request.url.path != '/api/auth/login/start') return response;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      data['masked_phone_number'] = '+20 ****** 5678';
      return fixture.response(
        body['code'] as String,
        data,
        response.statusCode,
      );
    };
    await open(tester);
    expect(find.text('+20 •••••• 5678'), findsOneWidget);
    expect(find.text('+201012345678'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('invalid credentials stay on Login and do not save token', (
    tester,
  ) async {
    fixture.failurePath = '/api/auth/login/start';
    fixture.failureStatus = 401;
    fixture.failureCode = 'invalid-credentials';
    await open(tester);
    expect(find.byType(OtpVerificationScreen), findsNothing);
    expect(await fixture.tokens.read(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'expired login attempt during send returns to Login without automatically restarting',
    (tester) async {
      fixture.failurePath = '/api/auth/otp/send';
      fixture.failureStatus = 410;
      fixture.failureCode = 'otp-expired';
      await open(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(fixture.requests.length, 2);
      expect(await fixture.tokens.read(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
