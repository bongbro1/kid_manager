import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
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

  void _openSettings() {
    _openedSettings = true;
    AppSettings.openAppSettings(type: AppSettingsType.notification);
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
                const Icon(
                  Icons.sos_rounded,
                  size: 90,
                  color: Colors.red,
                ),
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
                    l10n.permissionSosRecommendation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
