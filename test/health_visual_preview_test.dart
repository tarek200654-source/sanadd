import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import 'auth/dashboard_fixture.dart';

void main() {
  testWidgets('render complete reference dashboard screens', (tester) async {
    for (final item in {
      'Tajawal': 'assets/fonts/ar/Tajawal-Regular.ttf',
      'Poppins': 'assets/fonts/en/Poppins-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(item.key)..addFont(rootBundle.load(item.value))).load();
    }
    // Use the same system family as iOS when running previews on macOS.
    if (File('/System/Library/Fonts/HelveticaNeue.ttc').existsSync()) {
      await (FontLoader('Helvetica Neue')..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  '/System/Library/Fonts/HelveticaNeue.ttc',
                ).readAsBytesSync(),
              ),
            ),
          ))
          .load();
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final language in ['en', 'ar']) {
      final key = GlobalKey();
      await tester.pumpWidget(
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
          home: RepaintBoundary(
            key: key,
            child: HomeScreen(
              key: ValueKey(language),
              authService: DashboardTestAuth(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
      for (var tab = 0; tab < 4; tab++) {
        if (tab > 0) {
          final labels = language == 'ar'
              ? ['اليوم', 'النشاط', 'الصحة', 'الاتجاهات']
              : ['Today', 'Activity', 'Health', 'Insights'];
          await tester.tap(find.text(labels[tab]).last);
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)),
          );
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(
            'artifacts/reference-dashboard',
          ).create(recursive: true);
          await File(
            'artifacts/reference-dashboard/$language-$tab.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });
}
