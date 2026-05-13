import 'package:flutter/material.dart';

/// Pops the current route (e.g. a modal dialog) then pushes [page].
///
/// Uses the same [NavigatorState] that owns [context] (not `rootNavigator:
/// true`), then defers the push so iOS reliably runs it after the pop
/// completes.
void pushAfterClosingDialog(BuildContext context, Widget page) {
  final nav = Navigator.of(context);
  nav.pop();
  Future<void>.delayed(Duration.zero, () {
    if (!nav.mounted) return;
    nav.push<void>(MaterialPageRoute<void>(builder: (_) => page));
  });
}
