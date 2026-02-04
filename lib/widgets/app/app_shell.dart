import 'package:flutter/material.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/views/auth/forgot_pass_screen.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/views/auth/signup_screen.dart';
import 'package:kid_manager/views/home/home_screen.dart';
import 'package:kid_manager/views/parent/app_management_screen.dart';
import 'package:kid_manager/views/personal_info_screen.dart';
import 'package:kid_manager/widgets/app/app_bottom_nav.dart';
import 'package:provider/provider.dart';

class ChildShell extends StatefulWidget {
  const ChildShell({super.key});

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> {
  int _index = 0;

  final items = const [
    BottomNavItem(iconAsset: 'assets/icons/location.svg'),
    BottomNavItem(iconAsset: 'assets/icons/sms.svg'),
    BottomNavItem(iconAsset: 'assets/icons/bell.svg'),
    BottomNavItem(iconAsset: 'assets/icons/bell.svg'),
    BottomNavItem(iconAsset: 'assets/icons/user_nav.svg'),
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

// class _ParentShellState extends State<ParentShell> {
//   int _index = 0;

//   final items = const [
//     BottomNavItem(iconAsset: 'assets/icons/location.svg'),
//     BottomNavItem(iconAsset: 'assets/icons/sms.svg'),
//     BottomNavItem(iconAsset: 'assets/icons/bell.svg'),
//     BottomNavItem(iconAsset: 'assets/icons/calendar.svg'),
//     BottomNavItem(iconAsset: 'assets/icons/user_nav.svg'),
//   ];

//   final pages = const [
//     AppManagementScreen(),
//   ];

//   Future<void> _onNavTap(int i) async {
//     final isLogoutItem = i == items.length - 1;

//     if (isLogoutItem) {
//       await _logout();
//       return;
//     }

//     setState(() => _index = i);
//   }
  
  // Future<void> _logout() async {
  //   final authVM = context.read<AuthVM>();
  //   // final storage = context.read<StorageService>();

  //   await authVM.logout();
  //   // await storage.clear();

  //   if (!mounted) return;

  //   Navigator.pushAndRemoveUntil(
  //     context,
  //     MaterialPageRoute(builder: (_) => const LoginScreen()),
  //     (route) => false,
  //   );
  // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(index: _index, children: pages),
//       bottomNavigationBar: AppBottomNav(
//         items: items,
//         currentIndex: _index,
//         onTap: _onNavTap,
//       ),
//     );
//   }
// }


class _ParentShellState extends State<ParentShell> {
  int _index = 0;

  late final items = const [
    BottomNavItem(iconAsset: 'assets/icons/location.svg'),
    BottomNavItem(iconAsset: 'assets/icons/sms.svg'),
    BottomNavItem(iconAsset: 'assets/icons/bell.svg'),
    BottomNavItem(iconAsset: 'assets/icons/calendar.svg'),
    BottomNavItem(iconAsset: 'assets/icons/user_nav.svg'),
  ];

  // mỗi tab 1 navigator key
  late final _navKeys = List.generate(items.length, (_) => GlobalKey<NavigatorState>());

  // root screen cho từng tab
  late final List<Widget> _rootPages = const [
    AppManagementScreen(),
    AppManagementScreen(),
    AppManagementScreen(),
    AppManagementScreen(),
    PersonalInfoScreen(),
  ];

  // tab navigator widget
  Widget _buildTab(int i) {
    return Navigator(
      key: _navKeys[i],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => _rootPages[i]),
    );
  }

  Future<void> _onNavTap(int i) async {
    if (i == _index) {
      // bấm lại tab hiện tại -> pop về root của tab đó
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = i);
  }

  Future<bool> _onWillPop() async {
    final nav = _navKeys[_index].currentState;
    if (nav == null) return true;

    if (nav.canPop()) {
      nav.pop();
      return false; // không thoát app, chỉ pop trong tab
    }
    return true; // đang ở root tab -> cho back thoát app
  }

  @override
  Widget build(BuildContext context) {
    final tabs = List.generate(items.length, (i) => _buildTab(i));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(index: _index, children: tabs),
        bottomNavigationBar: AppBottomNav(
          items: items,
          currentIndex: _index,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
