import 'package:flutter/material.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState
    extends State<NotificationDebugScreen> {
  final _senderController = TextEditingController(text: "user_1");
  final _receiverController = TextEditingController(text: "user_2");
  final _titleController = TextEditingController(text: "Test Notification");
  final _bodyController = TextEditingController(text: "Hello from debug screen");
  final _familyController = TextEditingController();

  String _type = "message";
  bool _loading = false;

  Future<void> _sendUserToUser() async {
    setState(() => _loading = true);

    try {
      await NotificationService.sendUserToUser(
        senderId: _senderController.text.trim(),
        receiverId: _receiverController.text.trim(),
        type: _type,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        familyId: _familyController.text.trim().isEmpty
            ? null
            : _familyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Sent successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  Future<void> _sendSystem() async {
    setState(() => _loading = true);

    try {
      await NotificationService.sendSystem(
        receiverId: _receiverController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  Future<void> _sendChildAlert() async {
    setState(() => _loading = true);

    try {
      await NotificationService.sendChildAlert(
        childId: _senderController.text.trim(),
        parentId: _receiverController.text.trim(),
        type: _type,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        familyId: _familyController.text.trim().isEmpty
            ? null
            : _familyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚨 Child alert sent")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
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

  @override
  void dispose() {
    _senderController.dispose();
    _receiverController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Debug"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField("Sender ID", _senderController),
            _buildTextField("Receiver ID", _receiverController),
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