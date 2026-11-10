import 'package:flutter/foundation.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_config.dart';
import '../../data/storage/secure_token_store.dart';
import '../../data/models/auth_session.dart';
import '../../data/mappers/laravel_registration_mapper.dart';
import '../../data/mappers/laravel_user_mapper.dart';
import '../../data/network/api_exception.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/otp_attempt.dart';
import '../../domain/models/otp_dispatch.dart';
import '../../domain/models/otp_proof.dart';
import '../../domain/models/registration_data.dart';
import '../../domain/models/auth_json.dart';
import '../../domain/repositories/token_store.dart';
import 'laravel_login_service.dart';

/// App-owned facade. Laravel remains the only authority for migrated flows.
class AuthService extends ChangeNotifier {
  AuthService({required this.api, required TokenStore tokenStore})
    : tokens = tokenStore,
      login = LaravelLoginService(api: api, tokenStore: tokenStore);
  factory AuthService.local() {
    final tokens = SecureTokenStore();
    return AuthService(
      api: ApiClient(config: ApiConfig.fromEnvironment(), tokenStore: tokens),
      tokenStore: tokens,
    );
  }
  final ApiClient api;
  final TokenStore tokens;
  final LaravelLoginService login;
  AppUser? _user;
  OtpAttempt? _signup;
  OtpProof? _signupProof;
  OtpAttempt? _recovery;
  OtpProof? _resetProof;
  bool _busy = false;
  bool get isBusy => _busy || login.isBusy;
  AppUser? get currentUser => _user;
  bool get hasPendingSignup => _signup != null;
  bool get hasPendingRecovery => _recovery != null;
  bool get hasVerifiedRecovery => _recovery != null && _resetProof != null;

  /// UI hint only; the server still decides whether verification is valid.
  bool attemptExpired({required bool loginFlow}) {
    final expiry = loginFlow
        ? login.pendingAttempt?.expiresAt
        : _signup?.expiresAt;
    return expiry != null && !expiry.isAfter(DateTime.now());
  }

