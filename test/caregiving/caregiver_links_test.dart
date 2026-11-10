import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sanad/application/caregiving/caregiver_links_controller.dart';
import 'package:sanad/application/caregiving/caregiver_links_service.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import '../support/laravel_auth_fixture.dart';

Map<String, dynamic> linkJson({
  String status = 'pending',
  String id = '79e6b581-b223-4c55-b180-878f6dbc159a',
  List<String> actions = const ['cancel'],
}) => {
  'id': id,
  'status': status,
  'counterpart': {'name': 'Carer Display', 'username': 'Carer1'},
  'invited_at': '2026-11-08T12:00:00+00:00',
  'accepted_at': null,
  'ended_at': null,
  'allowed_actions': actions,
};
Map<String, dynamic> pageJson({
  List<Map<String, dynamic>>? links,
  int page = 1,
  int lastPage = 1,
  int occupied = 1,
}) => {
  'links': links ?? [linkJson()],
  'pagination': {
    'page': page,
    'per_page': 20,
    'total': lastPage,
    'last_page': lastPage,
  },
  'slots': {'maximum': 3, 'occupied': occupied, 'available': 3 - occupied},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  setUp(() async {
    f = LaravelAuthFixture()..role = 'patient';
    await f.tokens.save(
      SanctumToken(
        value: 'test-session',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
  });
  tearDown(() => f.close());

  test(
    'uses existing authenticated transport, structured query and stable errors',
    () async {
      f.override = (request) async {
        expect(request.headers['Authorization'], 'Bearer test-session');
        if (request.method == 'GET') {
          expect(request.url.queryParameters, {
            'page': '2',
            'per_page': '20',
            'status': 'all',
          });
          return f.response(
            'caregiver-links-listed',
            pageJson(page: 2, lastPage: 2),
          );
        }
        expect(jsonDecode(request.body), {'caregiver_username': 'Carer1'});
        return http.Response(jsonEncode({'code': 'caregiver-slots-full'}), 409);
      };
      final service = CaregiverLinksService(f.api);
      final page = await service.list(page: 2, history: true);
      expect(page.occupied, 1);
      expect(page.links.single.counterpart.username, 'Carer1');
      await expectLater(
        service.invite('Carer1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'caregiver-slots-full',
          ),
        ),
      );
    },
  );

  test(
    'controller confirms lookup, refreshes mutations and loads history pages',
    () async {
      var invited = false;
      f.override = (r) async {
        if (r.url.path == '/api/user') {
          return f.response('user-retrieved', {'user': f.user});
        }
        if (r.url.path.endsWith('/lookup')) {
          return f.response('caregiver-found', {
            'caregiver': {'name': 'Carer Display', 'username': 'Carer1'},
          });
        }
        if (r.method == 'POST') {
          invited = true;
          return f.response('caregiver-invitation-created', {
            'link': linkJson(),
          }, 201);
        }
        final history = r.url.queryParameters['status'] == 'all';
        final page = int.parse(r.url.queryParameters['page']!);
        return f.response(
          'caregiver-links-listed',
          pageJson(
            links: invited
                ? [
                    linkJson(
                      id: page == 2
                          ? '89e6b581-b223-4c55-b180-878f6dbc159a'
                          : '79e6b581-b223-4c55-b180-878f6dbc159a',
                      status: history && page == 2 ? 'cancelled' : 'pending',
                    ),
                  ]
                : [],
            page: page,
            lastPage: history ? 2 : 1,
            occupied: invited ? 1 : 0,
          ),
        );
      };
      final c = CaregiverLinksController(f.auth);
      addTearDown(c.dispose);
      await c.initialize();
      expect(c.isPatient, isTrue);
      await c.lookup('Carer1');
      expect(c.confirmation?.name, 'Carer Display');
      await c.invite();
      expect(c.confirmation, isNull);
      expect(c.occupied, 1);
      expect(c.links.single.status.name, 'pending');
      await c.showHistory(true);
      await c.loadMore();
      expect(c.links.length, 2);
      expect(c.links.last.status.name, 'cancelled');
    },
  );

  test(
    'uncertain mutation blocks retry until a successful reconciliation',
    () async {
      var offline = false;
      var writes = 0;
      f.override = (r) async {
        if (r.url.path == '/api/user') {
          return f.response('user-retrieved', {'user': f.user});
        }
        if (r.url.path.endsWith('/lookup')) {
          return f.response('caregiver-found', {
            'caregiver': {'name': 'Carer Display', 'username': 'Carer1'},
          });
        }
        if (r.method == 'POST') {
          writes++;
          offline = true;
          throw http.ClientException('offline');
        }
        if (offline) throw http.ClientException('offline');
        return f.response(
          'caregiver-links-listed',
          pageJson(links: [], occupied: 0),
        );
      };
      final c = CaregiverLinksController(f.auth);
      addTearDown(c.dispose);
      await c.initialize();
      await c.lookup('Carer1');
      await c.invite();
      expect(c.needsReconciliation, isTrue);
      await c.invite();
      expect(writes, 1);
      offline = false;
      await c.refresh();
      expect(c.needsReconciliation, isFalse);
    },
  );

  test('expired session clears private state', () async {
    var expire = false;
    f.override = (r) async {
      if (expire) return http.Response('{"code":"unauthenticated"}', 401);
      if (r.url.path == '/api/user') {
        return f.response('user-retrieved', {'user': f.user});
      }
      return f.response('caregiver-links-listed', pageJson());
    };
    final c = CaregiverLinksController(f.auth);
    addTearDown(c.dispose);
    await c.initialize();
    expect(c.links, isNotEmpty);
    expire = true;
    await c.refresh();
    expect(c.sessionExpired, isTrue);
    expect(c.links, isEmpty);
    expect(await f.tokens.read(), isNull);
  });

  test(
    'loading another page cannot reconcile an uncertain earlier mutation',
    () async {
      f.role = 'caregiver';
      var uncertain = false;
      final pages = <int>[];
      f.override = (r) async {
        if (r.url.path == '/api/user') {
          return f.response('user-retrieved', {'user': f.user});
        }
        if (r.method == 'POST') {
          uncertain = true;
          throw http.ClientException('lost response after commit');
        }
        final page = int.parse(r.url.queryParameters['page']!);
        pages.add(page);
        if (uncertain && page == 1) {
          throw http.ClientException('refresh offline');
        }
        return f.response(
          'caregiver-links-listed',
          pageJson(
            links: [
              linkJson(actions: ['accept', 'decline']),
            ],
            page: page,
            lastPage: 2,
          ),
        );
      };
      final c = CaregiverLinksController(f.auth);
      addTearDown(c.dispose);
      await c.initialize();
      await c.transition(c.links.single, 'accept');
      expect(c.needsReconciliation, isTrue);
      await c.loadMore();
      expect(c.needsReconciliation, isTrue);
      expect(c.canMutate, isFalse);
      expect(pages, everyElement(1));
    },
  );

  test(
    'session-bound service never dispatches under a replacement account token',
    () async {
      var writes = 0;
      f.override = (r) async {
        writes++;
        return f.response('caregiver-invitation-created', {
          'link': linkJson(),
        }, 201);
      };
      final service = CaregiverLinksService(
        f.api,
        expectedToken: 'test-session',
      );
      await f.tokens.save(
        SanctumToken(
          value: 'replacement-session',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await expectLater(
        service.invite('Carer1'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'session-changed'),
        ),
      );
      expect(writes, 0);
      expect((await f.tokens.read())?.value, 'replacement-session');
    },
  );

  test(
    'stale lookup cannot repopulate after input changes or token replacement',
    () async {
      final response = Completer<http.Response>();
      f.override = (r) async {
        if (r.url.path == '/api/user') {
          return f.response('user-retrieved', {'user': f.user});
        }
        if (r.url.path.endsWith('/lookup')) return response.future;
        return f.response('caregiver-links-listed', pageJson());
      };
      final c = CaregiverLinksController(f.auth);
      addTearDown(c.dispose);
      await c.initialize();
      final lookup = c.lookup('Carer1');
      await Future<void>.delayed(Duration.zero);
      c.clearConfirmation();
      await f.tokens.save(
        SanctumToken(
          value: 'other-session',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      response.complete(
        f.response('caregiver-found', {
          'caregiver': {'name': 'Carer Display', 'username': 'Carer1'},
        }),
      );
      await lookup;
      expect(c.confirmation, isNull);
      expect(c.links, isEmpty);
      expect((await f.tokens.read())?.value, 'other-session');
    },
  );
}
