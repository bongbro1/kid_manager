import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:provider/provider.dart';

import '../../services/storage_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with RouteAware {
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  /// 🔥 CHẠY MỖI LẦN MÀN HÌNH ĐƯỢC SHOW LẠI
  @override
  void didPopNext() {
    debugPrint("Notification screen visible again");
    _init(); // reload lại
  }

  Future<void> _init() async {
    final storage = context.read<StorageService>();
    final uid = await storage.getString(StorageKeys.uid);

    if (uid != null && mounted) {
      context.read<NotificationVM>().listen(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationVM>();

    return Scaffold(
      appBar: AppBar(title: Text("Notifications (${vm.unreadCount})")),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vm.notifications.length,
              itemBuilder: (_, index) {
                final item = vm.notifications[index];

                return ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.body),
                  trailing: item.isRead
                      ? null
                      : const Icon(Icons.circle, size: 10),
                  onTap: () {
                    vm.markAsRead(item.id);
                  },
                  onLongPress: () {
                    vm.delete(item.id);
                  },
                );
              },
            ),
    );
  }
}
