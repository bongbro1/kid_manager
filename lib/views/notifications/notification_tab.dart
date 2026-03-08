import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/views/notifications/notification_screen.dart';

class NotificationTab extends StatelessWidget {
  final List<NotificationSource> sources;
  final bool systemOnly;

  const NotificationTab({
    super.key,
    required this.sources,
    this.systemOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final storageService = context.read<StorageService>();
    final uId = storageService.getString(StorageKeys.uid) ?? "";

    if (uId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return NotificationScreen(
      uid: uId,
      sources: sources,
      systemOnly: systemOnly,
    );
  }
}