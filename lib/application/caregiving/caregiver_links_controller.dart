import 'package:flutter/foundation.dart';
import '../../data/network/api_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/caregiver_link.dart';
import '../../domain/models/user_role.dart';
import '../auth/auth_service.dart';
import 'caregiver_links_service.dart';

final class CaregiverLinksController extends ChangeNotifier {
  CaregiverLinksController(this.auth)
    : service = CaregiverLinksService(auth.api) {
    auth.addListener(_authChanged);
  }
  final AuthService auth;
  CaregiverLinksService service;
  AppUser? profile;
  List<CaregiverLink> links = const [];
  PublicLinkUser? confirmation;
  int occupied = 0;
  int _page = 1, _lastPage = 1, _generation = 0, _lookupGeneration = 0;
  String? _token;
  String? errorCode;
  bool loading = false, busy = false, searching = false, history = false;
  bool needsReconciliation = false,
      sessionExpired = false,
      actionCompleted = false;
  bool _disposed = false;
  bool get isPatient => profile?.role == UserRole.patient;
  bool get hasMore => _page < _lastPage;
  bool get canMutate =>
      !loading &&
      !busy &&
      !needsReconciliation &&
      profile != null &&
      !sessionExpired;

  Future<void> initialize() async {
    loading = true;
    _notify();
    final generation = _generation;
    try {
      _token = (await auth.tokens.read())?.value;
      service = CaregiverLinksService(auth.api, expectedToken: _token);
      final user = await auth.getCurrentUserProfile();
      if (_disposed || generation != _generation) return;
      if (user == null) {
        _invalidate(expired: true);
        return;
      }
      profile = user;
      if (!await _current(generation)) return;
      await _load();
    } on ApiException catch (e) {
      await _failure(e, generation);
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> refresh() async {
    if (loading || busy || _disposed) return;
    if (profile == null) {
      await initialize();
      return;
    }
    loading = true;
    _notify();
    try {
      await _load();
    } finally {
      if (!_disposed) {
        loading = false;
        _notify();
      }
    }
  }

  Future<bool> _load({bool more = false}) async {
    final generation = _generation;
    if (!await _current(generation)) return false;
    try {
      final result = await service.list(
        page: more ? _page + 1 : 1,
        history: history,
      );
      if (!await _current(generation)) return false;
      links = List.unmodifiable(
        more
            ? {
                ...{for (final l in links) l.id: l},
                ...{for (final l in result.links) l.id: l},
              }.values
            : result.links,
      );
      occupied = result.occupied ?? 0;
      _page = result.page;
      _lastPage = result.lastPage;
      if (!more) needsReconciliation = false;
      errorCode = null;
      return true;
    } on ApiException catch (e) {
      await _failure(e, generation);
      return false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || loading || busy) return;
    if (needsReconciliation) {
      await refresh();
      return;
    }
    loading = true;
    _notify();
    try {
      await _load(more: true);
    } finally {
      if (!_disposed) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> showHistory(bool value) async {
    if (loading || busy || history == value) return;
    history = value;
    links = const [];
    clearConfirmation();
    await refresh();
  }

  void clearConfirmation() {
    _lookupGeneration++;
    confirmation = null;
    searching = false;
    actionCompleted = false;
    _notify();
  }

  Future<void> lookup(String username) async {
    if (!isPatient || !canMutate || occupied >= 3) return;
    final search = ++_lookupGeneration;
    final generation = _generation;
    confirmation = null;
    errorCode = null;
    searching = true;
    actionCompleted = false;
    _notify();
    try {
      if (!await _current(generation)) return;
      final result = await service.lookup(username);
      if (await _current(generation) && search == _lookupGeneration) {
        confirmation = result;
      }
    } on ApiException catch (e) {
      if (search == _lookupGeneration) await _failure(e, generation);
    } finally {
      if (!_disposed && search == _lookupGeneration) {
        searching = false;
        _notify();
      }
    }
  }

  Future<void> invite() async {
    final target = confirmation;
    if (!isPatient || target == null || occupied >= 3) return;
    await _mutate(() => service.invite(target.username));
  }

  Future<void> transition(CaregiverLink link, String action) =>
      _mutate(() => service.transition(link, action));

  Future<void> _mutate(Future<CaregiverLink> Function() operation) async {
    if (!canMutate) return;
    final generation = _generation;
    if (!await _current(generation)) return;
    // Recheck after asynchronous token access so double taps cannot queue writes.
    if (!canMutate) return;
    busy = true;
    errorCode = null;
    actionCompleted = false;
    confirmation = null;
    _lookupGeneration++;
    _notify();
    String? operationError;
    try {
      await operation();
      if (!await _current(generation)) return;
      needsReconciliation = true;
      actionCompleted = true;
    } on ApiException catch (e) {
      if (!await _current(generation)) return;
      operationError = e.code;
      needsReconciliation = true;
    } finally {
      if (!_disposed && generation == _generation) {
        if (needsReconciliation) await _load();
        if (!_disposed && generation == _generation) {
          if (operationError != null && errorCode == null) {
            errorCode = operationError;
          }
          busy = false;
          _notify();
        }
      }
    }
  }

  Future<bool> _current(int generation) async {
    if (_disposed || generation != _generation) return false;
    final token = (await auth.tokens.read())?.value;
    if (_disposed || generation != _generation) return false;
    if (token != _token || token == null) {
      _invalidate(expired: token == null);
      if (token == null) await auth.restoreCurrentUser();
      return false;
    }
    return true;
  }

  Future<void> _failure(ApiException error, int generation) async {
    if (!await _current(generation)) return;
    if (['unauthenticated', 'token-expired'].contains(error.code)) {
      _invalidate(expired: true);
      return;
    }
    errorCode = error.code;
  }

  void _authChanged() {
    if (profile != null && auth.currentUser?.uid != profile!.uid) {
      _invalidate(expired: auth.currentUser == null);
    }
  }

  void _invalidate({required bool expired}) {
    _generation++;
    _lookupGeneration++;
    links = const [];
    confirmation = null;
    profile = null;
    occupied = 0;
    loading = false;
    busy = false;
    searching = false;
    sessionExpired = expired;
    errorCode = expired ? 'unauthenticated' : 'session-changed';
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
