String maskEmail(String? email) {
  final value = email?.trim() ?? '';
  final separator = value.lastIndexOf('@');
  if (separator <= 0 || separator == value.length - 1) return '***';
  final localPart = value.substring(0, separator);
  final domain = value.substring(separator + 1);
  return '${localPart.substring(0, 1)}***@$domain';
}
