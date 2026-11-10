import 'package:flutter/foundation.dart';

final class ApiConfig {
  ApiConfig({
    required String baseUrl,
    bool production = false,
    this.timeout = const Duration(seconds: 20),
  }) : origin = _origin(baseUrl, production || !kDebugMode) {
    if (timeout <= Duration.zero) {
      throw ArgumentError('API timeout must be positive.');
    }
  }

  /// Define SANAD_API_BASE_URL for a device LAN origin or any deployed build.
  factory ApiConfig.fromEnvironment() {
    const configured = String.fromEnvironment('SANAD_API_BASE_URL');
    if (configured.isEmpty && !kDebugMode) {
      throw StateError('SANAD_API_BASE_URL must be configured for this build.');
    }
    return ApiConfig(
      baseUrl: configured.isNotEmpty
          ? configured
          : developmentBaseUrl(
              android: defaultTargetPlatform == TargetPlatform.android,
            ),
    );
  }

  static String developmentBaseUrl({required bool android}) =>
      android ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';

  final Uri origin;
  final Duration timeout;

  static Uri _origin(String value, bool requireHttps) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !['http', 'https'].contains(uri.scheme) ||
        (requireHttps && uri.scheme != 'https') ||
        (uri.scheme == 'http' && !_localHost(uri.host))) {
      throw ArgumentError(
        'Configure a valid API origin; HTTPS is required outside local debug builds.',
      );
    }
    return uri.replace(path: '');
  }

  static bool _localHost(String host) {
    if (['localhost', '::1', '[::1]'].contains(host)) return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 ||
        parts.any((part) => part == null || part < 0 || part > 255)) {
      return false;
    }
    return parts[0] == 127 ||
        parts[0] == 10 ||
        (parts[0] == 192 && parts[1] == 168) ||
        (parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31);
  }

  Uri endpoint(String path) {
    final uri = Uri.tryParse(path);
    List<String> decodedSegments;
    try {
      decodedSegments = Uri.decodeComponent(path).split('/');
    } on FormatException {
      throw ArgumentError('Use a valid API path.');
    }
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        !path.startsWith('/api/') ||
        path.contains('\\') ||
        decodedSegments.any(
          (part) => part == '..' || part == '.' || part.contains('\\'),
        ) ||
        uri.pathSegments.any(
          (part) =>
              part == '..' ||
              part == '.' ||
              part.contains('/') ||
              part.contains('\\'),
        )) {
      throw ArgumentError('Use an API path on the configured origin.');
    }
    return origin.resolveUri(uri);
  }
}
