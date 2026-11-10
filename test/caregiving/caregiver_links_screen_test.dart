import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/presentation/screens/caregiver_links_screen/caregiver_links_screen.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import '../support/laravel_auth_fixture.dart';
import 'caregiver_links_test.dart' show linkJson, pageJson;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  late List<Map<String, dynamic>> links;
  var expire = false;
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    f = LaravelAuthFixture()..role = 'patient';
    links = [];
    expire = false;
    await f.tokens.save(
      SanctumToken(
        value: 'test-session',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    f.override = (r) async {
      if (expire) return http.Response('{"code":"unauthenticated"}', 401);
      if (r.url.path == '/api/user') {
        return f.response('user-retrieved', {'user': f.user});
      }
      if (r.url.path.endsWith('/lookup')) {
        return f.response('caregiver-found', {
          'caregiver': {'name': 'Carer Display', 'username': 'Carer1'},
        });
      }
      if (r.method == 'POST') {
        final action = r.url.path.split('/').last;
        final status = switch (action) {
          'accept' => 'active',
          'decline' => 'declined',
          'cancel' => 'cancelled',
          'revoke' => 'revoked',
          _ => 'pending',
        };
        links = [
          linkJson(
            status: status,
            actions: status == 'active'
                ? ['revoke']
                : status == 'pending'
                ? ['cancel']
                : [],
          ),
        ];
        return f.response(
          action == 'caregiver-links'
              ? 'caregiver-invitation-created'
              : 'caregiver-link-updated',
          {'link': links.single},
          action == 'caregiver-links' ? 201 : 200,
        );
      }
      final history = r.url.queryParameters['status'] == 'all';
      return f.response(
        'caregiver-links-listed',
        pageJson(
          links: links
              .where(
                (l) => history || ['pending', 'active'].contains(l['status']),
              )
              .toList(),
          occupied: links
              .where((l) => ['pending', 'active'].contains(l['status']))
              .length,
        ),
      );
    };
  });
  tearDown(() => f.close());
  Future<void> settle(WidgetTester t) async {
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String key) async {
    final finder = find.byKey(ValueKey(key));
    if (key == 'caregiver-history') {
      await t.drag(find.byType(ListView).first, const Offset(0, 2000));
      await settle(t);
    }
    if (finder.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        finder,
        160,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await t.ensureVisible(finder);
    await settle(t);
    await t.tap(finder);
    await settle(t);
  }

  for (final language in ['en', 'ar']) {
    testWidgets(
      '$language patient confirms caregiver before sending, cancels and opens history',
      (t) async {
        await t.pumpWidget(
          f.app(const CaregiverLinksScreen(), language: language),
        );
        await settle(t);
        expect(
          find.text(language == 'ar' ? 'مقدمو الرعاية' : 'Caregivers'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('caregiver-confirmation')),
          findsNothing,
        );
        await t.enterText(
          find.byKey(const ValueKey('caregiver-username')),
          'Carer1',
        );
        await tap(t, 'caregiver-lookup');
        expect(
          find.byKey(const ValueKey('caregiver-confirmation')),
          findsOneWidget,
        );
        expect(find.text('Carer Display'), findsOneWidget);
        expect(find.text('@Carer1'), findsOneWidget);
        expect(
          f.requests.where(
            (r) => r.method == 'POST' && r.url.path == '/api/caregiver-links',
          ),
          isEmpty,
        );
        await tap(t, 'caregiver-invite');
        expect(
          find.text(language == 'ar' ? 'قيد الانتظار' : 'Pending'),
          findsWidgets,
        );
        await tap(t, 'link-cancel-${links.single['id']}');
        await tap(t, 'caregiver-history');
        expect(
          find.text(language == 'ar' ? 'ملغاة' : 'Cancelled'),
          findsWidgets,
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('caregiver accepts and confirms leaving active relationship', (
    t,
  ) async {
    f.role = 'caregiver';
    links = [
      linkJson(actions: ['accept', 'decline']),
    ];
    await t.pumpWidget(f.app(const CaregiverLinksScreen()));
    await settle(t);
    expect(find.byKey(const ValueKey('caregiver-username')), findsNothing);
    await tap(t, 'link-accept-${links.single['id']}');
    expect(find.text('Active'), findsWidgets);
    await tap(t, 'link-revoke-${links.single['id']}');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(links.single['status'], 'active');
    await tap(t, 'confirm-revoke');
    expect(links.single['status'], 'revoked');
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'short Arabic screen with keyboard and scaled text stays usable',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        f.app(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.4),
              viewInsets: EdgeInsets.only(bottom: 220),
            ),
            child: const CaregiverLinksScreen(),
          ),
          language: 'ar',
        ),
      );
      await settle(t);
      await t.enterText(
        find.byKey(const ValueKey('caregiver-username')),
        'Carer1',
      );
      await tap(t, 'caregiver-lookup');
      expect(find.text('@Carer1'), findsOneWidget);
      expect(t.takeException(), isNull);
      final username = t.widget<Text>(find.text('@Carer1'));
      expect(username.textDirection, TextDirection.ltr);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('expired session leaves protected section', (t) async {
    await t.pumpWidget(f.app(const CaregiverLinksScreen()));
    await settle(t);
    expire = true;
    await tap(t, 'caregiver-refresh');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await f.tokens.read(), isNull);
    await t.pumpWidget(const SizedBox.shrink());
  });

  for (final language in ['en', 'ar']) {
    testWidgets('$language caregiver history exposes every terminal state', (
      t,
    ) async {
      f.role = 'caregiver';
      links = [
        for (final status in ['declined', 'revoked', 'cancelled'])
          linkJson(
            status: status,
            actions: [],
            id:
                '${status == 'declined'
                    ? '79'
                    : status == 'revoked'
                    ? '89'
                    : '99'}e6b581-b223-4c55-b180-878f6dbc159a',
          ),
      ];
      await t.pumpWidget(
        f.app(const CaregiverLinksScreen(), language: language),
      );
      await settle(t);
      await tap(t, 'caregiver-history');
      for (final text
          in language == 'ar'
              ? ['مرفوضة', 'منتهية', 'ملغاة']
              : ['Declined', 'Revoked', 'Cancelled']) {
        final label = find.text(text).first;
        if (label.evaluate().isEmpty) {
          await t.scrollUntilVisible(
            label,
            160,
            scrollable: find.byType(Scrollable).first,
          );
        }
        expect(label, findsOneWidget);
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('full slots disable search and show clear feedback', (t) async {
    links = [
      for (var n = 0; n < 3; n++)
        linkJson(id: '${79 + n}e6b581-b223-4c55-b180-878f6dbc159a'),
    ];
    await t.pumpWidget(f.app(const CaregiverLinksScreen()));
    await settle(t);
    expect(find.text('3 of 3 slots occupied'), findsOneWidget);
    expect(
      t
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('caregiver-lookup')),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('All three slots'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'duplicate conflict refreshes server state and offers localized feedback',
    (t) async {
      final normal = f.override!;
      f.override = (r) async {
        if (r.method == 'POST' && r.url.path == '/api/caregiver-links') {
          links = [linkJson()];
          return http.Response('{"code":"duplicate-live-relationship"}', 409);
        }
        return normal(r);
      };
      await t.pumpWidget(f.app(const CaregiverLinksScreen()));
      await settle(t);
      await t.enterText(
        find.byKey(const ValueKey('caregiver-username')),
        'Carer1',
      );
      await tap(t, 'caregiver-lookup');
      await tap(t, 'caregiver-invite');
      expect(find.textContaining('already have a pending'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('caregiver-confirmation')),
        findsNothing,
      );
      expect(
        f.requests
            .where(
              (r) => r.method == 'GET' && r.url.path == '/api/caregiver-links',
            )
            .length,
        2,
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Home and Profile open same section and preserve five navigation tabs',
    (t) async {
      await t.pumpWidget(f.app(const HomeScreen()));
      await settle(t);
      expect(
        find.byKey(const ValueKey('caregiver-links-entry')),
        findsOneWidget,
      );
      for (final key in [
        'nav-home',
        'nav-activity',
        'nav-health',
        'nav-insights',
        'nav-profile',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      await tap(t, 'caregiver-links-entry');
      expect(find.byType(CaregiverLinksScreen), findsOneWidget);
      await t.pageBack();
      await settle(t);
      await tap(t, 'nav-profile');
      await tap(t, 'caregiver-links-entry');
      expect(find.byType(CaregiverLinksScreen), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
