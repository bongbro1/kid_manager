import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_navigator.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/repositories/chat/family_chat_repository.dart';
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
  final FamilyChatRepository _chatRepository = FamilyChatRepository();
  late final Set<int> _visitedIndexes = <int>{_index};

  late final AppShellConfig _config = widget.mode == AppMode.parent
      ? AppShellConfig.parent()
      : widget.mode == AppMode.guardian
      ? AppShellConfig.guardian()
      : AppShellConfig.child();

  late final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    _config.tabs.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  void initState() {
    super.initState();

    notificationTabIndexNotifier.value = _config.tabs.indexWhere(
      (t) => t.isNotificationTab,
    );
    mapTabIndexNotifier.value = _config.tabs.indexWhere((t) => t.isMapTab);
    scheduleTabIndexNotifier.value = _config.tabs.indexWhere(
      (t) => t.isScheduleTab,
    );

    activeTabNotifier.addListener(_syncTabFromNotifier);
  }

  void _syncTabFromNotifier() {
    final i = activeTabNotifier.value;
    if (!mounted) return;
    if (i == _index) return;
    setState(() {
      _index = i;
      _visitedIndexes.add(i);
    });
  }

  Future<void> _onNavTap(int i) async {
    if (i == _index) {
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);

      if (i == _config.chatTabIndex) {
        try {
          await _chatRepository.markAsRead();
        } catch (e) {
          debugPrint('markAsRead error: $e');
        }
      }
      return;
    }

    setState(() {
      _index = i;
      _visitedIndexes.add(i);
    });
    activeTabNotifier.value = i;

    if (i == _config.chatTabIndex) {
      try {
        await _chatRepository.markAsRead();
      } catch (e) {
        debugPrint('markAsRead error: $e');
      }
    }
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
              children: List<Widget>.generate(_config.tabs.length, (i) {
                if (!_visitedIndexes.contains(i)) {
                  return const SizedBox.shrink();
                }
                return _buildTabNavigator(i);
              }),
            ),
            bottomNavigationBar: AppBottomNav(
              items: _config.tabs
                  .map(
                    (t) => BottomNavItem(
                      iconAsset: t.iconAsset,
                      showBadge: t.showBadge,
                      badgeCountStreamBuilder: t.badgeCountStreamBuilder,
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

  Widget _buildTabNavigator(int index) {
    final tab = _config.tabs[index];
    final isNotificationTab = tab.isNotificationTab;

    return Navigator(
      key: isNotificationTab ? NotificationTabNavigator.key : _navKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => tab.root),
    );
  }
}
