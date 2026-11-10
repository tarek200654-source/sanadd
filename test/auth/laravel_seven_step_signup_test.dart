import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/signup_screen/signup_screen.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import '../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> frames(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 1100));
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> enter(WidgetTester t, String key, String value) async {
    await t.enterText(find.byKey(ValueKey(key)), value);
    await frames(t);
  }

  Future<void> next(WidgetTester t) async {
    await t.ensureVisible(find.byKey(const ValueKey('signup-submit')));
    await t.tap(find.byKey(const ValueKey('signup-submit')));
    await frames(t);
  }

  for (final role in UserRole.values) {
    testWidgets('seven-step ${role.name} signup through OTP to Home', (
      tester,
    ) async {
      final f = LaravelAuthFixture()..role = role.name;
      addTearDown(f.close);
      await tester.pumpWidget(
        f.app(SignUpScreen(arguments: AuthRouteArguments(role: role))),
      );
      await frames(tester);
      await enter(tester, 'signup-email-field', 'amina@example.com');
      await next(tester);
      await enter(tester, 'signup-username-field', 'Amina_1');
      await next(tester);
      await enter(tester, 'signup-first-name-field', 'Amina');
      await enter(tester, 'signup-last-name-field', 'Hassan');
      await next(tester);
      await enter(tester, 'signup-password-field', 'ValidPass1!');
      await enter(tester, 'signup-confirm-password-field', 'ValidPass1!');
      await next(tester);
      await enter(tester, 'signup-phone-field', '1012345678');
      await next(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup-region-field')),
      );
      await tester.tap(
        find
            .ancestor(
              of: find.byKey(const ValueKey('signup-region-field')),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
      await frames(tester);
      await tester.tap(find.text('Cairo').last);
      await frames(tester);
      await next(tester);
      await enter(tester, 'signup-address-field', '12 Nile Street');
      await next(tester);
      expect(await f.tokens.read(), isNull);
      final submitted =
          jsonDecode(
                f.requests
                    .firstWhere((r) => r.url.path.endsWith('/signup/start'))
                    .body,
              )
              as Map;
      expect(submitted['role'], role.name);
      expect(submitted['phone_number'], '+201012345678');
      expect(submitted['address'], '12 Nile Street');
      await tester.enterText(
        find.byKey(const ValueKey('otp-code-field')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
      await frames(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(f.auth.currentUser?.role, role);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('email checks remain debounced and send latest value only', (
    tester,
  ) async {
    final f = LaravelAuthFixture();
    addTearDown(f.close);
    await tester.pumpWidget(
      f.app(
        const SignUpScreen(
          arguments: AuthRouteArguments(role: UserRole.patient),
        ),
      ),
    );
    await frames(tester);
    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'old@example.com',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'new@example.com',
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(f.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(f.requests.length, 1);
    expect(jsonDecode(f.requests.single.body), {'email': 'new@example.com'});
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
