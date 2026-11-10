/// Strict, non-logging parsing shared by authentication wire values.
String authString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Invalid authentication response.');
  }
  return value;
}

DateTime authTimestamp(Object? value) {
  final text = authString(value);
  if (!RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
  ).hasMatch(text)) {
    throw const FormatException('Invalid authentication timestamp.');
  }
  final result = DateTime.tryParse(text);
  if (result == null) {
    throw const FormatException('Invalid authentication timestamp.');
  }
  return result.toUtc();
}

String authSecret(Object? value) {
  final secret = authString(value);
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(secret)) {
    throw const FormatException('Invalid authentication proof.');
  }
  return secret;
}
