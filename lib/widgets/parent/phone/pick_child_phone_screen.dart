import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class PickChildPhoneScreen extends StatefulWidget {
  const PickChildPhoneScreen({super.key});

  @override
  State<PickChildPhoneScreen> createState() => _PickChildPhoneScreenState();
}

class _PickChildPhoneScreenState extends State<PickChildPhoneScreen> {
  final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();
  bool _loading = false;

  Future<void> _pickPhoneFromContacts() async {
    final l10n = AppLocalizations.of(context);

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
          SnackBar(
            content: Text(l10n.parentPhoneContactHasNoNumber),
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
          content: Text(l10n.parentPhonePickFailed('$e')),
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          l10n.parentPhonePickTitle,
          style: const TextStyle(
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
                    label: Text(l10n.parentPhoneOpenContactsButton),
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
