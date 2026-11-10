import 'auth_json.dart';

enum CaregiverLinkStatus { pending, active, declined, revoked, cancelled }

final class PublicLinkUser {
  const PublicLinkUser({required this.name, required this.username});
  final String name;
  final String username;
  factory PublicLinkUser.fromJson(Map<String, dynamic> json) => PublicLinkUser(
    name: authString(json['name']),
    username: authString(json['username']),
  );
}

final class CaregiverLink {
  const CaregiverLink({
    required this.id,
    required this.status,
    required this.counterpart,
    required this.invitedAt,
    required this.actions,
    this.acceptedAt,
    this.endedAt,
  });
  final String id;
  final CaregiverLinkStatus status;
  final PublicLinkUser counterpart;
  final DateTime invitedAt;
  final DateTime? acceptedAt;
  final DateTime? endedAt;
  final List<String> actions;
  factory CaregiverLink.fromJson(Map<String, dynamic> json) {
    final id = authString(json['id']);
    final status = CaregiverLinkStatus.values
        .where((v) => v.name == json['status'])
        .firstOrNull;
    final actions = json['allowed_actions'];
    if (!RegExp(
          r'^[a-fA-F0-9]{8}-(?:[a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}$',
        ).hasMatch(id) ||
        status == null ||
        actions is! List ||
        actions.any(
          (v) => !['accept', 'decline', 'cancel', 'revoke'].contains(v),
        )) {
      throw const FormatException('Invalid relationship response.');
    }
    return CaregiverLink(
      id: id,
      status: status,
      counterpart: PublicLinkUser.fromJson(
        json['counterpart'] as Map<String, dynamic>,
      ),
      invitedAt: authTimestamp(json['invited_at']),
      acceptedAt: json['accepted_at'] == null
          ? null
          : authTimestamp(json['accepted_at']),
      endedAt: json['ended_at'] == null
          ? null
          : authTimestamp(json['ended_at']),
      actions: List<String>.unmodifiable(actions),
    );
  }
}

final class CaregiverLinksPage {
  const CaregiverLinksPage({
    required this.links,
    required this.page,
    required this.lastPage,
    this.occupied,
  });
  final List<CaregiverLink> links;
  final int page;
  final int lastPage;
  final int? occupied;
  factory CaregiverLinksPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final page = pagination['page'];
    final last = pagination['last_page'];
    final slots = json['slots'] as Map<String, dynamic>?;
    final occupied = slots?['occupied'];
    if (page is! int ||
        page < 1 ||
        last is! int ||
        last < 1 ||
        (slots != null &&
            (slots['maximum'] != 3 ||
                occupied is! int ||
                occupied < 0 ||
                occupied > 3 ||
                slots['available'] != 3 - occupied))) {
      throw const FormatException('Invalid relationship pagination.');
    }
    return CaregiverLinksPage(
      links: List.unmodifiable(
        (json['links'] as List).map(
          (v) => CaregiverLink.fromJson(v as Map<String, dynamic>),
        ),
      ),
      page: page,
      lastPage: last,
      occupied: occupied as int?,
    );
  }
}
