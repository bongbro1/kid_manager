import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

class PickChildPhoneScreen extends StatefulWidget {
  const PickChildPhoneScreen({super.key});

  @override
  State<PickChildPhoneScreen> createState() => _PickChildPhoneScreenState();
}

class _PickChildPhoneScreenState extends State<PickChildPhoneScreen> {
  final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();
  bool _loading = false;

  Future<void> _pickPhoneFromContacts() async {
    setState(() => _loading = true);
    try {
      final contact = await _picker.selectContact();

      debugPrint('contact = $contact');
      debugPrint('selectedPhoneNumber = ${contact?.selectedPhoneNumber}');
      debugPrint('phoneNumbers = ${contact?.phoneNumbers}');

      if (contact == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      String? phone;

      if (contact.selectedPhoneNumber != null &&
          contact.selectedPhoneNumber!.trim().isNotEmpty) {
        phone = contact.selectedPhoneNumber!.trim();
      } else if (contact.phoneNumbers != null &&
          contact.phoneNumbers!.isNotEmpty) {
        phone = contact.phoneNumbers!.first.trim();
      }

      debugPrint('picked phone = $phone');

      if (phone == null || phone.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liên hệ này không có số điện thoại'),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, phone);
    } catch (e, st) {
      debugPrint('===== PICK CONTACT ERROR =====');
      debugPrint('error = $e');
      debugPrint('stack = $st');
      debugPrint('==============================');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy số điện thoại từ danh bạ: $e'),
        ),
      );
      setState(() => _loading = false);
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickPhoneFromContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Chọn số điện thoại',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: _pickPhoneFromContacts,
              icon: const Icon(Icons.contacts_rounded),
              label: const Text('Mở danh bạ'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ),
    );
  }
}