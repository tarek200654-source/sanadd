import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/data/repositories/wexora_otp_repository.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:sanad/utils/routes.dart';

void main() {
  final repository = _FakeOtpRepository();
  Widget app(Widget home, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      theme: AppColor.theme(isArabic: locale.languageCode == 'ar'),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: home,
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> pumpOtp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      app(
        OtpVerificationScreen(
          arguments: const AuthRouteArguments(
            role: UserRole.patient,
            phoneNumber: '+201012345678',
          ),
          repository: repository,
        ),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('OTP screen shows WhatsApp and hides email', (tester) async {
    await pumpOtp(tester);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('+••••••5678'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('Arabic OTP keeps phone and digit entry LTR', (tester) async {
    await pumpOtp(tester, locale: const Locale('ar'));
    final phone = find.text('+••••••5678');
    expect(tester.widget<Text>(phone).textDirection, TextDirection.ltr);

    final firstDigit = find.descendant(
      of: find.byKey(const ValueKey('otp-input-0')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(firstDigit).textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('OTP requires six digits and accepts a verified Wexora code', (
    tester,
  ) async {
    await pumpOtp(tester);
    await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.pump();
    expect(find.text('Enter the 6-digit verification code.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('otp-input-0')));
    await tester.enterText(find.byKey(const ValueKey('otp-input-0')), '123456');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.pump();
    expect(find.text('Verified successfully'), findsOneWidget);
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

class _FakeOtpRepository implements OtpVerificationRepository {
  @override
  Future<OtpChallenge> sendCode({
    required String phoneNumber,
    required String language,
  }) async => OtpChallenge(
    id: 'otp-challenge-12345',
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
  );

  @override
  Future<bool> verifyCode({
    required String challengeId,
    required String code,
  }) async => code == '123456';
}
