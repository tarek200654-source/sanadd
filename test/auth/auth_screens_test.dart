import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/data/repositories/wexora_otp_repository.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:sanad/presentation/screens/signup_screen/signup_screen.dart';
import 'package:sanad/utils/routes.dart';

void main() {
  Widget app(
    Widget home, {
    Locale locale = const Locale('en'),
    NavigatorObserver? observer,
  }) {
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
      navigatorObservers: [?observer],
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

  Future<void> pumpAuthApp(
    WidgetTester tester,
    Widget home, {
    Locale? locale,
    NavigatorObserver? observer,
  }) async {
    await tester.pumpWidget(
      app(home, locale: locale ?? const Locale('en'), observer: observer),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login rejects invalid email and keeps the Oufa auth layout', (
    tester,
  ) async {
    await pumpAuthApp(
      tester,
      const LoginScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-email-field')),
      'not-an-email',
    );
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('AR'), findsNothing);
    expect(find.text('EN'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets(
    'valid login stays in auth UI and explains backend is not connected',
    (tester) async {
      await pumpAuthApp(
        tester,
        const LoginScreen(
          arguments: AuthRouteArguments(role: UserRole.caregiver),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('auth-email-field')),
        'caregiver@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password-field')),
        'NotConnected1!',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Preview only. No data was sent.'), findsOneWidget);
      expect(find.text('Welcome to SANAD'), findsNothing);
    },
  );

  testWidgets(
    'signup shows password requirements on focus and requires terms',
    (tester) async {
      await pumpAuthApp(
        tester,
        const SignUpScreen(
          arguments: AuthRouteArguments(role: UserRole.caregiver),
        ),
      );

      expect(find.text('At least 9 characters'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('signup-password-field')));
      await tester.pump();
      expect(find.text('At least 9 characters'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('signup-password-field')),
        'ValidPass1!',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup-confirm-password-field')),
      );
      await tester.tap(
        find.byKey(const ValueKey('signup-confirm-password-field')),
      );
      await tester.pump();
      expect(find.text('At least 9 characters'), findsNothing);

      await tester.ensureVisible(find.byKey(const ValueKey('signup-submit')));
      await tester.tap(find.byKey(const ValueKey('signup-submit')));
      await tester.pump();
      expect(find.text('Full name is required.'), findsOneWidget);
      expect(find.text('Please agree before continuing.'), findsOneWidget);
    },
  );

  testWidgets('signup is part of the copied auth flow and returns to login', (
    tester,
  ) async {
    await pumpAuthApp(
      tester,
      const LoginScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-email-field')),
      'returning@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password-field')),
      'NotConnected1!',
    );
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Start with email'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    final emailField = find.descendant(
      of: find.byKey(const ValueKey('auth-email-field')),
      matching: find.byType(TextField),
    );
    final passwordField = find.descendant(
      of: find.byKey(const ValueKey('auth-password-field')),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(emailField).controller?.text,
      'returning@example.com',
    );
    expect(
      tester.widget<TextField>(passwordField).controller?.text,
      'NotConnected1!',
    );
  });

  testWidgets('short login keeps its primary action near the bottom', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAuthApp(
      tester,
      const LoginScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
    );

    final buttonRect = tester.getRect(
      find.byKey(const ValueKey('login-submit')),
    );
    expect(buttonRect.bottom, greaterThan(720));
  });

  testWidgets('login and signup use the reference auth type scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthApp(
      tester,
      const LoginScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
    );
    expect(
      tester.widget<Text>(find.text('Log in to your account')).style?.fontSize,
      30,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('login-submit'))).height,
      58,
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('login-submit')),
              matching: find.text('Sign in'),
            ),
          )
          .style
          ?.fontSize,
      16,
    );

    await pumpAuthApp(
      tester,
      const SignUpScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
    );
    expect(
      tester.widget<Text>(find.text('Create a new account')).style?.fontSize,
      24,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('signup-submit'))).height,
      54,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('signup-phone-field'))).height,
      54,
    );
  });

  testWidgets('auth primary actions remain reachable across phone sizes', (
    tester,
  ) async {
    const sizes = [Size(318, 644), Size(390, 844), Size(480, 960)];
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetViewPadding();
    });

    final screens = <(Widget, String)>[
      (
        const LoginScreen(
          arguments: AuthRouteArguments(role: UserRole.patient),
        ),
        'login-submit',
      ),
      (
        SignUpScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
        'signup-submit',
      ),
      (
        const OtpVerificationScreen(
          arguments: AuthRouteArguments(
            role: UserRole.patient,
            email: 'sarah@gmail.com',
            phoneNumber: '+201012345678',
          ),
          repository: _FakeOtpRepository(),
        ),
        'otp-verify-submit',
      ),
    ];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      for (final (screen, actionKey) in screens) {
        await pumpAuthApp(tester, screen);
        await tester.ensureVisible(find.byKey(ValueKey(actionKey)));
        await tester.pumpAndSettle();
        final action = tester.getRect(find.byKey(ValueKey(actionKey)));
        expect(
          action.top,
          greaterThanOrEqualTo(0),
          reason: '$actionKey at $size',
        );
        expect(
          action.bottom,
          lessThanOrEqualTo(size.height),
          reason: '$actionKey at $size',
        );
        expect(tester.takeException(), isNull, reason: '$actionKey at $size');
      }
    }
  });

  testWidgets(
    'focused password checklist remains reachable with keyboard open',
    (tester) async {
      const size = Size(318, 644);
      await tester.binding.setSurfaceSize(size);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewInsets = const FakeViewPadding(bottom: 275);
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.view.resetViewInsets();
        tester.view.resetViewPadding();
      });

      await pumpAuthApp(
        tester,
        SignUpScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
      );
      final passwordField = find.byKey(const ValueKey('signup-password-field'));
      await tester.ensureVisible(passwordField);
      await tester.tap(passwordField);
      await tester.pumpAndSettle();

      final keyboardTop = size.height - 275;
      final activeFieldRect = tester.getRect(passwordField);
      expect(activeFieldRect.top, greaterThanOrEqualTo(0));
      expect(activeFieldRect.bottom, lessThanOrEqualTo(keyboardTop));
      expect(find.text('At least 9 characters'), findsOneWidget);
      await tester.ensureVisible(find.text('One special character'));
      await tester.pumpAndSettle();

      final checklistRect = tester.getRect(find.text('One special character'));
      expect(checklistRect.bottom, lessThanOrEqualTo(keyboardTop));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Arabic auth keeps credential fields left to right', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(318, 644));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAuthApp(
      tester,
      const SignUpScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
      locale: const Locale('ar'),
    );

    expect(
      Directionality.of(tester.element(find.byType(SignUpScreen))),
      TextDirection.rtl,
    );
    final heading = find.text('إنشاء حساب جديد');
    expect(tester.widget<Text>(heading).textAlign, TextAlign.start);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    for (final key in [
      const ValueKey('signup-phone-field'),
      const ValueKey('signup-email-field'),
      const ValueKey('signup-password-field'),
    ]) {
      final field = find.descendant(
        of: find.byKey(key),
        matching: find.byType(EditableText),
      );
      expect(
        tester.widget<EditableText>(field).textDirection,
        TextDirection.ltr,
      );
    }
  });

  testWidgets(
    'signup requires matching password and valid terms before navigation',
    (tester) async {
      final observer = _RecordingObserver();
      await pumpAuthApp(
        tester,
        SignUpScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
        observer: observer,
      );
      observer.lastPushed = null;

      await tester.enterText(
        find.byKey(const ValueKey('signup-name-field')),
        'أحمد بن علي',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-phone-field')),
        '010 1234 5678',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-email-field')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-password-field')),
        'ValidPass1!',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-confirm-password-field')),
        'ValidPass2!',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('signup-terms-checkbox')),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('signup-terms-checkbox')))
            .height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byKey(const ValueKey('signup-terms-checkbox')));
      await tester.pump();
      expect(
        tester
            .widget<Checkbox>(
              find.byKey(const ValueKey('signup-terms-checkbox')),
            )
            .value,
        isTrue,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('signup-submit')));
      await tester.tap(find.byKey(const ValueKey('signup-submit')));
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(observer.lastPushed?.settings.name, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('signup-confirm-password-field')),
        'ValidPass1!',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('signup-submit')));
      await tester.tap(find.byKey(const ValueKey('signup-submit')));
      await tester.pumpAndSettle();
      expect(observer.lastPushed?.settings.name, AppRoutes.otpVerification);
      final arguments =
          observer.lastPushed?.settings.arguments as AuthRouteArguments;
      expect(arguments.role, UserRole.patient);
      expect(arguments.email, 'user@example.com');
      expect(arguments.phoneNumber, '+201012345678');
    },
  );
}

class _FakeOtpRepository implements OtpVerificationRepository {
  const _FakeOtpRepository();

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
  }) async => false;
}

class _RecordingObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
    super.didPush(route, previousRoute);
  }
}
