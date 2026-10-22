import 'dart:async';

import 'package:flutter/material.dart';

import '../../../application/auth/auth_failure.dart';
import '../../../application/auth/auth_service.dart';
import '../../../application/auth/auth_service_exception.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../data/repositories/wexora_otp_repository.dart';
import '../../../utils/routes.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/otp_verification_screen_widgets/otp_verification_content.dart';
import '../../../presentation/widgets/otp_verification_screen_widgets/otp_verification_header.dart';
import '../../../presentation/widgets/otp_verification_screen_widgets/otp_verification_submit_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.arguments,
    this.repository,
    this.authService,
  });

  static const routeName = '/otp-verification';

  final AuthRouteArguments arguments;
  final OtpVerificationRepository? repository;
  final AuthService? authService;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';
  String? _errorText;
  late final _otpRepository = widget.repository ?? WexoraOtpRepository();
  late final _authService = widget.authService ?? AuthService.firebase();
  bool _busy = false;
  bool _sending = false;
  bool _verified = false;
  int _inputRevision = 0;
  String? _challengeId;
  DateTime? _expiresAt;
  DateTime? _resendAt;
  String? _statusText;
  String? _lastSendFailure;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  Future<void> _sendCode() async {
    final phone = widget.arguments.phoneNumber;
    if (phone == null || phone.isEmpty) {
      setState(() => _errorText = context.l10n.otpServiceUnavailable);
      return;
    }
    setState(() {
      _sending = true;
      _errorText = null;
      _statusText = null;
    });
    try {
      final challenge = await _otpRepository.sendCode(
        phoneNumber: phone,
        language: Localizations.localeOf(context).languageCode == 'ar'
            ? 'ar'
            : 'en',
      );
      if (!mounted) return;
      setState(() {
        _challengeId = challenge.id;
        _expiresAt = challenge.expiresAt;
        _lastSendFailure = null;
        _resendAt = DateTime.now().add(const Duration(seconds: 60));
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
        _statusText = context.l10n.otpSentMessage;
        if (challenge.deliveryStatus == OtpDeliveryStatus.queued ||
            challenge.deliveryStatus == OtpDeliveryStatus.sending) {
          _statusText = Localizations.localeOf(context).languageCode == 'ar'
              ? 'تم إنشاء طلب الرمز وهو قيد الإرسال إلى واتساب.'
              : 'The code request was accepted and is queued for WhatsApp.';
        }
        _code = '';
        _inputRevision++;
      });
    } on WexoraOtpException catch (error) {
      if (!mounted) return;
      _logWexoraFailure(error, 'send');
      _lastSendFailure = error.message ?? error.code;
      setState(() => _errorText = _localizedError(error.code, error.message));
    } catch (error) {
      if (!mounted) return;
      _lastSendFailure = error.toString();
      setState(() => _errorText = context.l10n.otpServiceUnavailable);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    if (_code.length != 6) {
      setState(() => _errorText = l10n.otpIncompleteMessage);
      return;
    }
    final challengeId = _challengeId;
    if (challengeId == null && _lastSendFailure != null) {
      setState(
        () => _errorText = Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر إرسال طلب جديد: $_lastSendFailure'
            : 'The latest send request failed: $_lastSendFailure',
      );
      return;
    }
    if (challengeId == null) {
      setState(() => _errorText = l10n.otpServiceUnavailable);
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
      _statusText = null;
    });
    try {
      // Delivery can be asynchronous after the API accepted the challenge.
      // Keep this diagnostic only; the verify endpoint remains authoritative.
      try {
        final delivery = await _otpRepository.getDeliveryStatus(challengeId);
        debugPrint('Wexora OTP delivery status: ${delivery.name}');
      } on WexoraOtpException catch (error) {
        _logWexoraFailure(error, 'delivery-status');
        // Status lookup is diagnostic only; still allow server-side code verify.
      }
      final verified = await _otpRepository.verifyCode(
        challengeId: challengeId,
        code: _code,
      );
      if (!verified) {
        if (mounted) setState(() => _errorText = l10n.otpInvalidMessage);
        return;
      }
      final args = widget.arguments;
      final registration = args.registrationData;
      if (registration == null &&
          args.email == null &&
          args.password == null &&
          args.name == null) {
        if (mounted) setState(() => _verified = true);
        return;
      }
      if (registration == null) {
        if (mounted) {
          setState(() => _errorText = l10n.authProfileIncomplete);
        }
        return;
      }
      await _authService.register(registration);
      if (!mounted) return;
      setState(() => _verified = true);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } on WexoraOtpException catch (error) {
      if (mounted) {
        _logWexoraFailure(error, 'verify');
        setState(() => _errorText = _localizedError(error.code, error.message));
      }
    } on AuthFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = switch (error.type) {
          AuthFailureType.emailAlreadyInUse =>
            context.l10n.authEmailAlreadyUsed,
          AuthFailureType.network => context.l10n.authNetworkError,
          _ => context.l10n.authGenericError,
        };
      });
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.type == AuthServiceFailureType.usernameTaken
            ? context.l10n.authUsernameTaken
            : context.l10n.authGenericError;
      });
    } catch (_) {
      if (mounted) setState(() => _errorText = l10n.otpServiceUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _localizedError(String code, [String? serverMessage]) {
    final l10n = context.l10n;
    if (l10n.isArabic && serverMessage?.trim().isNotEmpty == true) {
      return serverMessage!.trim();
    }
    return switch (code) {
      'resource-exhausted' || 'rate-limited' => l10n.otpRateLimited,
      'invalid-code' => l10n.otpInvalidMessage,
      'not-found' => l10n.otpExpiredMessage,
      'invalid-api-key' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'مفتاح Wexora غير صالح أو متوقف. راجع المفتاح من لوحة Wexora.'
            : 'The Wexora API key is invalid or disabled. Check it in the Wexora dashboard.',
      'session-not-found' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'جلسة واتساب غير موجودة في حساب Wexora المرتبط. راجع معرّف الجلسة.'
            : 'The WhatsApp session was not found in the linked Wexora account. Check the session ID.',
      'invalid-argument' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'راجع رقم واتساب واكتبه بالصيغة الدولية مع مفتاح الدولة.'
            : 'Check the WhatsApp number and enter it in international format with its country code.',
      'missing-otp-permission' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'مفتاح Wexora لا يملك صلاحية otp.send و otp.verify.'
            : 'The Wexora key needs the otp.send and otp.verify permissions.',
      'billing-required' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'خطة Wexora أو رصيد الرسائل لا يسمح بإرسال رمز حاليًا.'
            : 'The Wexora plan or message balance does not allow sending an OTP right now.',
      'wexora-conflict' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'جلسة واتساب غير متصلة أو يلزم الانتظار قبل إعادة الإرسال.'
            : 'The WhatsApp session is disconnected or the resend cooldown is still active.',
      'wexora-unavailable' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر إكمال طلب OTP من Wexora. رمز الخطأ: $code'
            : 'Wexora could not complete the OTP request. Error: $code',
      'unexpected-success-status' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'وصل رد غير متوقع من Wexora. رمز الخطأ: $code'
            : 'Wexora returned an unexpected response. Error: $code',
      'credentials-not-configured' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'بيانات Wexora غير مضبوطة للتجربة. أضف مفتاح API وSession ID عند تشغيل التطبيق.'
            : 'Wexora credentials are missing. Provide the API key and session ID when running the app.',
      'timeout' =>
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'انتهت مهلة الاتصال بـWexora. تأكد من الإنترنت وحاول بعد قليل.'
            : 'The connection to Wexora timed out. Check your internet and try again shortly.',
      _ => l10n.otpServiceUnavailable,
    };
  }

  void _logWexoraFailure(WexoraOtpException error, String operation) {
    debugPrint(
      'Wexora OTP $operation failed: code=${error.code}, '
      'requestId=${error.requestId ?? 'none'}, message=${error.message ?? 'none'}',
    );
  }

  String _maskedPhone(String? phone) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) return '—';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '••••$digits';
    return '+••••••${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;

    return Scaffold(
      backgroundColor: AppColor.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(28, 12, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OtpVerificationHeader(
                    backLabel: l10n.back,
                    onBack: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: OtpVerificationContent(
                        title: l10n.otpTitle,
                        description: isArabic
                            ? 'أدخل الرمز المكوّن من 6 أرقام المرسل عبر واتساب.'
                            : 'Enter the 6-digit code sent to you on WhatsApp.',
                        whatsAppLabel: isArabic ? 'واتساب' : 'WhatsApp',
                        phoneNumber: _maskedPhone(widget.arguments.phoneNumber),
                        codeLabel: l10n.otpCodeLabel,
                        inputKey: ValueKey('otp-input-$_inputRevision'),
                        errorText: _errorText,
                        digitLabel: l10n.otpDigitLabel,
                        onCodeChanged: (value) => setState(() {
                          _code = value;
                          if (value.length == 6) _errorText = null;
                        }),
                        resendLabel: _resendLabel(l10n),
                        canResend:
                            !_sending &&
                            !_busy &&
                            (_resendAt == null ||
                                !DateTime.now().isBefore(_resendAt!)),
                        onResend: _sendCode,
                        statusText:
                            _statusText ??
                            (_sending || _expiresAt == null
                                ? l10n.otpSendingMessage
                                : l10n.otpExpiryMessage(_expiresAt!)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OtpVerificationSubmitButton(
                    isBusy: _busy,
                    isSending: _sending,
                    isVerified: _verified,
                    verifyLabel: l10n.verifyLabel,
                    verifiedLabel: l10n.otpVerifiedMessage,
                    onPressed: _verify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resendLabel(AppLocalizations l10n) {
    if (_resendAt == null) return l10n.otpResendLabel;
    final remaining = _resendAt!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) return l10n.otpResendLabel;
    return l10n.otpResendCountdown(remaining);
  }
}
