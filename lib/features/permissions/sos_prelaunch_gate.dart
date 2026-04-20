import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SosPrelaunchGate extends StatefulWidget {
  final Widget child;

  const SosPrelaunchGate({super.key, required this.child});

  @override
  State<SosPrelaunchGate> createState() => _SosPrelaunchGateState();
}

class _SosPrelaunchGateState extends State<SosPrelaunchGate>
    with WidgetsBindingObserver {
  bool _ready = false;
  bool _openedSettings = false;

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
        _ready = true;
      });
    } else {
      setState(() {
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
        _ready = true;
      });
      return;
    }

    setState(() {
      _ready = false;
    });
  }

  Future<void> _openSettings() async {
    _openedSettings = true;
    await PermissionService().openAndroidSosAlertSettings();
  }

  String _recommendationTextLocalized(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode.toLowerCase() == 'vi') {
      return 'Hãy bật thông báo. Trên Android, bạn nên mở thêm cài đặt SOS khẩn cấp để app có thể dùng cảnh báo mạnh hơn, bỏ qua Không làm phiền nếu máy cho phép, và tạm thời tăng một số mức âm lượng cảnh báo. Android vẫn có thể chặn âm thanh trong một số chế độ im lặng của thiết bị.';
    }

    return 'Enable notifications first. On Android, you should also open the SOS emergency settings so the app can use stronger alerts, bypass Do Not Disturb when the device allows it, and temporarily raise some alert-related volume streams. The OS may still block sound in some silent-mode scenarios.';
  }

  // ignore: unused_element
  String _recommendationText(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode.toLowerCase() == 'vi') {
      return 'Hãy bật thông báo. Trên Android, bạn nên mở thêm cài đặt SOS khẩn cấp để cho phép cảnh báo mạnh hơn trong chế độ Không làm phiền. Hệ điều hành vẫn có thể chặn âm thanh trong một số chế độ im lặng của thiết bị.';
    }

    return 'Enable notifications first. On Android, you should also open the SOS emergency settings to allow stronger alerts during Do Not Disturb. The OS may still block sound in some silent-mode scenarios.';
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    final l10n = AppLocalizations.of(context);

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
                const Icon(Icons.sos_rounded, size: 90, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  l10n.permissionSosTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.permissionSosSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                  child: Text(
                    _recommendationTextLocalized(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
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
                    child: Text(l10n.permissionSosAllowButton),
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
                    child: Text(l10n.permissionOpenSettingsButton),
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
