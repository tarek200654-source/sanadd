/// Shared username constraints used by UI validation and Firestore paths.
abstract final class UsernamePolicy {
  static const int minLength = 4;
  static const int maxLength = 15;
  static final RegExp _allowedCharacters = RegExp(r'^[A-Za-z0-9._]+$');

  static bool isValid(String? value) {
    final username = value?.trim() ?? '';
    return username.length >= minLength &&
        username.length <= maxLength &&
        _allowedCharacters.hasMatch(username);
  }

  static String canonicalize(String username) => username.trim().toLowerCase();
}
