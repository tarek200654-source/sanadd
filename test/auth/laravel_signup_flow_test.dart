import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import '../application/auth/laravel_signup_test.dart' show registration;
import '../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final role in UserRole.values) {
    testWidgets('signup OTP to Home for ${role.name}', (tester) async {
      final f = LaravelAuthFixture()..role = role.name;
      addTearDown(f.close);
      await f.auth.startSignup(
        registration(role),
        passwordConfirmation: 'ValidPass1!',
        language: 'en',
      );
      await tester.pumpWidget(
        f.app(OtpVerificationScreen(arguments: AuthRouteArguments(role: role))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(await f.tokens.read(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('otp-code-field')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(f.auth.currentUser?.role, role);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
