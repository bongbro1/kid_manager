import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
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
    return NotificationScreen(sources: sources, systemOnly: systemOnly);
  }
}
