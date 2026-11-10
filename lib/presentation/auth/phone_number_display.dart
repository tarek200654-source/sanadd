import '../../core/constants/app_constants.dart';

/// Display data only: never use a masked number as a delivery destination.
String maskedWhatsAppNumber(String? phone) {
  final value = phone?.trim() ?? '';
  final callingCodes =
      AppConstants.countries.values
          .map((country) => country.callingCode)
          .toSet()
          .toList()
        ..sort((a, b) => b.length.compareTo(a.length));
  final callingCode = callingCodes.where(value.startsWith).firstOrNull;
  final nationalDigits =
      (callingCode == null ? value : value.substring(callingCode.length))
          .replaceAll(RegExp(r'\D'), '');
  if (nationalDigits.length < 4) return '—';
  final lastFour = nationalDigits.substring(nationalDigits.length - 4);
  return '${callingCode == null ? '' : '$callingCode '}•••••• $lastFour';
}
