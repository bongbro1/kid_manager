import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'package:kid_manager/views/chat/family_group_chat_screen.dart';

class NotificationRouter {
  static void handle(BuildContext context, Map<String, dynamic> data) {
    final route = data['route']?.toString();
    final familyId = data['familyId']?.toString();
    final messageId = data['messageId']?.toString();

    debugPrint('[NotificationRouter] data=$data');

    if (route == 'family_group_chat' &&
        familyId != null &&
        familyId.isNotEmpty) {
      Navigator.of(context).push(
        AppPageTransitions.route(
          builder: (_) => FamilyGroupChatScreen(initialMessageId: messageId),
        ),
      );
      return;
    }

    debugPrint('[NotificationRouter] no matched route');
  }
}
