import 'package:flutter/material.dart';
import 'package:kid_manager/repositories/user_repository.dart';
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

  String _type = "message";
  bool _loading = false;

  Future<void> _sendUserToUser() async {
    setState(() => _loading = true);

    try {
      final payload = {
        "senderId": _selectedSenderId!,
        "receiverId": _selectedReceiverId!,
        "type": _type,
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
        familyId: payload["familyId"] as String?,
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
      await NotificationService.sendSystem(
        receiverId: _selectedReceiverId!,
        type: _type,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ System notification sent")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => _loading = false);
  }

  Future<void> _sendChildAlert() async {
    setState(() => _loading = true);

    try {
      // await NotificationService.sendChildAlert(
      //   childId: _senderController.text.trim(),
      //   parentId: _receiverController.text.trim(),
      //   type: _type,
      //   title: _titleController.text.trim(),
      //   body: _bodyController.text.trim(),
      //   familyId: _familyController.text.trim().isEmpty
      //       ? null
      //       : _familyController.text.trim(),
      // );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🚨 Child alert sent")));
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

            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: "Notification Type",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "message", child: Text("message")),
                DropdownMenuItem(value: "alert", child: Text("alert")),
                DropdownMenuItem(value: "system", child: Text("system")),
              ],
              onChanged: (value) {
                setState(() {
                  _type = value ?? "message";
                });
              },
            ),

            const SizedBox(height: 20),

            if (_loading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _sendUserToUser,
                child: const Text("👤 Send User → User"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sendSystem,
                child: const Text("⚙️ Send System → User"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sendChildAlert,
                child: const Text("🚨 Send Child → Parent"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
