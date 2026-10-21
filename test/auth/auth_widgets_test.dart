import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/presentation/auth/validation/auth_validators.dart';
import 'package:sanad/presentation/widgets/auth/auth_header.dart';
import 'package:sanad/presentation/widgets/auth/otp_input.dart';
import 'package:sanad/presentation/widgets/auth/password_requirements.dart';
import 'package:sanad/presentation/widgets/auth/auth_text_field.dart';
import 'package:sanad/presentation/widgets/auth/verification_method_card.dart';
import 'package:sanad/presentation/widgets/sanad_button.dart';

void main() {
  Widget app(Widget child, {Locale locale = const Locale('en')}) {
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
      home: Scaffold(body: child),
    );
  }

  testWidgets('password requirements remain hidden until made visible', (
    tester,
  ) async {
    final validation = PasswordValidation.evaluate('Abcdef12!');
    await tester.pumpWidget(
      app(PasswordRequirements(validation: validation, visible: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('At least 9 characters'), findsNothing);

    await tester.pumpWidget(
      app(PasswordRequirements(validation: validation, visible: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('At least 9 characters'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(5));
  });

  testWidgets('visible password requirements use compact vertical space', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Align(
          alignment: Alignment.topCenter,
          child: PasswordRequirements(
            validation: PasswordValidation.evaluate('Abcdef12!'),
            visible: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(PasswordRequirements),
                  matching: find.byType(Column),
                )
                .first,
          )
          .height,
      lessThanOrEqualTo(112),
    );
  });

  testWidgets('password field toggles obscuring without changing its value', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Abcdef12!');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        AuthPasswordField(
          controller: controller,
          label: 'Password',
          showPasswordLabel: 'Show password',
          hidePasswordLabel: 'Hide password',
        ),
      ),
    );
    await tester.pumpAndSettle();

    EditableText field() =>
        tester.widget<EditableText>(find.byType(EditableText));
    expect(field().obscureText, isTrue);
    expect(controller.text, 'Abcdef12!');

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(field().obscureText, isFalse);
    expect(controller.text, 'Abcdef12!');
  });

  testWidgets('password content remains LTR in Arabic when revealed', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Abcdef12!');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        AuthPasswordField(
          controller: controller,
          label: 'كلمة المرور',
          showPasswordLabel: 'إظهار كلمة المرور',
          hidePasswordLabel: 'إخفاء كلمة المرور',
        ),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('Arabic auth header uses the directional back arrow and label', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        AuthHeader(title: 'تسجيل الدخول', subtitle: 'مرحبًا', onBack: () {}),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('شعار سند'), findsOneWidget);
  });

  testWidgets('auth header supports a compact title and welcome mark', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const AuthHeader(
          title: 'Welcome back',
          subtitle: 'Good to see you again',
          topBarTitle: 'SANAD',
          heroIcon: Icons.monitor_heart_outlined,
          centerTitle: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('SANAD logo'), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
  });

  testWidgets('auth header uses a readable shared title type scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const AuthHeader(
          title: 'Welcome back',
          subtitle: 'Good to see you again',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text('Welcome back')).style?.fontSize, 24);
    expect(
      tester.widget<Text>(find.text('Good to see you again')).style?.fontSize,
      14,
    );
  });

  testWidgets('branded auth header renders the original logo in black', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const AuthHeader(
          title: 'Welcome back',
          subtitle: 'Good to see you again',
          topBarTitle: 'SANAD',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    final logo = tester.widget<Image>(imageFinder);
    expect(
      (logo.image as AssetImage).assetName,
      'assets/images/sanad_logo.png',
    );
    expect(logo.fit, BoxFit.contain);
    expect(logo.width, closeTo(141, 1));
    expect(logo.height, closeTo(141, 1));
    expect(
      tester.widget<OverflowBox>(find.byType(OverflowBox)).alignment,
      const Alignment(0, .08),
    );
    expect(
      find.ancestor(of: imageFinder, matching: find.byType(ClipRect)),
      findsOneWidget,
    );
    expect(logo.color, Colors.black);
    expect(logo.colorBlendMode, BlendMode.srcIn);
    expect(find.text('SANAD'), findsNothing);
    expect(find.bySemanticsLabel('SANAD logo'), findsOneWidget);
  });

  testWidgets('OTP input preserves corrections and moves backward on delete', (
    tester,
  ) async {
    final values = <String>[];
    await tester.pumpWidget(app(OtpInput(onChanged: values.add)));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.byType(EditableText), findsNWidgets(6));
    await tester.tap(find.byKey(const ValueKey('otp-input-0')));
    await tester.enterText(find.byKey(const ValueKey('otp-input-0')), '123456');
    await tester.pump();
    expect(values.last, '123456');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('otp-input-0')), '19');
    await tester.pump();
    expect(values.last, '923456');

    await tester.enterText(find.byKey(const ValueKey('otp-input-5')), '');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('otp-input-5')));
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(values.last, '9234');
  });

  testWidgets('auth button honors compact accessible height', (tester) async {
    await tester.pumpWidget(
      app(const SanadButton(label: 'Continue', onPressed: _noop, height: 50)),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(FilledButton)).height, 50);
  });

  testWidgets('compact labeled field uses readable type and touch height', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      app(
        AuthTextField(
          controller: controller,
          label: 'Email address',
          labelAbove: true,
          compact: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.text('Email address')).style?.fontSize, 14);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).style.fontSize,
      15,
    );
    expect(
      find.descendant(
        of: find.byType(AuthTextField),
        matching: find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 54,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('password requirements use readable supporting text', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        PasswordRequirements(
          validation: PasswordValidation.evaluate('abc'),
          visible: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('At least 9 characters')).style?.fontSize,
      12,
    );
  });

  testWidgets('verification card shows masked value', (tester) async {
    await tester.pumpWidget(
      app(
        const VerificationMethodCard(
          title: 'Email address',
          description: 'Use email',
          valueText: 's***@gmail.com',
          icon: Icons.alternate_email_rounded,
          selected: true,
          available: true,
          onTap: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(VerificationMethodCard),
        matching: find.text('s***@gmail.com'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('verification card uses readable title and supporting text', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const VerificationMethodCard(
          title: 'Email verification',
          description: 'Use your email address for the verification preview.',
          valueText: 's***@gmail.com',
          icon: Icons.alternate_email_rounded,
          selected: true,
          available: true,
          onTap: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('Email verification')).style?.fontSize,
      14,
    );
    expect(
      tester
          .widget<Text>(
            find.text('Use your email address for the verification preview.'),
          )
          .style
          ?.fontSize,
      12,
    );
  });

  testWidgets('OTP cells fit a narrow phone content width', (tester) async {
    const size = Size(260, 180);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const OtpInput(onChanged: _ignoreCode)));
    await tester.pumpAndSettle();

    for (var index = 0; index < 6; index++) {
      final cell = tester.getRect(find.byKey(ValueKey('otp-cell-$index')));
      expect(cell.left, greaterThanOrEqualTo(0));
      expect(cell.right, lessThanOrEqualTo(size.width));
    }
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

void _ignoreCode(String _) {}
