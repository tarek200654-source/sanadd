import 'package:flutter/widgets.dart';
import 'auth_service.dart';

class AuthScope extends StatefulWidget {
  const AuthScope({super.key, this.auth, required this.child});
  final AuthService? auth;
  final Widget child;
  static AuthService read(BuildContext context) {
    final provider = context.getInheritedWidgetOfExactType<_AuthProvider>();
    if (provider == null) throw StateError('AuthScope is required.');
    return provider.notifier!;
  }

  @override
  State<AuthScope> createState() => _AuthScopeState();
}

class _AuthScopeState extends State<AuthScope> {
  late final AuthService auth = widget.auth ?? AuthService.local();
  @override
  void dispose() {
    if (widget.auth == null) auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AuthProvider(notifier: auth, child: widget.child);
}

class _AuthProvider extends InheritedNotifier<AuthService> {
  const _AuthProvider({required super.notifier, required super.child});
}
