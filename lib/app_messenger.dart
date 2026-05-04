import 'package:flutter/material.dart';

/// Global snackbars without changing page layout (floating, short).
final class AppMessenger {
  AppMessenger._();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(String message) {
    final m = scaffoldMessengerKey.currentState;
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
