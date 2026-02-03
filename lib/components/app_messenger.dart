import 'package:flutter/material.dart';

class AppMessenger {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void show(String text) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }
}