  Future<OtpAttempt> startLogin({
    required String email,
    required String password,
    required String language,
  }) => _run(
    () => login.start(email: email, password: password, language: language),
  );
  Future<OtpDispatch> sendLoginOtp() => _run(() => login.sendOtp());
  Future<AppUser> verifyLoginOtp(String code) => _run(() async {
    final user = await login.verifyOtp(code);
    _user = user;
    notifyListeners();
    return user;
  });
  Future<T> _run<T>(Future<T> Function() operation) async {
    if (isBusy) throw ApiException(code: 'auth-operation-in-progress');
    _busy = true;
    try {
      return await operation();
    } on FormatException {
      throw ApiException(code: 'invalid-response');
    } finally {
      _busy = false;
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? response, String code) {
    if (response?['code'] != code ||
        response?['data'] is! Map<String, dynamic>) {
      throw ApiException(code: 'invalid-response');
    }
    return response!['data'] as Map<String, dynamic>;
  }

  Future<bool> _available(String field, String value) async {
    final response = await api.post(
      '/api/auth/availability/$field',
      body: {field: value.trim()},
    );
    final data = _data(response, 'availability-checked');
    if (data['available'] is! bool) {
      throw ApiException(code: 'invalid-response');
    }
    return data['available'] as bool;
  }

  Future<bool> isEmailAvailable(String email) =>
      _available('email', email.toLowerCase());
  Future<bool> isUsernameAvailable(String username) =>
      _available('username', username);
  Future<OtpAttempt> startSignup(
    RegistrationData data, {
    required String passwordConfirmation,
    required String language,
  }) => _run(() async {
    _signup = null;
    _signupProof = null;
    final response = await api.post(
      '/api/auth/signup/start',
      body: {
        ...LaravelRegistrationMapper.toJson(
          data,
          passwordConfirmation: passwordConfirmation,
        ),
        'language': language,
      },
    );
    final attempt = OtpAttempt.fromJson(_data(response, 'signup-started'));
    if (attempt.purpose != OtpPurpose.signup) {
      throw ApiException(code: 'invalid-response');
    }
    _signup = attempt;
    return attempt;
  });
  Future<OtpDispatch> sendSignupOtp() => _run(() async {
    final attempt = _signup;
    if (attempt == null || _signupProof != null) {
      throw ApiException(code: 'invalid-challenge');
    }
    final sent = OtpDispatch.fromJson(
      _data(
        await api.post('/api/auth/otp/send', body: attempt.toRequest()),
        'otp-sent',
      ),
    );
    if (sent.attemptId != attempt.id) {
      throw ApiException(code: 'invalid-response');
    }
    return sent;
  });
  Future<AppUser> verifySignupOtp(String code) => _run(() async {
    final attempt = _signup;
    if (attempt == null) throw ApiException(code: 'invalid-challenge');
    try {
      _signupProof ??= OtpProof.fromJson(
        _data(
          await api.post(
            '/api/auth/otp/verify',
            body: {...attempt.toRequest(), 'purpose': 'signup', 'code': code},
          ),
          'signup-verified',
        ),
        purpose: OtpPurpose.signup,
      );
      final response = await api.post(
        '/api/auth/register',
        body: {
          ...attempt.toRequest(),
          'verification_proof': _signupProof!.value,
        },
      );
      _signup = null;
      _signupProof = null;
      return await _accept(_data(response, 'registered'));
    } on ApiException catch (error) {
      if ([
            'invalid-challenge',
            'challenge-used',
            'account-changed',
            'email-already-in-use',
            'username-taken',
          ].contains(error.code) ||
          (error.code == 'otp-expired' && _signupProof != null) ||
          error.fieldCodes.values
              .expand((v) => v)
              .any(
                (c) => c == 'email-already-in-use' || c == 'username-taken',
              )) {
        _signup = null;
        _signupProof = null;
      }
      rethrow;
    }
  });
  Future<AppUser> _accept(Map<String, dynamic> data) async {
    final session = AuthSession.fromJson(data);
    if (!session.user.hasCompleteRegistrationProfile ||
        session.token.isExpired(DateTime.now())) {
      throw ApiException(code: 'invalid-response');
    }
    await tokens.save(session.token);
    _user = session.user;
    notifyListeners();
    return session.user;
  }

  void discardSignup() {
    if (isBusy) return;
    _signup = null;
    _signupProof = null;
  }

  Future<bool> checkRecoveryEligibility(String email) => _run(() async {
    final data = _data(
      await api.post(
        '/api/auth/password/eligibility',
        body: {'email': email.trim().toLowerCase()},
      ),
      'recovery-eligibility-checked',
    );
    if (data['eligible'] is! bool) throw ApiException(code: 'invalid-response');
    return data['eligible'] as bool;
  });

  Future<OtpAttempt> startRecovery(
    String email, {
    required String language,
    required String phoneNumber,
  }) => _run(() async {
    _recovery = null;
    _resetProof = null;
    final data = _data(
      await api.post(
        '/api/auth/password/forgot',
        body: {
          'email': email.trim().toLowerCase(),
          'language': language,
          'phone_number': phoneNumber.trim(),
        },
      ),
      'password-recovery-started',
    );
    if (data['recovery_confirmed'] != true) {
      throw ApiException(code: 'invalid-response');
    }
    final attempt = OtpAttempt.fromJson(data);
    if (attempt.purpose != OtpPurpose.passwordReset) {
      throw ApiException(code: 'invalid-response');
    }
    _recovery = attempt;
    return attempt;
  });
  Future<DateTime> sendRecoveryOtp() => _run(() async {
    final attempt = _recovery;
    if (attempt == null || _resetProof != null) {
      throw ApiException(code: 'invalid-challenge');
    }
    final data = _data(
      await _recoveryRequest(
        '/api/auth/password/otp/send',
        attempt.toRequest(),
      ),
      'recovery-request-accepted',
    );
    if (data['authenticated'] != false ||
        data['attempt_id'] != attempt.id ||
        data['recovery_confirmed'] != true) {
      throw ApiException(code: 'invalid-response');
    }
    return authTimestamp(data['resend_at']);
  });
  Future<void> verifyRecoveryOtp(String code) => _run(() async {
    final attempt = _recovery;
    if (attempt == null) throw ApiException(code: 'invalid-challenge');
    _resetProof = OtpProof.fromJson(
      _data(
        await _recoveryRequest('/api/auth/password/otp/verify', {
          ...attempt.toRequest(),
          'code': code,
        }),
        'password-recovery-verified',
      ),
      purpose: OtpPurpose.passwordReset,
    );
  });
  Future<void> resetPassword(String password, String confirmation) =>
      _run(() async {
        final attempt = _recovery;
        final proof = _resetProof;
        if (attempt == null || proof == null) {
          throw ApiException(code: 'invalid-challenge');
        }
        final data = _data(
          await _recoveryRequest('/api/auth/password/reset', {
            ...attempt.toRequest(),
            'reset_proof': proof.value,
            'password': password,
            'password_confirmation': confirmation,
          }),
          'password-reset',
        );
        if (data['authenticated'] != false || data['login_required'] != true) {
          throw ApiException(code: 'invalid-response');
        }
        _recovery = null;
        _resetProof = null;
        _user = null;
        notifyListeners();
        await tokens.clear();
      });
  void discardRecovery() {
    if (isBusy) return;
    _recovery = null;
    _resetProof = null;
  }

  Future<Map<String, dynamic>?> _recoveryRequest(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      return await api.post(path, body: body);
    } on ApiException catch (error) {
      if ([
        'invalid-challenge',
        'challenge-used',
        'account-changed',
        'otp-expired',
        'recovery-not-eligible',
      ].contains(error.code)) {
        _recovery = null;
        _resetProof = null;
      }
      rethrow;
    }
  }

