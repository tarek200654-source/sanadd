import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:sanad/presentation/screens/signup_screen/signup_screen.dart';
import '../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> frames(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 1100));
    await t.pump(const Duration(milliseconds: 300));
  }

  void expectProgress(WidgetTester tester, int step) {
    for (var index = 0; index < 4; index++) {
      final segment = tester.widget<AnimatedContainer>(
        find.byKey(ValueKey('recovery-progress-segment-$index')),
      );
      expect(
        (segment.decoration as BoxDecoration).color,
        index <= step ? AppColor.loginLightText : AppColor.loginLightBorder,
      );
      expect(segment.constraints!.maxWidth, index == step ? 24 : 10);
    }
    expect(
      find.byKey(const ValueKey('recovery-progress-segment-4')),
      findsNothing,
    );
  }

  Future<void> openEmail(WidgetTester tester, LaravelAuthFixture f) async {
    await tester.pumpWidget(
      f.app(
        const LoginScreen(
          arguments: AuthRouteArguments(role: UserRole.patient),
        ),
      ),
    );
    await frames(tester);
    await tester.tap(find.text('Forgot password?'));
    await frames(tester);
    expectProgress(tester, 0);
  }

  Future<void> nextEmail(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextField).first, email);
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await frames(tester);
  }

  Future<void> submitPhone(WidgetTester tester) async {
    expect(find.byType(SignUpScreen), findsNothing);
    expect(find.byKey(const ValueKey('recovery-phone-screen')), findsOneWidget);
    expectProgress(tester, 1);
    await tester.enterText(
      find.byKey(const ValueKey('recovery-phone-field')),
      '1012345678',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recovery-phone-next')));
    await frames(tester);
  }

  Future<void> openRecovery(WidgetTester tester, LaravelAuthFixture f) async {
    await tester.pumpWidget(
      f.app(
        const LoginScreen(
          arguments: AuthRouteArguments(role: UserRole.patient),
        ),
      ),
    );
    await frames(tester);
    await tester.tap(find.text('Forgot password?'));
    await frames(tester);
    await tester.enterText(find.byType(TextField).first, 'amina@example.com');
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await frames(tester);
    expect(f.requests.map((r) => r.url.path), [
      '/api/auth/password/eligibility',
    ]);
    await submitPhone(tester);
  }

  for (final email in ['unknown@example.com', 'not-an-email']) {
    testWidgets('$email cannot advance from email or start recovery', (
      tester,
    ) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await openEmail(tester, f);
      await nextEmail(tester, email);
      expect(find.byKey(const ValueKey('recovery-phone-screen')), findsNothing);
      expectProgress(tester, 0);
      expect(
        f.requests.where((r) => r.url.path != '/api/auth/password/eligibility'),
        isEmpty,
      );
      expect(f.auth.hasPendingRecovery, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'editing email during eligibility cannot advance unchecked details',
    (tester) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      final response = Completer<http.Response>();
      f.override = (_) => response.future;
      await openEmail(tester, f);
      await tester.enterText(find.byType(TextField).first, 'amina@example.com');
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField).first,
        'unknown@example.com',
      );
      response.complete(
        f.response('recovery-eligibility-checked', {'eligible': true}),
      );
      await frames(tester);
      expect(find.byKey(const ValueKey('recovery-phone-screen')), findsNothing);
      expectProgress(tester, 0);
      expect(f.auth.hasPendingRecovery, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final failure in ['network', 'server', 'malformed']) {
    testWidgets('email $failure failure stays on email with a separate error', (
      tester,
    ) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      f.override = (request) async {
        if (failure == 'network') throw http.ClientException('test offline');
        if (failure == 'server') {
          return f.response('otp-service-unavailable', {}, 503);
        }
        return f.response('recovery-eligibility-checked', {});
      };
      await openEmail(tester, f);
      await nextEmail(tester, 'amina@example.com');
      expect(find.byKey(const ValueKey('recovery-phone-screen')), findsNothing);
      final l10n = AppLocalizations(const Locale('en'));
      expect(
        find.text(
          failure == 'network'
              ? l10n.authNetworkError
              : l10n.otpServiceUnavailable,
        ),
        findsOneWidget,
      );
      expect(f.auth.hasPendingRecovery, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final failure in ['mismatch', 'unconfirmed', 'network']) {
    testWidgets('phone $failure cannot open OTP or lose the phone step', (
      tester,
    ) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await openEmail(tester, f);
      await nextEmail(tester, 'amina@example.com');
      expectProgress(tester, 1);
      expect(find.byType(SignUpScreen), findsNothing);
      f.override = (request) async {
        if (failure == 'network') throw http.ClientException('test offline');
        if (failure == 'mismatch') {
          return f.response('recovery-not-eligible', {}, 422);
        }
        final response = await f.respond(request);
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        (body['data'] as Map).remove('recovery_confirmed');
        return f.response(
          body['code'] as String,
          body['data'] as Map<String, dynamic>,
          response.statusCode,
        );
      };
      await submitPhone(tester);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expectProgress(tester, 1);
      expect(f.requests.any((r) => r.url.path.endsWith('/otp/send')), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('short phone stays on phone without a request', (tester) async {
    final f = LaravelAuthFixture();
    addTearDown(f.close);
    await openEmail(tester, f);
    await nextEmail(tester, 'amina@example.com');
    await tester.enterText(
      find.byKey(const ValueKey('recovery-phone-field')),
      '123',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('recovery-phone-next')));
    await frames(tester);
    expect(f.requests, hasLength(1));
    expectProgress(tester, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'reset Back returns to phone with proof retired and no automatic dispatch',
    (tester) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await openRecovery(tester, f);
      expectProgress(tester, 2);
      await tester.enterText(
        find.byKey(const ValueKey('otp-code-field')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
      await frames(tester);
      expectProgress(tester, 3);
      expect(f.auth.hasVerifiedRecovery, isTrue);
      final before = f.requests
          .where((r) => r.url.path.endsWith('/otp/send'))
          .length;
      await tester.tap(find.byTooltip('Back'));
      await frames(tester);
      expectProgress(tester, 1);
      expect(f.auth.hasVerifiedRecovery, isFalse);
      expect(
        f.requests.where((r) => r.url.path.endsWith('/otp/send')),
        hasLength(before),
      );
      await tester.tap(find.byTooltip('Back'));
      await frames(tester);
      expectProgress(tester, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'transient first-send failure retries the same attempt and sends once on OTP entry',
    (tester) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await openEmail(tester, f);
      await nextEmail(tester, 'amina@example.com');
      f.failurePath = '/api/auth/password/otp/send';
      f.failureCode = 'otp-service-unavailable';
      f.failureStatus = 503;
      await submitPhone(tester);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(f.auth.hasPendingRecovery, isTrue);
      f.failureStatus = null;
      await tester.tap(find.byKey(const ValueKey('recovery-phone-next')));
      await frames(tester);
      expectProgress(tester, 2);
      expect(
        f.requests.where((r) => r.url.path == '/api/auth/password/forgot'),
        hasLength(1),
      );
      expect(
        f.requests.where((r) => r.url.path == '/api/auth/password/otp/send'),
        hasLength(2),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'lost send acknowledgement and cooldown retain the same recovery attempt',
    (tester) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await openEmail(tester, f);
      await nextEmail(tester, 'amina@example.com');
      var sends = 0;
      f.override = (request) async {
        if (request.url.path != '/api/auth/password/otp/send') {
          return f.respond(request);
        }
        if (sends++ == 0) throw http.ClientException('acknowledgement lost');
        return f.response('too-many-requests', {}, 429);
      };
      await submitPhone(tester);
      await tester.tap(find.byKey(const ValueKey('recovery-phone-next')));
      await frames(tester);
      expectProgress(tester, 1);
      expect(f.auth.hasPendingRecovery, isTrue);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(
        find.text(AppLocalizations(const Locale('en')).otpRateLimited),
        findsOneWidget,
      );
      expect(
        f.requests.where((r) => r.url.path == '/api/auth/password/forgot'),
        hasLength(1),
      );
      expect(
        f.requests.where((r) => r.url.path == '/api/auth/password/otp/send'),
        hasLength(2),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('recovery resend clears input and stays in the recovery flow', (
    tester,
  ) async {
    final f = LaravelAuthFixture();
    addTearDown(f.close);
    f.override = (request) async {
      final response = await f.respond(request);
      if (request.url.path != '/api/auth/password/otp/send') return response;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      data['resend_at'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(seconds: 1))
          .toIso8601String();
      return f.response(body['code'] as String, data, response.statusCode);
    };
    await openRecovery(tester, f);
    await tester.enterText(find.byKey(const ValueKey('otp-code-field')), '123');
    await tester.tap(find.text('Resend code'));
    await frames(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('otp-code-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      f.requests.where((r) => r.url.path == '/api/auth/password/otp/send'),
      hasLength(2),
    );
    expect(f.requests.any((r) => r.url.path == '/api/auth/otp/send'), isFalse);
    expect(await f.tokens.read(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final failureStage in ['send', 'verify']) {
    testWidgets('expired recovery $failureStage returns to email entry', (
      tester,
    ) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      if (failureStage == 'send') {
        f.failurePath = '/api/auth/password/otp/send';
        f.failureCode = 'otp-expired';
        f.failureStatus = 410;
      }
      await openRecovery(tester, f);
      if (failureStage == 'verify') {
        f.failurePath = '/api/auth/password/otp/verify';
        f.failureCode = 'otp-expired';
        f.failureStatus = 410;
        await tester.enterText(
          find.byKey(const ValueKey('otp-code-field')),
          '123456',
        );
        await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
        await frames(tester);
      }
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(
        find.byKey(const ValueKey('recovery-phone-field')),
        findsOneWidget,
      );
      expect(f.auth.hasPendingRecovery, isFalse);
      expect(await f.tokens.read(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'recovery uses six WhatsApp digits and returns to Login without a session',
    (tester) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await tester.pumpWidget(
        f.app(
          const LoginScreen(
            arguments: AuthRouteArguments(role: UserRole.patient),
          ),
        ),
      );
      await frames(tester);
      await tester.tap(find.text('Forgot password?'));
      await frames(tester);
      await tester.enterText(find.byType(TextField).first, 'amina@example.com');
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await frames(tester);
      await submitPhone(tester);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expectProgress(tester, 2);
      expect(
        f.requests.where((r) => r.url.path.endsWith('/password/otp/send')),
        hasLength(1),
      );
      expect(find.text('+20 •••••• 5678'), findsOneWidget);
      final submitted =
          jsonDecode(
                f.requests
                    .firstWhere((r) => r.url.path.endsWith('/password/forgot'))
                    .body,
              )
              as Map;
      expect(submitted['phone_number'], '+201012345678');
      expect(
        find.textContaining('WhatsApp', findRichText: true),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('otp-code-field')),
        '000000',
      );
      await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
      await frames(tester);
      expect(find.byType(OtpVerificationScreen), findsOneWidget);
      expect(f.auth.hasPendingRecovery, isTrue);
      expect(await f.tokens.read(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('otp-code-field')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
      await frames(tester);
      expect(find.byType(TextField), findsNWidgets(2));
      expectProgress(tester, 3);
      await tester.enterText(find.byType(TextField).at(0), 'NewStrongPass1!');
      await tester.enterText(find.byType(TextField).at(1), 'NewStrongPass1!');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await frames(tester);
      expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);
      expect(await f.tokens.read(), isNull);
      expect(
        f.requests.map((r) => r.url.path),
        contains('/api/auth/password/reset'),
      );
      expect(
        f.requests.any((r) => r.url.path == '/api/auth/otp/verify'),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets(
      'recovery $language reuses country picker and normalizes its number',
      (tester) async {
        final f = LaravelAuthFixture();
        f.recoveryPhoneNumber = '+966512346789';
        addTearDown(f.close);
        await tester.pumpWidget(
          f.app(
            const LoginScreen(
              arguments: AuthRouteArguments(role: UserRole.patient),
            ),
            language: language,
          ),
        );
        await frames(tester);
        await tester.tap(
          find.text(
            language == 'ar' ? 'نسيت كلمة المرور؟' : 'Forgot password?',
          ),
        );
        await frames(tester);
        await tester.enterText(
          find.byType(TextField).first,
          'amina@example.com',
        );
        await tester.tap(find.text(language == 'ar' ? 'التالي' : 'Next'));
        await frames(tester);
        await tester.tap(find.text('+20'));
        await frames(tester);
        expect(
          find.text(language == 'ar' ? 'كود الدولة' : 'Country Code'),
          findsOneWidget,
        );
        await tester.tap(find.text('🇸🇦 +966'));
        await frames(tester);
        await tester.enterText(
          find.byKey(const ValueKey('recovery-phone-field')),
          '512346789',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('recovery-phone-next')));
        await frames(tester);
        expect(find.byType(OtpVerificationScreen), findsOneWidget);
        expect(find.text('+966 •••••• 6789'), findsOneWidget);
        final request = f.requests.firstWhere(
          (r) => r.url.path.endsWith('/password/forgot'),
        );
        expect(
          (jsonDecode(request.body) as Map)['phone_number'],
          '+966512346789',
        );
        expect((jsonDecode(request.body) as Map)['language'], language);
        expect(await f.tokens.read(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'recovery $language fits a small phone and keyboard, digits remain LTR',
      (tester) async {
        final f = LaravelAuthFixture();
        addTearDown(f.close);
        await tester.binding.setSurfaceSize(const Size(318, 644));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          f.app(
            const LoginScreen(
              arguments: AuthRouteArguments(role: UserRole.patient),
            ),
            language: language,
          ),
        );
        await frames(tester);
        await tester.tap(
          find.text(
            language == 'ar' ? 'نسيت كلمة المرور؟' : 'Forgot password?',
          ),
        );
        await frames(tester);
        await tester.enterText(
          find.byType(TextField).first,
          'amina@example.com',
        );
        final send = find.text(language == 'ar' ? 'التالي' : 'Next');
        await tester.ensureVisible(send);
        await tester.tap(send);
        await frames(tester);
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        expect(tester.takeException(), isNull);
        await submitPhone(tester);
        expect(find.byType(OtpVerificationScreen), findsOneWidget);
        final first = find.descendant(
          of: find.byKey(const ValueKey('otp-code-field')),
          matching: find.byType(EditableText),
        );
        expect(
          tester.widget<EditableText>(first).textDirection,
          TextDirection.ltr,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        final action = find.byKey(const ValueKey('otp-verify-submit'));
        await tester.ensureVisible(action);
        await tester.pump();
        expect(tester.takeException(), isNull);
        final back = find.byTooltip(language == 'ar' ? 'رجوع' : 'Back');
        await tester.ensureVisible(back);
        await tester.tap(back);
        await frames(tester);
        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.byKey(const ValueKey('recovery-phone-field')),
          findsOneWidget,
        );
        expect(f.auth.hasPendingRecovery, isFalse);
        await tester.tap(back);
        await frames(tester);
        expect(find.text(language == 'ar' ? 'التالي' : 'Next'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
