import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kid_manager/widgets/sos/sos_sound_help.dart'; // file chứa SosSoundHelpDialog

class SosSoundPrompt {
  static const _keyShown = 'sos_sound_help_shown_v1';

  static Future<void> showIfNeeded(BuildContext context) async {
    final sp = await SharedPreferences.getInstance();
    final shown = sp.getBool(_keyShown) ?? false;
    if (shown) return;

    await sp.setBool(_keyShown, true);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SosSoundHelpDialog(),
    );
  }

  static Future<void> reset() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyShown);
  }
}