  Future<AppUser?> restoreCurrentUser() => _run(() async {
    final token = await tokens.read();
    if (token == null) {
      _user = null;
      notifyListeners();
      return null;
    }
    try {
      final data = _data(
        await api.get('/api/user', authenticated: true),
        'user-retrieved',
      );
      if (data['user'] is! Map<String, dynamic>) {
        throw ApiException(code: 'invalid-response');
      }
      final user = LaravelUserMapper.fromJson(
        data['user'] as Map<String, dynamic>,
      );
      if (!user.hasCompleteRegistrationProfile) {
        throw ApiException(code: 'profile-incomplete');
      }
      if ((await tokens.read())?.value != token.value) {
        throw ApiException(code: 'session-changed');
      }
      _user = user;
      notifyListeners();
      return user;
    } catch (error) {
      _user = null;
      notifyListeners();
      if (error is ApiException &&
          ['unauthenticated', 'token-expired'].contains(error.code)) {
        return null;
      }
      rethrow;
    }
  });
  Future<AppUser?> getCurrentUserProfile() => restoreCurrentUser();
  Future<void> signOut() => _run(() async {
    final token = await tokens.read();
    if (token != null) {
      try {
        final result = await api.post(
          '/api/auth/logout',
          body: {},
          authenticated: true,
        );
        if (result != null) throw ApiException(code: 'invalid-response');
      } on ApiException catch (error) {
        if (!['unauthenticated', 'token-expired'].contains(error.code)) rethrow;
      }
      _user = null;
      notifyListeners();
      await tokens.clearIfMatches(token);
    }
    _user = null;
    _signup = null;
    _signupProof = null;
    _recovery = null;
    _resetProof = null;
    login.discardPendingAttempt();
    notifyListeners();
  });
  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}
