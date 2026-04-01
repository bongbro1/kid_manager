import 'package:flutter/material.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/user/user_profile_patch.dart';
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
    final userRepository = context.read<UserRepository>();
    final phone = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PickChildPhoneScreen()),
    );

    if (phone == null || phone.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      await userRepository.patchUserProfile(
        uid: widget.childId,
        patch: UserProfilePatch(phone: phone.trim()),
      );

      if (!mounted) return;
      Navigator.pop(context, phone.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).parentPhoneSaveFailed),
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
    final l10n = AppLocalizations.of(context);
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 22,
    );
    final screenWidth = MediaQuery.sizeOf(context).width;
    final phoneCircleSize = (screenWidth * 0.28).clamp(92.0, 110.0);
    final addCircleSize = (phoneCircleSize * 0.38).clamp(36.0, 42.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 18,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = constraints.maxWidth > 420
                  ? 420.0
                  : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                            width: phoneCircleSize,
                            height: phoneCircleSize,
                            decoration: const BoxDecoration(
                              color: Color(0xFF32D74B),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.call_rounded,
                              color: Colors.white,
                              size: phoneCircleSize * 0.5,
                            ),
                          ),
                          Positioned(
                            left: -4,
                            top: (phoneCircleSize - addCircleSize) / 2,
                            child: Container(
                              width: addCircleSize,
                              height: addCircleSize,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFCC00),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: addCircleSize * 0.66,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Text(
                        l10n.parentPhoneAddTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.parentPhoneAddSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                              : Text(
                                  l10n.parentPhoneAddButton,
                                  style: const TextStyle(
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
              );
            },
          ),
        ),
      ),
    );
  }
}
