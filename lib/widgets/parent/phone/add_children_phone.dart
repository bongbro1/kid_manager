import 'package:flutter/material.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/widgets/parent/phone/pick_child_phone_screen.dart';
import 'package:provider/provider.dart';

class AddChildPhoneScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const AddChildPhoneScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<AddChildPhoneScreen> createState() => _AddChildPhoneScreenState();
}

class _AddChildPhoneScreenState extends State<AddChildPhoneScreen> {
  bool _saving = false;

  Future<void> _handleAddPhone() async {
    final phone = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const PickChildPhoneScreen(),
      ),
    );

    if (phone == null || phone.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      await context.read<UserRepository>().updateUserProfileByUid(
        uid: widget.childId,
        data: {
          'phone': phone.trim(),
        },
      );

      if (!mounted) return;
      Navigator.pop(context, phone.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu số điện thoại'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: Color(0xFF32D74B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                  Positioned(
                    left: -4,
                    top: 26,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFCC00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              const Text(
                'Thêm số điện thoại của con bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Liên lạc với con ngay cả khi điện thoại của con đang ở chế độ im lặng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleAddPhone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1683F8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Thêm vào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}