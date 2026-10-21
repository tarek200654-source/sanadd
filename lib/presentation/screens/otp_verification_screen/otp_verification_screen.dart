import 'dart:async';

import 'package:flutter/material.dart';

import '../../../application/auth/auth_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/repositories/wexora_otp_repository.dart';
import '../../../utils/routes.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/auth/otp_input.dart';
import '../../../presentation/widgets/auth/sanad_auth_logo.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.arguments,
    this.repository,
  });

  static const routeName = '/otp-verification';

  final AuthRouteArguments arguments;
  final OtpVerificationRepository? repository;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';
  String? _errorText;
  late final _otpRepository = widget.repository ?? WexoraOtpRepository();
  bool _busy = false;
  bool _sending = false;
  bool _verified = false;
  int _inputRevision = 0;
  String? _challengeId;
  DateTime? _expiresAt;
  DateTime? _resendAt;
  String? _statusText;
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
        _resendAt = DateTime.now().add(const Duration(seconds: 60));
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
        _statusText = context.l10n.otpSentMessage;
        _code = '';
        _inputRevision++;
      });
    } on WexoraOtpException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = _localizedError(error.code));
    } catch (_) {
      if (!mounted) return;
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
      final verified = await _otpRepository.verifyCode(
        challengeId: challengeId,
        code: _code,
      );
      if (!verified) {
        if (mounted) setState(() => _errorText = l10n.otpInvalidMessage);
        return;
      }
      final args = widget.arguments;
      if (args.email == null || args.password == null || args.name == null) {
        if (mounted) setState(() => _verified = true);
        return;
      }
      await AuthService.firebase().register(
        name: args.name!,
        email: args.email!,
        password: args.password!,
        role: args.role,
        phoneNumber: args.phoneNumber,
      );
      if (!mounted) return;
      setState(() => _verified = true);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
    } on WexoraOtpException catch (error) {
      if (mounted) setState(() => _errorText = _localizedError(error.code));
    } catch (_) {
      if (mounted) setState(() => _errorText = l10n.otpServiceUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _localizedError(String code) {
    final l10n = context.l10n;
    return switch (code) {
      'resource-exhausted' || 'rate-limited' => l10n.otpRateLimited,
      'invalid-argument' || 'invalid-code' => l10n.otpInvalidMessage,
      'not-found' => l10n.otpExpiredMessage,
      'credentials-not-configured' => Localizations.localeOf(context).languageCode == 'ar'
          ? 'بيانات Wexora غير مضبوطة للتجربة. أضف مفتاح API وSession ID عند تشغيل التطبيق.'
          : 'Wexora credentials are missing. Provide the API key and session ID when running the app.',
      'timeout' => Localizations.localeOf(context).languageCode == 'ar'
          ? 'انتهت مهلة الاتصال بخدمة التحقق. تأكد من تشغيل خادم Wexora وحاول مجددًا.'
          : 'The verification service timed out. Check that the Wexora proxy is running and try again.',
      _ => l10n.otpServiceUnavailable,
    };
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(28, 12, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.back,
                        onPressed: () => Navigator.maybePop(context),
                        icon: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      const SanadAuthLogo(artworkWidth: 100),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.otpTitle,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 30,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isArabic
                                ? 'أدخل الرمز المكوّن من 6 أرقام المرسل عبر واتساب.'
                                : 'Enter the 6-digit code sent to you on WhatsApp.',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 21,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isArabic ? 'واتساب' : 'WhatsApp',
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _maskedPhone(widget.arguments.phoneNumber),
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Text(
                            l10n.otpCodeLabel,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OtpInput(
                            key: ValueKey('otp-input-$_inputRevision'),
                            errorText: _errorText,
                            digitLabel: l10n.otpDigitLabel,
                            onChanged: (value) => setState(() {
                              _code = value;
                              if (value.length == 6) _errorText = null;
                            }),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed:
                                  _sending ||
                                      _busy ||
                                      (_resendAt != null &&
                                          DateTime.now().isBefore(_resendAt!))
                                  ? null
                                  : _sendCode,
                              child: Text(_resendLabel(l10n)),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _statusText ??
                                (_sending
                                    ? l10n.otpSendingMessage
                                    : _expiresAt == null
                                    ? l10n.otpSendingMessage
                                    : l10n.otpExpiryMessage(_expiresAt!)),
                            style: const TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 58,
                    child: FilledButton(
                      key: const ValueKey('otp-verify-submit'),
                      onPressed: _busy || _sending || _verified
                          ? null
                          : _verify,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _busy || _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _verified
                                  ? l10n.otpVerifiedMessage
                                  : l10n.verifyLabel,
                            ),
                    ),
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
