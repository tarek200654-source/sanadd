import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
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
        await tester.pumpAndSettle();
        final labels = language == 'ar'
            ? ['اليوم', 'النشاط', 'الصحة', 'الاتجاهات']
            : ['Today', 'Activity', 'Health', 'Insights'];
        for (var tab = 0; tab < 4; tab++) {
          await tester.tap(find.text(labels[tab]).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('test@example.com'), findsOneWidget);
      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();
      expect(auth.signedOut, isTrue);
      expect(find.text('Splash after sign out'), findsOneWidget);
    },
  );
}
