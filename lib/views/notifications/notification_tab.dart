import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/notifications/notification_screen.dart';

class NotificationTab extends StatefulWidget {
  final List<NotificationSource> sources;
  final bool systemOnly;

  const NotificationTab({
    super.key,
    required this.sources,
    this.systemOnly = false,
  });

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  String? _uidFromStorage;
  bool _loadingUid = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureUid();
  }

  Future<void> _ensureUid() async {
    if (_loadingUid) return;

    // ✅ KHÔNG dùng context.select ngoài build
    final uidFromUserVm = context.read<UserVm>().me?.uid;
    if (uidFromUserVm != null && uidFromUserVm.isNotEmpty) return;

    if (_uidFromStorage != null && _uidFromStorage!.isNotEmpty) return;

    _loadingUid = true;
    try {
      final storage = context.read<StorageService>();
      final uid = await storage.getString(StorageKeys.uid);

      if (!mounted) return;
      setState(() => _uidFromStorage = uid);
    } finally {
      _loadingUid = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ select chỉ dùng trong build
    final uid = context.select<UserVm, String?>((vm) => vm.me?.uid);
    final finalUid = (uid != null && uid.isNotEmpty) ? uid : (_uidFromStorage ?? "");

    if (finalUid.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return NotificationScreen(
      uid: finalUid,
      sources: widget.sources,
      systemOnly: widget.systemOnly,
    );
  }
}