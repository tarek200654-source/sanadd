import '../../data/network/api_client.dart';
import '../../data/network/api_exception.dart';
import '../../domain/models/caregiver_link.dart';

final class CaregiverLinksService {
  CaregiverLinksService(this.api, {this.expectedToken});
  final ApiClient api;
  final String? expectedToken;

  Future<PublicLinkUser> lookup(String username) => _parse(() async {
    final json = await api.post(
      '/api/caregivers/lookup',
      body: {'username': username.trim()},
      authenticated: true,
      expectedToken: expectedToken,
    );
    return PublicLinkUser.fromJson(
      _data(json, 'caregiver-found')['caregiver'] as Map<String, dynamic>,
    );
  });
  Future<CaregiverLinksPage> list({
    int page = 1,
    bool history = false,
  }) => _parse(() async {
    final json = await api.get(
      '/api/caregiver-links',
      authenticated: true,
      expectedToken: expectedToken,
      query: {'page': '$page', 'per_page': '20', if (history) 'status': 'all'},
    );
    return CaregiverLinksPage.fromJson(_data(json, 'caregiver-links-listed'));
  });
  Future<CaregiverLink> invite(String username) => _parse(() async {
    final json = await api.post(
      '/api/caregiver-links',
      body: {'caregiver_username': username.trim()},
      authenticated: true,
      expectedToken: expectedToken,
    );
    return CaregiverLink.fromJson(
      _data(json, 'caregiver-invitation-created')['link']
          as Map<String, dynamic>,
    );
  });
  Future<CaregiverLink> transition(CaregiverLink link, String action) =>
      _parse(() async {
        if (!['accept', 'decline', 'cancel', 'revoke'].contains(action) ||
            !link.actions.contains(action)) {
          throw ApiException(code: 'invalid-relationship-state');
        }
        final json = await api.post(
          '/api/caregiver-links/${link.id}/$action',
          body: {},
          authenticated: true,
          expectedToken: expectedToken,
        );
        return CaregiverLink.fromJson(
          _data(json, 'caregiver-link-updated')['link'] as Map<String, dynamic>,
        );
      });
  Map<String, dynamic> _data(Map<String, dynamic>? json, String code) {
    if (json?['code'] != code || json?['data'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid response.');
    }
    return json!['data'] as Map<String, dynamic>;
  }

  Future<T> _parse<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FormatException {
      throw ApiException(code: 'invalid-response');
    } on TypeError {
      throw ApiException(code: 'invalid-response');
    }
  }
}
