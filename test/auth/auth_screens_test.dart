import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/application/auth/auth_service.dart';
import 'package:sanad/domain/models/app_user.dart';
import 'package:sanad/domain/repositories/auth_repository.dart';
import 'package:sanad/domain/repositories/user_repository.dart';
import 'package:sanad/data/repositories/wexora_otp_repository.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:sanad/presentation/screens/signup_screen/signup_screen.dart';
import 'package:sanad/presentation/screens/splash_screen/splash_screen.dart';
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

  testWidgets('splash restores a signed-in profile before routing home', (
    tester,
  ) async {
    await pumpAuthApp(tester, SplashScreen(authService: _testAuthService()));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to SANAD'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('valid login loads the saved user profile and opens home', (
    tester,
  ) async {
    final service = _testAuthService();
    await pumpAuthApp(
      tester,
      LoginScreen(
        arguments: AuthRouteArguments(role: UserRole.caregiver),
        authService: service,
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

    expect(find.text('Welcome to SANAD'), findsOneWidget);
    expect(find.text('Preview only. No data was sent.'), findsNothing);
  });

  testWidgets(
    'signup starts with the existing seven-step registration screen',
    (tester) async {
      await pumpAuthApp(
        tester,
        const SignUpScreen(
          arguments: AuthRouteArguments(role: UserRole.patient),
        ),
      );

      expect(find.text('Welcome, Start with email'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Create a new account'), findsNothing);
    },
  );

  testWidgets('signup advances from email to username after email validation', (
    tester,
  ) async {
    await pumpAuthApp(
      tester,
      SignUpScreen(
        arguments: const AuthRouteArguments(role: UserRole.caregiver),
        authService: _testAuthService(),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'newuser@example.com',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Choose username'), findsOneWidget);
    expect(find.byKey(const ValueKey('signup-username-field')), findsOneWidget);
  });

  testWidgets('username availability failures are shown as errors', (
    tester,
  ) async {
    final authService = AuthService(
      authRepository: _FakeAuthRepository(),
      userRepository: _FakeUserRepository(
        usernameAvailability: (_) async => throw StateError('Firestore offline'),
      ),
    );
    await pumpAuthApp(
      tester,
      SignUpScreen(
        arguments: const AuthRouteArguments(role: UserRole.caregiver),
        authService: authService,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'newuser@example.com',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('signup-username-field')),
      'setugd',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    final feedback = tester.widget<Text>(find.text('Could not check availability'));
    expect(feedback.style?.color, AppColor.loginError);
    final inputContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('signup-username-field')),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = inputContainer.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, AppColor.loginError);
  });

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
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Start with email'), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/back_to_left.png',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    final emailField = find.byKey(const ValueKey('auth-email-field'));
    final passwordField = find.byKey(const ValueKey('auth-password-field'));
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
    expect(buttonRect.bottom, greaterThan(844 * .75));
    expect(buttonRect.bottom, lessThanOrEqualTo(844));
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
    final loginButtonLabel = find.descendant(
      of: find.byKey(const ValueKey('login-submit')),
      matching: find.text('Sign in'),
    );
    expect(
      DefaultTextStyle.of(tester.element(loginButtonLabel)).style.fontSize,
      16,
    );

    await pumpAuthApp(
      tester,
      const SignUpScreen(arguments: AuthRouteArguments(role: UserRole.patient)),
    );
    expect(
      tester
          .widget<Text>(find.text('Welcome, Start with email'))
          .style
          ?.fontSize,
      28,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('signup-submit'))).height,
      58,
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

  testWidgets('signup email remains reachable with keyboard open', (
    tester,
  ) async {
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
      SignUpScreen(
        arguments: const AuthRouteArguments(role: UserRole.patient),
        authService: _testAuthService(),
      ),
    );
    final emailField = find.byKey(const ValueKey('signup-email-field'));
    await tester.ensureVisible(emailField);
    await tester.tap(emailField);
    await tester.pumpAndSettle();

    final keyboardTop = size.height - 275;
    final activeFieldRect = tester.getRect(emailField);
    expect(activeFieldRect.top, greaterThanOrEqualTo(0));
    expect(activeFieldRect.bottom, lessThanOrEqualTo(keyboardTop + 8));
    expect(tester.takeException(), isNull);
  });

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
    final heading = find.text('أهلاً بك، ابدأ ببريدك');
    expect(tester.widget<Text>(heading).textAlign, isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/back_to_right.png',
      ),
      findsOneWidget,
    );
    final emailField = find.byKey(const ValueKey('signup-email-field'));
    expect(emailField, findsOneWidget);
  });

  testWidgets('signup passes the complete registration to OTP', (tester) async {
    final observer = _RecordingObserver();
    await pumpAuthApp(
      tester,
      SignUpScreen(
        arguments: const AuthRouteArguments(role: UserRole.patient),
        authService: _testAuthService(),
      ),
      observer: observer,
    );
    observer.lastPushed = null;

    await tester.enterText(
      find.byKey(const ValueKey('signup-email-field')),
      'user@example.com',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('signup-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Choose username'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('signup-username-field')),
      'user_123',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('signup-submit')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('signup-first-name-field')),
      'Amina',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-last-name-field')),
      'Hassan',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('signup-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Secure account'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('signup-password-field')),
      'ValidPass1!',
    );
    await tester.enterText(
      find.byKey(const ValueKey('signup-confirm-password-field')),
      'ValidPass1!',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('signup-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('signup-phone-field')),
      '1012345678',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('signup-submit')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('signup-region-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(
            of: find.byKey(const ValueKey('signup-region-field')),
            matching: find.byType(GestureDetector),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('signup-submit')));
    await tester.tap(find.byKey(const ValueKey('signup-submit')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('signup-address-field')),
      '12 Nile Street',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('signup-submit')));
    await tester.tap(find.byKey(const ValueKey('signup-submit')));
    await tester.pumpAndSettle();

    expect(observer.lastPushed?.settings.name, AppRoutes.otpVerification);
    final arguments =
        observer.lastPushed?.settings.arguments as AuthRouteArguments;
    expect(arguments.role, UserRole.patient);
    expect(arguments.email, 'user@example.com');
    expect(arguments.phoneNumber, '+201012345678');
    expect(arguments.registrationData?.username, 'user_123');
    expect(arguments.registrationData?.firstName, 'Amina');
    expect(arguments.registrationData?.lastName, 'Hassan');
    expect(arguments.registrationData?.country, 'Egypt');
    expect(arguments.registrationData?.region, 'Cairo');
    expect(arguments.registrationData?.address, '12 Nile Street');
  });
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

AuthService _testAuthService() => AuthService(
  authRepository: _FakeAuthRepository(),
  userRepository: _FakeUserRepository(),
);

class _FakeAuthRepository implements AuthRepository {
  @override
  String? get currentUserId => 'test-uid';

  @override
  Stream<String?> authStateChanges() => const Stream.empty();

  @override
  Future<String> createAccount({
    required String email,
    required String password,
  }) async => 'test-uid';

  @override
  Future<void> deleteCurrentAccount() async {}

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async => 'test-uid';

  @override
  Future<void> signOut() async {}
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({this.usernameAvailability});

  final Future<bool> Function(String username)? usernameAvailability;

  @override
  Future<void> createUser(AppUser user) async {}

  @override
  Future<AppUser?> getUser(String uid) async => const AppUser(
    uid: 'test-uid',
    name: 'Test User',
    email: 'caregiver@example.com',
    role: UserRole.caregiver,
    username: 'caregiver_1',
    firstName: 'Test',
    lastName: 'User',
    country: 'Egypt',
    region: 'Cairo',
    address: 'Test Street',
    phoneNumber: '+201012345678',
  );

  @override
  Future<bool> isUsernameAvailable(String username) async =>
      usernameAvailability?.call(username) ?? true;
}
