import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_payload.dart';
import 'package:kid_manager/models/notifications/removed_app_data.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String? _selectedSenderId;
  String? _selectedReceiverId;
  final _titleController = TextEditingController(text: "Test Notification");
  final _bodyController = TextEditingController(
    text: "Hello from debug screen",
  );

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<UserVm>().loadUsers();
    });
  }

  final _familyController = TextEditingController();

  NotificationType _selectedType = NotificationType.system;
  bool _loading = false;

  Future<void> _sendUserToUser() async {
    setState(() => _loading = true);

    try {
      final payload = {
        "senderId": _selectedSenderId!,
        "receiverId": _selectedReceiverId!,
        "type": _selectedType.value,
        "title": _titleController.text.trim(),
        "body": _bodyController.text.trim(),
        "familyId": _familyController.text.trim().isEmpty
            ? null
            : _familyController.text.trim(),
      };

      debugPrint("========== DEBUG SEND ==========");
      debugPrint(payload.toString());
      debugPrint("receiverId length: ${payload["receiverId"]?.length}");
      debugPrint("================================");

      await NotificationService.sendUserToUser(
        senderId: payload["senderId"] as String,
        receiverId: payload["receiverId"] as String,
        type: payload["type"] as String,
        title: payload["title"] as String,
        body: payload["body"] as String,
        familyId: payload["familyId"],
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Sent successfully")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => _loading = false);
  }

  Future<void> _sendSystem() async {
    setState(() => _loading = true);

    try {
      Map<String, dynamic>? data;

      /// 🔹 Nếu là appRemoved
      if (_selectedType == NotificationType.appRemoved) {
        final childId = 'U5mE7n6SR5dZcYIlH9vTKqKbSVr2';
        final appName = 'kid_manager';
        final childName = 'Bông';
        final packageName = 'com.example.kid_manager';

        final removedData = RemovedAppData(
          childId: childId,
          childName: childName,
          packageName: packageName,
          appName: appName,
          removedAt: DateFormat("HH:mm:ss").format(DateTime.now()),
        );

        data = removedData.toMap();
      } else {
        /// 🔹 các loại khác
        data = {"debug": true};
      }

      final payload = NotificationPayload(
        receiverId: _selectedReceiverId!,
        type: _selectedType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        data: data,
      );

      debugPrint("========== DEBUG SYSTEM SEND ==========");
      debugPrint("receiverId: ${payload.receiverId}");
      debugPrint("type: ${payload.type}");
      debugPrint("title: ${payload.title}");
      debugPrint("body: ${payload.body}");
      debugPrint("data: ${payload.data}");
      debugPrint("=======================================");

      await NotificationService.sendSystem(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ System notification sent")),
        );
      }
    } catch (e, stack) {
      debugPrint("ERROR SEND SYSTEM: $e");
      debugPrint(stack.toString());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _testSubscription(SubscriptionStatus status) async {
    if (_selectedReceiverId == null) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedReceiverId)
          .set({
            'subscription': {
              'plan': SubscriptionPlan.pro.wireValue,
              'status': status.wireValue,
              'startAt': Timestamp.fromDate(DateTime.now()),
              'endAt': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 30)),
              ),
              'isTrial': status == SubscriptionStatus.trial,
              'autoRenew': true,
              'productId': 'pro_monthly',
              'platform': 'android',
              'updatedAt': FieldValue.serverTimestamp(),
            },
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subscription status → $status")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => _loading = false);
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildUserDropdown({
    required String label,
    required String? value,
    required List<UserItem> users,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: users.map((user) {
          return DropdownMenuItem<String>(
            value: user.uid,
            child: Text(user.displayName),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserVm>();

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Notification Debug")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserDropdown(
              label: "Sender",
              value: _selectedSenderId,
              users: vm.users,
              onChanged: (value) {
                setState(() {
                  _selectedSenderId = value;
                });
              },
            ),

            _buildUserDropdown(
              label: "Receiver",
              value: _selectedReceiverId,
              users: vm.users,
              onChanged: (value) {
                setState(() {
                  _selectedReceiverId = value;
                });
              },
            ),

            _buildTextField("Title", _titleController),
            _buildTextField("Body", _bodyController),
            _buildTextField("Family ID (optional)", _familyController),

            const SizedBox(height: 12),

            DropdownButtonFormField<NotificationType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: "Type",
                border: OutlineInputBorder(),
              ),
              items: NotificationType.values.map((type) {
                return DropdownMenuItem<NotificationType>(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedType = value;
                });
              },
            ),

            const SizedBox(height: 20),

            if (_loading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: () async {
                  await LocalNotificationService.show(
                    title: 'Test local',
                    body: 'Tap me',
                    payload: jsonEncode({
                      "notificationId": "06eloLbzICVdapzFdDF0",
                      "type": "test",
                    }),
                  );
                },
                child: const Text('Show test notification'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await LocalNotificationService.show(
                    title: 'Tracking alert test',
                    body: 'This should appear on the tracking_alerts channel.',
                    channelId: LocalNotificationService.generalChannelId,
                    payload: jsonEncode({
                      "type": "tracking",
                      "eventKey": "tracking.location_service_off.parent",
                      "message":
                          "Please turn on GPS or Location Services on the device so location updates can continue.",
                    }),
                  );
                },
                child: const Text('Show tracking channel notification'),
              ),
              ElevatedButton(
                onPressed: _sendSystem,
                child: const Text("⚙️ Send System → User"),
              ),
              const SizedBox(height: 20),

              const Text(
                "Subscription Test",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () => _testSubscription(SubscriptionStatus.trial),
                child: const Text("🧪 Start Trial"),
              ),

              ElevatedButton(
                onPressed: () => _testSubscription(SubscriptionStatus.active),
                child: const Text("✅ Activate Subscription"),
              ),

              ElevatedButton(
                onPressed: () => _testSubscription(SubscriptionStatus.expired),
                child: const Text("⛔ Expire Subscription"),
              ),

              ElevatedButton(
                onPressed: () => _testSubscription(SubscriptionStatus.canceled),
                child: const Text("🚫 Cancel Subscription"),
              ),

              ElevatedButton(
                onPressed: () =>
                    _testSubscription(SubscriptionStatus.paymentFailed),
                child: const Text("💳 Payment Failed"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
