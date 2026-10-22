import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanad/core/localization/locale_controller.dart';
import 'package:sanad/core/localization/locale_scope.dart';
import 'package:sanad/main.dart';
import 'package:sanad/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:sanad/presentation/screens/role_selection/role_selection_screen.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/widgets/shared_widgets/sanad_button.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // The welcome watch animates continuously; advance finite transitions explicitly.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
  }

  Future<void> openOnboarding(
    WidgetTester tester, {
    LocaleController? controller,
  }) async {
    await tester.pumpWidget(
      LocaleScope(
        controller: controller ?? LocaleController(),
        child: const SanadApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await settle(tester);
  }

  testWidgets(
    'welcome watch has a live heart and rotating orbit without badges',
    (tester) async {
      await openOnboarding(tester);
      expect(find.text('Always by your side'), findsNothing);
      expect(find.text('A little more peace of mind'), findsNothing);
      final orbit = find.byKey(const ValueKey('watch-orbit-rotation')).first;
      final heart = find.byKey(const ValueKey('watch-heartbeat'));
      final before = tester.widget<Transform>(orbit).transform.clone();
      await tester.pump(const Duration(milliseconds: 150));
      final after = tester.widget<Transform>(orbit).transform;
      expect(after, isNot(before));
      final angleBefore = math.atan2(before.entry(1, 0), before.entry(0, 0));
      final angleAfter = math.atan2(after.entry(1, 0), after.entry(0, 0));
      expect(angleAfter - angleBefore, closeTo(2 * math.pi * .150 / 30, .001));
      final scales = <double>[];
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        scales.add(tester.widget<Transform>(heart).transform.entry(0, 0));
      }
      expect(scales.reduce((a, b) => a > b ? a : b), greaterThan(1.05));
      final readings = <String>{};
      for (var i = 0; i < 7; i++) {
        final switcher = tester.widget<AnimatedSwitcher>(
          find.byKey(const ValueKey('watch-bpm')),
        );
        readings.add((switcher.child! as Text).data!);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(readings.length, greaterThan(1));
      expect(readings.map(int.parse), everyElement(inInclusiveRange(70, 74)));
      await tester.tap(find.text('Next'));
      await settle(tester);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('first launch is English with a white canvas and Arabic toggle', (
    tester,
  ) async {
    await openOnboarding(tester);
    expect(find.text('Care That Stays With You.'), findsOneWidget);
    expect(find.text('عربي'), findsOneWidget);
    expect(find.text('🇸🇦'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(OnboardingScreen))),
      TextDirection.ltr,
    );
    expect(
      tester
          .widget<Scaffold>(
            find.descendant(
              of: find.byType(OnboardingScreen),
              matching: find.byType(Scaffold),
            ),
          )
          .backgroundColor,
      Colors.white,
    );
    expect(
      find.descendant(
        of: find.byType(SanadButton),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'logo stays centered and header controls swap with the language',
    (tester) async {
      await openOnboarding(tester);
      final logo = find.byKey(const ValueKey('onboarding-logo'));
      final skip = find.byKey(const ValueKey('onboarding-skip'));
      expect(
        (tester.widget<Image>(logo).image as AssetImage).assetName,
        'assets/images/sanad_logo.png',
      );
      final center = tester.getCenter(find.byType(OnboardingScreen)).dx;
      expect(tester.getCenter(logo).dx, closeTo(center, .1));
      expect(tester.getCenter(find.text('عربي')).dx, greaterThan(center));
      expect(tester.getCenter(skip).dx, lessThan(center));
      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('عربي'));
      await settle(tester);
      expect(tester.getCenter(logo).dx, closeTo(center, .1));
      expect(tester.getCenter(find.text('English')).dx, lessThan(center));
      expect(tester.getCenter(skip).dx, greaterThan(center));
      expect(find.text('تخطي'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(OnboardingScreen))),
        TextDirection.rtl,
      );
      expect(
        Theme.of(
          tester.element(find.byType(OnboardingScreen)),
        ).textTheme.bodyMedium?.fontFamily,
        'Tajawal',
      );
      await tester.tap(skip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
    },
  );

  testWidgets('language persists and switches without resetting the page', (
    tester,
  ) async {
    await openOnboarding(tester);
    await tester.tap(find.text('Next'));
    await settle(tester);
    await tester.tap(find.text('عربي'));
    await settle(tester);
    expect(find.text('صحتك تحت المتابعة دائمًا.'), findsOneWidget);
    final controller = LocaleController();
    await controller.load();
    expect(controller.locale.languageCode, 'ar');
    await tester.tap(find.text('English'));
    await settle(tester);
    expect(find.text('Your Health, Always in View.'), findsOneWidget);
    expect(
      Theme.of(
        tester.element(find.byType(OnboardingScreen)),
      ).textTheme.bodyMedium?.fontFamily,
      'Poppins',
    );
  });

  testWidgets(
    'Next traverses onboarding and continues through role selection',
    (tester) async {
      await openOnboarding(tester);
      for (var page = 1; page < 5; page++) {
        await tester.tap(find.text('Next'));
        await settle(tester);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      final caregiver = find.byKey(const ValueKey('role-option-caregiver'));
      await tester.ensureVisible(caregiver);
      await tester.tap(caregiver);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Continue'));
      await settle(tester);
      expect(
        tester.widget<LoginScreen>(find.byType(LoginScreen)).arguments.role,
        UserRole.caregiver,
      );
    },
  );

  testWidgets(
    'feature entrance animates and swipe can return to a previous page',
    (tester) async {
      await openOnboarding(tester);
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      final feature = find.byKey(
        const ValueKey('onboarding-feature-monitoring'),
      );
      final initial = tester.widget<Opacity>(feature).opacity;
      expect(initial, lessThan(1));
      await settle(tester);
      expect(tester.widget<Opacity>(feature).opacity, 1);
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await settle(tester);
      expect(find.text('Care That Stays With You.'), findsOneWidget);
    },
  );

  testWidgets('reduced motion shows content immediately and jumps pages', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await openOnboarding(tester);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump();
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('onboarding-feature-monitoring')),
          )
          .opacity,
      1,
    );
    await settle(tester);
  });

  testWidgets(
    'all five scenes fit small, standard, and large phones in both languages',
    (tester) async {
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(440, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await openOnboarding(tester);
        for (var page = 1; page <= 5; page++) {
          for (final target in ['ar', 'en']) {
            await tester.tap(find.byKey(ValueKey('language-option-$target')));
            await settle(tester);
            expect(
              tester.takeException(),
              isNull,
              reason: '$size page $page language $target',
            );
          }
          if (page < 5) {
            await tester.tap(find.text('Next'));
            await settle(tester);
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}
