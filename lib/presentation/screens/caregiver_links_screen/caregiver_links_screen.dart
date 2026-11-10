import 'package:flutter/material.dart';
import '../../../application/auth/auth_scope.dart';
import '../../../application/caregiving/caregiver_links_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/caregiving_localizations.dart';
import '../../../domain/models/caregiver_link.dart';
import '../../../domain/validation/username_policy.dart';
import '../../../utils/routes.dart';
import '../../widgets/home_widgets/reference_ui.dart';

class CaregiverLinksScreen extends StatefulWidget {
  const CaregiverLinksScreen({super.key});
  @override
  State<CaregiverLinksScreen> createState() => _CaregiverLinksScreenState();
}

class _CaregiverLinksScreenState extends State<CaregiverLinksScreen>
    with WidgetsBindingObserver {
  late final CaregiverLinksController controller;
  final _username = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _leaving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = CaregiverLinksController(AuthScope.read(context))
      ..addListener(_changed);
    controller.initialize();
  }

  void _changed() {
    if (!mounted) return;
    if (controller.sessionExpired && !_leaving) {
      _leaving = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        }
      });
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_changed);
    controller.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ReferenceUi.theme(Theme.of(context), context.l10n.isArabic),
    child: Builder(builder: _content),
  );

  Widget _content(BuildContext context) {
    final l = context.l10n;
    final c = controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          c.profile == null
              ? l.currentLinks
              : c.isPatient
              ? l.caregiversTitle
              : l.caregivingTitle,
        ),
        actions: [
          IconButton(
            key: const ValueKey('caregiver-refresh'),
            tooltip: l.refreshLinks,
            onPressed: c.loading || c.busy ? null : c.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (c.loading || c.busy)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(),
                    ),
                  if (c.profile != null) ...[
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        key: const ValueKey('caregiver-history'),
                        onPressed: c.loading || c.busy
                            ? null
                            : () => c.showHistory(!c.history),
                        icon: Icon(
                          c.history
                              ? Icons.people_outline
                              : Icons.history_rounded,
                        ),
                        label: Text(c.history ? l.currentLinks : l.linkHistory),
                      ),
                    ),
                    if (c.isPatient) ...[
                      _panel(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l.slotsSummary(c.occupied),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                for (var slot = 0; slot < 3; slot++)
                                  Expanded(
                                    child: Semantics(
                                      label: slot < c.occupied
                                          ? l.occupiedSlot
                                          : l.availableSlot,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: slot < c.occupied
                                              ? ReferenceUi.blue
                                              : ReferenceUi.darkBorder,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${l.availableSlot}: ${3 - c.occupied}'),
                          ],
                        ),
                      ),
                      if (!c.history) ...[
                        const SizedBox(height: 16),
                        _search(context),
                      ],
                    ],
                  ],
                  if (c.errorCode != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          l.linkError(c.errorCode!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  if (c.needsReconciliation)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l.reconcileLinks),
                    ),
                  if (c.actionCompleted &&
                      !c.needsReconciliation &&
                      c.errorCode == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(l.relationshipUpdated),
                      ),
                    ),
                  if (!c.loading && c.links.isEmpty && c.profile != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: _panel(
                        Column(
                          children: [
                            const Icon(Icons.people_outline, size: 36),
                            const SizedBox(height: 12),
                            Text(
                              c.history ? l.noHistory : l.noConnections,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.isPatient
                                  ? l.patientEmptyHint
                                  : l.caregiverEmptyHint,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final status in CaregiverLinkStatus.values)
                    if (c.links.any((link) => link.status == status)) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          l.linkState(status),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      for (final link in c.links.where(
                        (link) => link.status == status,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _linkCard(context, link),
                        ),
                    ],
                  if (c.hasMore)
                    TextButton(
                      onPressed: c.loading || c.busy ? null : c.loadMore,
                      child: Text(l.moreLinks),
                    ),
                  if (c.errorCode != null)
                    OutlinedButton(
                      onPressed: c.loading || c.busy ? null : c.refresh,
                      child: Text(l.refreshLinks),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _search(BuildContext context) {
    final l = context.l10n;
    final c = controller;
    return _panel(
      Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.findCaregiver,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(l.exactUsernameHint),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('caregiver-username'),
              controller: _username,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              enableSuggestions: false,
              enabled:
                  !c.busy &&
                  !c.loading &&
                  !c.needsReconciliation &&
                  c.occupied < 3,
              decoration: InputDecoration(
                labelText: l.caregiverUsername,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => c.clearConfirmation(),
              validator: (value) => UsernamePolicy.isValid(value)
                  ? null
                  : l.invalidUsernameMessage,
              onFieldSubmitted: (_) => _lookup(),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('caregiver-lookup'),
              onPressed: c.canMutate && !c.searching && c.occupied < 3
                  ? _lookup
                  : null,
              child: c.searching
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.lookUpCaregiver),
            ),
            if (c.occupied >= 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l.linkError('caregiver-slots-full')),
              ),
            if (c.confirmation case final target?) ...[
              const SizedBox(height: 16),
              Container(
                key: const ValueKey('caregiver-confirmation'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ReferenceUi.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.confirmCaregiver),
                    const SizedBox(height: 12),
                    Text(
                      target.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '@${target.username}',
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const ValueKey('caregiver-invite'),
                      onPressed: c.canMutate
                          ? () {
                              FocusScope.of(context).unfocus();
                              c.invite();
                            }
                          : null,
                      child: Text(l.sendInvitation),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _lookup() {
    if (_form.currentState?.validate() == true) {
      FocusScope.of(context).unfocus();
      controller.lookup(_username.text);
    }
  }

  Widget _linkCard(BuildContext context, CaregiverLink link) {
    final l = context.l10n;
    final active = link.status == CaregiverLinkStatus.active;
    String date(DateTime value) =>
        MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
    return _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            link.counterpart.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            '@${link.counterpart.username}',
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(
              label: Text(l.linkState(link.status)),
              backgroundColor: active
                  ? const Color(0xFFE6F4EA)
                  : link.status == CaregiverLinkStatus.pending
                  ? const Color(0xFFFFF4D6)
                  : ReferenceUi.darkBorder,
              side: BorderSide.none,
            ),
          ),
          Text('${l.invitedOn}: ${date(link.invitedAt)}'),
          if (controller.history) ...[
            if (link.acceptedAt != null)
              Text('${l.acceptedOn}: ${date(link.acceptedAt!)}'),
            if (link.endedAt != null)
              Text('${l.endedOn}: ${date(link.endedAt!)}'),
          ],
          if (link.actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in link.actions)
                    OutlinedButton(
                      key: ValueKey('link-$action-${link.id}'),
                      onPressed: controller.canMutate
                          ? () => _action(context, link, action)
                          : null,
                      child: Text(
                        l.linkAction(action, patient: controller.isPatient),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _action(
    BuildContext context,
    CaregiverLink link,
    String action,
  ) async {
    if (action == 'revoke') {
      final l = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            controller.isPatient
                ? l.revokePatientTitle
                : l.revokeCaregiverTitle,
          ),
          content: Text(l.revokeExplanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.keepConnection),
            ),
            FilledButton(
              key: const ValueKey('confirm-revoke'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l.linkAction('revoke', patient: controller.isPatient),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await controller.transition(link, action);
  }

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: ReferenceUi.darkSurface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}
