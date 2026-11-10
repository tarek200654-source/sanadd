import '../../core/localization/app_localizations.dart';
import '../../data/network/api_exception.dart';
import '../../domain/repositories/token_store.dart';

String apiErrorCode(Object error) {
  if (error is! ApiException) return '';
  if (error.code == 'validation-failed') {
    final codes = error.fieldCodes.values.expand((v) => v);
    for (final identity in ['username-taken', 'email-already-in-use']) {
      if (codes.contains(identity)) return identity;
    }
    if (codes.isNotEmpty) return codes.first;
  }
  return error.code;
}

String apiErrorMessage(AppLocalizations l10n, Object error) {
  if (error is TokenStorageException) {
    return l10n.isArabic
        ? 'تعذر حفظ الجلسة بأمان. حاول تسجيل الدخول مجددًا.'
        : 'Could not securely save the session. Start login again.';
  }
  final code = apiErrorCode(error);
  return switch (code) {
    'recovery-not-eligible' =>
      l10n.isArabic
          ? 'تعذر المتابعة بهذه البيانات. راجعها وحاول مجددًا.'
          : 'Unable to continue with these details. Check them and try again.',
    'invalid-credentials' => l10n.authInvalidCredentials,
    'invalid-email' => l10n.invalidEmailMessage,
    'invalid-phone-number' => l10n.invalidPhoneMessage,
    'invalid-username' => l10n.invalidUsernameMessage,
    'password-mismatch' => l10n.passwordMismatchMessage,
    'required' =>
      l10n.isArabic
          ? 'يرجى استكمال الحقول المطلوبة.'
          : 'Complete the required fields.',
    'too-short' || 'too-long' || 'invalid-data' || 'invalid-role' =>
      l10n.isArabic
          ? 'راجع البيانات وشروط الحقول.'
          : 'Check the submitted fields and their requirements.',
    'invalid-code' => l10n.otpInvalidMessage,
    'otp-expired' => l10n.otpExpiredMessage,
    'too-many-requests' => l10n.otpRateLimited,
    'network-request-failed' || 'request-timeout' => l10n.authNetworkError,
    'invalid-challenge' || 'challenge-used' || 'account-changed' =>
      l10n.isArabic
          ? 'انتهت محاولة التحقق. ابدأ من جديد.'
          : 'This verification attempt is unavailable. Start again.',
    'email-already-in-use' =>
      l10n.isArabic
          ? 'البريد الإلكتروني مستخدم بالفعل.'
          : 'This email is already in use.',
    'username-taken' =>
      l10n.isArabic
          ? 'اسم المستخدم مستخدم بالفعل.'
          : 'This username is already in use.',
    'weak-password' =>
      l10n.isArabic
          ? 'كلمة المرور لا تطابق شروط الأمان.'
          : 'The password does not meet the security requirements.',
    'profile-incomplete' => l10n.authProfileIncomplete,
    'auth-operation-in-progress' =>
      l10n.isArabic
          ? 'انتظر اكتمال الطلب الحالي.'
          : 'Wait for the current request to finish.',
    _ => l10n.otpServiceUnavailable,
  };
}
