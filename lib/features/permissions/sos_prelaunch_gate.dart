import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SosPrelaunchGate extends StatefulWidget {
  final Widget child;

  const SosPrelaunchGate({
    super.key,
    required this.child,
  });

  @override
  State<SosPrelaunchGate> createState() => _SosPrelaunchGateState();
}

class _SosPrelaunchGateState extends State<SosPrelaunchGate>
    with WidgetsBindingObserver {
  bool _ready = false;
  bool _openedSettings = false;
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _status = status;
        _ready = true;
      });
    } else {
      setState(() {
        _status = status;
        _ready = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!_openedSettings) return;
    if (state != AppLifecycleState.resumed) return;

    _openedSettings = false;
    await _checkPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _status = status;
        _ready = true;
      });
      return;
    }

    setState(() {
      _status = status;
      _ready = false;
    });
  }

  void _openSettings() {
    _openedSettings = true;
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const Spacer(),
                const Icon(
                  Icons.sos_rounded,
                  size: 90,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bật quyền SOS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ứng dụng cần quyền thông báo để gửi cảnh báo SOS khẩn cấp và phát âm thanh cảnh báo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hãy bật thông báo và đảm bảo kênh "SOS Alerts" có âm thanh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestPermission,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cho phép SOS'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _openSettings,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Mở cài đặt'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}