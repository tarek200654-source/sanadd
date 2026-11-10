import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/presentation/screens/splash_screen/splash_screen.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import '../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    f = LaravelAuthFixture();
  });
  tearDown(() => f.close());
  Future<void> frames(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 1500));
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
  }

  Future<void> saved() => f.tokens.save(
    SanctumToken(
      value: 'saved-token',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
    ),
  );
  testWidgets('startup validates saved token and reaches Home', (tester) async {
    await saved();
    await tester.pumpWidget(f.app(const SplashScreen()));
    await frames(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(f.auth.currentUser?.uid, '7');
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'startup transient error retains token and retries without opening Home',
    (tester) async {
      await saved();
      f.failureStatus = 503;
      f.failureCode = 'otp-service-unavailable';
      await tester.pumpWidget(f.app(const SplashScreen()));
      await frames(tester);
      expect(find.byType(HomeScreen), findsNothing);
      expect(await f.tokens.read(), isNotNull);
      expect(find.text('Retry'), findsOneWidget);
      f.failureStatus = null;
      await tester.tap(find.text('Retry'));
      await frames(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('direct protected route cannot show a profile without a token', (
    tester,
  ) async {
    await tester.pumpWidget(f.app(const HomeScreen()));
    await frames(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(f.requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Home retry receiving a revoked token leaves protected routes', (
    tester,
  ) async {
    await saved();
    f.failurePath = '/api/user';
    f.failureStatus = 503;
    f.failureCode = 'otp-service-unavailable';
    await tester.pumpWidget(f.app(const HomeScreen()));
    await frames(tester);
    expect(find.text('Try again'), findsOneWidget);
    f.failureStatus = 401;
    f.failureCode = 'unauthenticated';
    await tester.tap(find.text('Try again'));
    await frames(tester);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await f.tokens.read(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
