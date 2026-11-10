import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import 'package:sanad/presentation/widgets/home_widgets/sanad_bottom_navigation.dart';
import 'dashboard_fixture.dart';

Widget app(String language, DashboardTestAuth auth, {double scale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppColor.theme(isArabic: language == 'ar'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      initialRoute: '/home',
      routes: {
        '/': (_) => const Scaffold(body: Text('Splash after sign out')),
        '/home': (_) => HomeScreen(authService: auth),
      },
    );
void main() {
  testWidgets(
    'floating dock overlays the viewport and leaves the final content visible',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(app('en', DashboardTestAuth()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('nav-profile')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final scroll = find.byType(SingleChildScrollView).first;
      final dock = find.byType(SanadBottomNavigation);
      expect(tester.getRect(dock).bottom, closeTo(604, .1));
      expect(
        tester.getRect(scroll).bottom,
        greaterThan(tester.getRect(dock).bottom),
      );
      await tester.drag(scroll, const Offset(0, -2000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.getRect(find.text('Test address')).bottom,
        lessThanOrEqualTo(tester.getRect(dock).top - 16),
      );
    },
  );

  testWidgets('selection indicator travels smoothly between destinations', (
    tester,
  ) async {
    await tester.pumpWidget(app('en', DashboardTestAuth()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final indicator = find.byKey(const ValueKey('nav-selection-indicator'));
    final before = tester.getTopLeft(indicator).dx;
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final during = tester.getTopLeft(indicator).dx;
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester.getTopLeft(indicator).dx;
    expect(during, greaterThan(before));
    expect(during, lessThan(after));
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion changes destination without animating the dock', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(app('en', DashboardTestAuth()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pump();
    final indicator = tester.getRect(
      find.byKey(const ValueKey('nav-selection-indicator')),
    );
    final profile = tester.getRect(find.byKey(const ValueKey('nav-profile')));
    expect(indicator.left, closeTo(profile.left, .1));
    expect(find.text('test@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dock has accessible touch targets on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: SanadBottomNavigation(
              selectedIndex: 0,
              isArabic: false,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('bottom navigation opens all five pages including the account', (
    tester,
  ) async {
    await tester.pumpWidget(app('en', DashboardTestAuth()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final profile = find.byKey(const ValueKey('nav-profile'));
    expect(profile, findsOneWidget);
    await tester.tap(profile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('test@example.com'), findsOneWidget);
    expect(tester.widget<Semantics>(profile).properties.selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Your health, at a glance'), findsOneWidget);
    expect(find.text('test@example.com'), findsNothing);
  });
  for (final language in ['en', 'ar']) {
    for (final width in [320.0, 390.0]) {
      testWidgets('complete reference screens fit $language at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(language, DashboardTestAuth(), scale: 1.3));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final destinations = [
          'home',
          'activity',
          'health',
          'insights',
          'profile',
        ];
        for (var tab = 0; tab < destinations.length; tab++) {
          await tester.tap(find.byKey(ValueKey('nav-${destinations[tab]}')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            tester.takeException(),
            isNull,
            reason: 'destination ${destinations[tab]}',
          );
          expect(
            tester
                .widget<Semantics>(
                  find.byKey(ValueKey('nav-${destinations[tab]}')),
                )
                .properties
                .selected,
            isTrue,
          );
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -600),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
  testWidgets(
    'profile retains real account fields and signs out through splash',
    (tester) async {
      final auth = DashboardTestAuth();
      await tester.pumpWidget(app('en', auth));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byTooltip('Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('test@example.com'), findsOneWidget);
      await tester.tap(find.byTooltip('Sign out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(auth.signedOut, isTrue);
      expect(find.text('Splash after sign out'), findsOneWidget);
    },
  );
}
