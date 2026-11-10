import '../../data/models/auth_session.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/otp_attempt.dart';
import '../../domain/models/otp_dispatch.dart';
import '../../domain/repositories/token_store.dart';

/// Explicitly injected, inactive until UI migration. Never falls back to Firebase.
/// Share one instance per login flow and use the same TokenStore as ApiClient.
final class LaravelLoginService {
  LaravelLoginService({
    required ApiClient api,
    required TokenStore tokenStore,
    DateTime Function()? now,
  }) : _api = api,
       _tokens = tokenStore,
       _now = now ?? DateTime.now;

  final ApiClient _api;
  final TokenStore _tokens;
  final DateTime Function() _now;
  OtpAttempt? _pending;
  bool _busy = false;

  /// Sensitive credentials: memory-only; do not put this value in route storage.
  OtpAttempt? get pendingAttempt => _pending;
  bool get isBusy => _busy;

  Future<OtpAttempt> start({
    required String email,
    required String password,
    String language = 'en',
  }) => _exclusive(() async {
    // A failed replacement must not leave the previous account's attempt active.
    _pending = null;
    final response = await _api.post(
      '/api/auth/login/start',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'language': language,
      },
    );
    final data = _data(response, 'login-started');
    final attempt = OtpAttempt.fromJson(data);
    if (attempt.purpose != OtpPurpose.login || data['otp_started'] != false) {
      throw ApiException(code: 'invalid-response');
    }
    _pending = attempt;
    return attempt;
  });

  Future<OtpDispatch> sendOtp() => _exclusive(() async {
    final attempt = _requireAttempt();
    final response = await _pendingPost(
      '/api/auth/otp/send',
      attempt.toRequest(),
    );
    final delivery = OtpDispatch.fromJson(_data(response, 'otp-sent'));
    if (delivery.attemptId != attempt.id) {
      throw ApiException(code: 'invalid-response');
    }
    return delivery;
  });

  Future<AppUser> verifyOtp(String code) => _exclusive(() async {
    final attempt = _requireAttempt();
    final response = await _pendingPost('/api/auth/otp/verify', {
      ...attempt.toRequest(),
      'purpose': OtpPurpose.login.value,
      'code': code,
    }, consumesAttempt: true);
    // A successful HTTP response may have consumed the one-use server challenge.
    // Retire it even if decoding/persistence fails; do not repeat verification.
    _pending = null;
    final session = AuthSession.fromJson(_data(response, 'authenticated'));
    if (!session.user.hasCompleteRegistrationProfile ||
        session.token.isExpired(_now())) {
      throw ApiException(code: 'invalid-response');
    }
    await _tokens.save(session.token);
    return session.user;
  });

  /// Abandon only pending login; this is not logout and never touches storage.
  /// Await the active operation before discarding or starting a different flow.
  void discardPendingAttempt() {
    _ensureIdle();
    _pending = null;
  }

  OtpAttempt _requireAttempt() {
    final attempt = _pending;
    if (attempt == null) throw ApiException(code: 'invalid-challenge');
    return attempt;
  }

  Future<Map<String, dynamic>?> _pendingPost(
    String path,
    Map<String, dynamic> body, {
    bool consumesAttempt = false,
  }) async {
    try {
      return await _api.post(path, body: body);
    } on ApiException catch (error) {
      if ([
            'invalid-challenge',
            'account-changed',
            'challenge-used',
          ].contains(error.code) ||
          (consumesAttempt && error.code == 'invalid-response')) {
        _pending = null;
      }
      // Keep attempts on transient failures; let the server enforce OTP limits.
      rethrow;
    }
  }

  static Map<String, dynamic> _data(
    Map<String, dynamic>? response,
    String code,
  ) {
    if (response?['code'] != code ||
        response?['data'] is! Map<String, dynamic>) {
      throw ApiException(code: 'invalid-response');
    }
    return response!['data'] as Map<String, dynamic>;
  }

  void _ensureIdle() {
    if (_busy) throw ApiException(code: 'auth-operation-in-progress');
  }

  Future<T> _exclusive<T>(Future<T> Function() operation) async {
    _ensureIdle();
    _busy = true;
    try {
      return await operation();
    } on FormatException {
      throw ApiException(code: 'invalid-response');
    } finally {
      _busy = false;
    }
  }
}
