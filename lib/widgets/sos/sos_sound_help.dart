import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SosSoundHelpDialog extends StatefulWidget {
  const SosSoundHelpDialog({super.key});

  @override
  State<SosSoundHelpDialog> createState() => _SosSoundHelpDialogState();
}

class _SosSoundHelpDialogState extends State<SosSoundHelpDialog>
    with WidgetsBindingObserver {
  bool _openedSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!_openedSettings) return;
    if (state != AppLifecycleState.resumed) return;

    final status = await Permission.notification.status;
    if (!mounted) return;

    if (status.isGranted) {
      Navigator.of(context).pop(true); // ✅ tự đóng dialog
    } else {
      setState(() => _openedSettings = false);
    }
  }

  void _openSettings() {
    setState(() => _openedSettings = true);
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bật âm thanh SOS'),
      content: const Text(
        'Nếu bạn đang để im lặng/tắt âm, SOS có thể không kêu.\n'
        'Hãy bật âm thanh cho kênh "SOS Alerts" trong cài đặt thông báo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Để sau'),
        ),
        ElevatedButton(
          onPressed: _openSettings,
          child: const Text('Mở cài đặt'),
        ),
      ],
    );
  }
}
