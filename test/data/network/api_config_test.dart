import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/data/network/api_config.dart';

void main() {
  test('development defaults distinguish Android emulator and desktop', () {
    expect(ApiConfig.developmentBaseUrl(android: true), 'http://10.0.2.2:8000');
    expect(
      ApiConfig.developmentBaseUrl(android: false),
      'http://127.0.0.1:8000',
    );
  });

  test('debug permits loopback and explicit private LAN origins', () {
    for (final url in [
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
      'http://192.168.1.7:8000',
      'http://172.16.0.2:8000',
      'http://localhost:8000',
    ]) {
      expect(ApiConfig(baseUrl: url).endpoint('/api/user').path, '/api/user');
    }
  });

  test('production requires an explicit HTTPS origin', () {
    expect(
      () => ApiConfig(baseUrl: 'http://127.0.0.1:8000', production: true),
      throwsArgumentError,
    );
    expect(
      ApiConfig(
        baseUrl: 'https://backend.example',
        production: true,
      ).endpoint('/api/user').scheme,
      'https',
    );
  });

  test('rejects unsafe origins and endpoints before sending credentials', () {
    for (final url in [
      '',
      'ftp://localhost',
      'http://public.example',
      'https://u:p@backend.example',
      'https://backend.example/api',
      'https://backend.example/?key=secret',
      'https://backend.example/#x',
    ]) {
      expect(() => ApiConfig(baseUrl: url), throwsArgumentError);
    }
    final config = ApiConfig(baseUrl: 'http://127.0.0.1:8000/');
    for (final path in [
      'https://other.example/api/user',
      '//other.example/api/user',
      '/api/../user',
      '/api/%2e%2e/user',
      '/api/user#x',
      '/api/user?token=x',
      '/other',
      '/api/a\\b',
    ]) {
      expect(() => config.endpoint(path), throwsArgumentError);
    }
    expect(
      () => ApiConfig(baseUrl: 'http://localhost', timeout: Duration.zero),
      throwsArgumentError,
    );
  });
}
