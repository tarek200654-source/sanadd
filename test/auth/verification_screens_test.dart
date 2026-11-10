import '../support/laravel_auth_fixture.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';

void main() {
  late LaravelAuthFixture fixture;
  setUp(() => fixture = LaravelAuthFixture());
  tearDown(() => fixture.close());
  Widget app(Widget home, {Locale locale = const Locale('en')}) {
    return fixture.app(home, language: locale.languageCode);
  }

  Future<void> pumpOtp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    String phoneNumber = '+201012345678',
  }) async {
    await fixture.auth.startLogin(
      email: 'amina@example.com',
      password: 'ValidPass1!',
      language: locale.languageCode,
    );
    await tester.pumpWidget(
      app(
        OtpVerificationScreen(
          arguments: AuthRouteArguments(
            role: UserRole.patient,
            isLoginVerification: true,
            phoneNumber: phoneNumber,
          ),
        ),
        locale: locale,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('OTP screen shows WhatsApp and hides email', (tester) async {
    await pumpOtp(tester);
    expect(find.textContaining('WhatsApp', findRichText: true), findsOneWidget);
    expect(find.text('+20 •••••• 5678'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('Arabic OTP keeps phone and digit entry LTR', (tester) async {
    await pumpOtp(tester, locale: const Locale('ar'));
    final phone = find.text('+20 •••••• 5678');
    expect(Directionality.of(tester.element(phone)), TextDirection.ltr);

    final firstDigit = find.descendant(
      of: find.byKey(const ValueKey('otp-code-field')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(firstDigit).textDirection,
      TextDirection.ltr,
    );
  });

  for (final callingCode in [
    '+20',
    '+966',
    '+971',
    '+965',
    '+974',
    '+968',
    '+973',
    '+962',
    '+1',
    '+44',
  ]) {
    testWidgets('OTP masks national digits for $callingCode', (tester) async {
      await pumpOtp(tester, phoneNumber: '${callingCode}1234567890');
      expect(find.text('$callingCode •••••• 7890'), findsOneWidget);
      expect(find.text('${callingCode}1234567890'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('OTP requires six digits and accepts a server-verified code', (
    tester,
  ) async {
    await pumpOtp(tester);
    await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.pump();
    expect(find.text('Enter the 6-digit verification code.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('otp-code-field')));
    await tester.enterText(
      find.byKey(const ValueKey('otp-code-field')),
      '123456',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('OTP action stays visible on a short device', (tester) async {
    const size = Size(318, 644);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpOtp(tester);

    final action = tester.getRect(
      find.byKey(const ValueKey('otp-verify-submit')),
    );
    expect(action.top, greaterThanOrEqualTo(0));
    expect(action.bottom, lessThanOrEqualTo(size.height));
    expect(tester.takeException(), isNull);
  });
}
