import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/app/app_mode.dart';
import 'package:kid_manager/widgets/app/app_bottom_nav.dart';
import 'package:kid_manager/widgets/app/app_sell_config.dart';
import 'package:kid_manager/widgets/sos/incoming_sos_overlay.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  final AppMode mode;

  const AppShell({super.key, required this.mode});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  late final AppShellConfig _config = widget.mode == AppMode.parent
      ? AppShellConfig.parent()
      : AppShellConfig.child();

  late final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    _config.tabs.length,
        (_) => GlobalKey<NavigatorState>(),
  );

  late final List<Widget> _tabs = List.generate(
    _config.tabs.length,
        (i) => Navigator(
      key: _navKeys[i],
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => _config.tabs[i].root),
    ),
  );

  @override
  void initState() {
    super.initState();
    activeTabNotifier.addListener(_syncTabFromNotifier);
  }

  void _syncTabFromNotifier() {
    final i = activeTabNotifier.value;
    if (!mounted) return;
    if (i == _index) return;
    setState(() => _index = i);
  }

  Future<void> _onNavTap(int i) async {
    if (i == _index) {
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = i);
    activeTabNotifier.value = i;
  }

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final familyId = context.select<UserVm, String?>((vm) => vm.familyId);
    final myUid = context.select<UserVm, String?>((vm) => vm.me?.uid);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(
              index: _index,
              children: _tabs,
            ),
            bottomNavigationBar: AppBottomNav(
              items: _config.tabs
                  .map(
                    (t) => BottomNavItem(
                  iconAsset: t.iconAsset,
                  showBadge: t.showBadge,
                ),
              )
                  .toList(),
              currentIndex: _index,
              onTap: _onNavTap,
            ),
          ),
          if (familyId != null && myUid != null)
            IncomingSosOverlay(
              key: ValueKey('sos-$familyId'),
              familyId: familyId,
              myUid: myUid,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    activeTabNotifier.removeListener(_syncTabFromNotifier);
    super.dispose();
  }
}