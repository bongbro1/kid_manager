import 'package:flutter/material.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/views/home/home_screen.dart';
import 'package:kid_manager/views/parent/app_management_screen.dart';
import 'package:kid_manager/widgets/app/app_bottom_nav.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/views/parent/schedule/schedule_screen.dart';


class ChildShell extends StatefulWidget {
  const ChildShell({super.key});

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int _index = 0;

  final items = const [
    BottomNavItem(iconAsset: 'assets/icons/home.svg'),
    BottomNavItem(iconAsset: 'assets/icons/apps.svg'),
    BottomNavItem(iconAsset: 'assets/icons/clock.svg'),
    BottomNavItem(iconAsset: 'assets/icons/bell.svg'),
    BottomNavItem(iconAsset: 'assets/icons/user.svg'),
    BottomNavItem(iconAsset: 'assets/icons/settings.svg'),
  ];

  final pages = const [
    HomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AppBottomNav(
        items: items,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}


class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _index = 0;

  final items = const [
    BottomNavItem(iconAsset: 'assets/icons/location.svg'),
    BottomNavItem(iconAsset: 'assets/icons/dashboard.svg'),
    BottomNavItem(iconAsset: 'assets/icons/sms.svg'),
    BottomNavItem(iconAsset: 'assets/icons/bell.svg'),
    BottomNavItem(iconAsset: 'assets/icons/calendar.svg'),
    BottomNavItem(iconAsset: 'assets/icons/user_nav.svg'),
  ];

  final pages = const [
    AppManagementScreen(),
    ScheduleScreen(), //HIện tại bấm vào lịch thì đang là icon thứ 2
  ];

  Future<void> _onNavTap(int i) async {
    final isLogoutItem = i == items.length - 1;

    if (isLogoutItem) {
      await _logout();
      return;
    }

    setState(() => _index = i);
  }
  
  Future<void> _logout() async {
    final authVM = context.read<AuthVM>();
    // final storage = context.read<StorageService>();

    await authVM.logout();
    // await storage.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AppBottomNav(
        items: items,
        currentIndex: _index,
        onTap: _onNavTap,
      ),
    );
  }
}
