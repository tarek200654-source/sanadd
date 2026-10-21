import 'package:flutter/widgets.dart';

import 'locale_controller.dart';

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    required LocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  LocaleController get controller => notifier!;
}

extension LocaleScopeX on BuildContext {
  LocaleController get localeController =>
      dependOnInheritedWidgetOfExactType<LocaleScope>()!.controller;
}
