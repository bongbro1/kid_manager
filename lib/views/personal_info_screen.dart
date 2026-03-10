import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/features/sessionguard/session_guard.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/about_app_screen.dart';
import 'package:kid_manager/views/setting_pages/add_account_screen.dart';
import 'package:kid_manager/views/setting_pages/app_appearance_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';
import 'package:kid_manager/widgets/app/app_input_component.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/widgets/common/tappable_photo.dart';
import 'package:provider/provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool allowLocationTracking = false;
  bool _initialized = false;
  int _age = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      context.read<UserVm>().loadProfile(
        uid: authUid,
        caller: 'PersonalInfoScreen',
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final vm = context.read<UserVm>();
    final p = vm.profile;

    if (p != null) {
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone;
      _genderCtrl.text = p.gender;
      _dobCtrl.text = p.dob;
      _addressCtrl.text = p.address;

      allowLocationTracking = p.allowTracking;

      _age = calculateAgeFromDateString(p.dob);
    }
  }

  Future<void> _updateUserInfo() async {
    final dob = parseDateFromText(_dobCtrl.text);

    if (dob == null) {
      NotificationDialog.show(
        context,
        type: DialogType.error,
        title: "Thất bại",
        message: "Ngày sinh không hợp lệ",
      );
      return;
    }
    final vm = context.read<UserVm>();

    final ok = await vm.updateUserInfo(
      name: _nameCtrl.text,
      phone: _phoneCtrl.text,
      gender: _genderCtrl.text,
      dob: _dobCtrl.text,
      address: _addressCtrl.text,
      allowTracking: allowLocationTracking,
    );

    if (!mounted) return;

    if (ok) {
      NotificationDialog.show(
        context,
        type: DialogType.success,
        title: "Thành công",
        message: "Cập nhật thông tin thành công",
      );
      vm.listenProfile();
    } else {
      debugPrint("Update FAIL: ${vm.error}");
      // show snackbar/dialog nếu muốn
    }
  }

  Future<void> _onRefresh() async {
    context.read<UserVm>().listenProfile();
  }

  Future<void> _logout() async {
    final authVM = context.read<AuthVM>();
    final notiVM = context.read<NotificationVM>();
    final rootNav = Navigator.of(context, rootNavigator: true);

    await notiVM.clear();
    await authVM.logout();

    rootNav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SessionGuard()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserVm>();
    final p = vm.profile;

    if (p != null && !_initialized) {
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone;
      _genderCtrl.text = p.gender;
      _dobCtrl.text = p.dob;
      _addressCtrl.text = p.address;
      allowLocationTracking = p.allowTracking;
      _age = calculateAgeFromDateString(p.dob);
      _initialized = true;
    }

    if (vm.loading) {
      return const LoadingOverlay();
    }

    // if (p == null) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (!mounted) return;
    //     _logout();
    //   });

    //   return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // }

    final isChild = p?.role.toString() == "child";

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            /// ✅ HEADER (KHÔNG SCROLL)
            Row(
              children: [
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const MoreActionSheet(),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 14,
                    ),
                    child: AppIcon(
                      path: "assets/icons/menu.svg",
                      type: AppIconType.svg,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Thông tin cá nhân",
                      style: TextStyle(
                        color: Color(0xFF222B45),
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),

            /// ✅ PHẦN NÀY MỚI SCROLL
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      SizedBox(
                        width: 500,
                        height: 220,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 35,
                              child: Center(
                                child: tappablePhoto(
                                  context: context,
                                  vm: vm,
                                  url: p?.coverUrl,
                                  fallbackAsset: "assets/images/cover.png",
                                  onReplace: (index, file) {
                                    return vm.updateUserPhoto(
                                      file: file,
                                      type: UserPhotoType.cover,
                                    );
                                  },
                                  child: Image(
                                    image:
                                        ((p?.coverUrl ?? '').trim().isNotEmpty)
                                        ? NetworkImage(
                                            (p?.coverUrl ?? '').trim(),
                                          )
                                        : const AssetImage(
                                                "assets/images/cover.png",
                                              )
                                              as ImageProvider,
                                    width: 500,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 82,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x3F000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      tappablePhoto(
                                        context: context,
                                        vm: vm,
                                        url: p?.avatarUrl,
                                        fallbackAsset: "assets/images/u1.png",
                                        onReplace: (index, file) {
                                          return vm.updateUserPhoto(
                                            file: file,
                                            type: UserPhotoType.avatar,
                                          );
                                        },
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              78.5,
                                            ),
                                            border: Border.all(
                                              width: 2,
                                              color: const Color(0xFF5EC8F2),
                                            ),
                                            image: DecorationImage(
                                              image:
                                                  ((p?.avatarUrl ?? '')
                                                      .trim()
                                                      .isNotEmpty)
                                                  ? NetworkImage(
                                                      (p?.avatarUrl ?? '')
                                                          .trim(),
                                                    )
                                                  : const AssetImage(
                                                          "assets/images/u1.png",
                                                        )
                                                        as ImageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              p?.name ?? '',
                                              style: TextStyle(
                                                color: Color(0xFF212121),
                                                fontSize: 18,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w700,
                                                height: 1.11,
                                                letterSpacing: -0.24,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "$_age tuổi",
                                              style: TextStyle(
                                                color: Color(0xFF212121),
                                                fontSize: 13,
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w500,
                                                height: 1.69,
                                                letterSpacing: -0.41,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _updateUserInfo,
                                        child: Image.asset(
                                          "assets/images/source_edit.png",
                                          width: 18,
                                          height: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 18),

                            AppLabeledTextField(
                              label: "Họ và tên",
                              hint: "Nhập họ và tên",
                              controller: _nameCtrl,
                            ),

                            AppLabeledTextField(
                              label: "Số điện thoại",
                              hint: "+84 012345678",
                              controller: _phoneCtrl,
                            ),

                            AppLabeledTextField(
                              label: "Giới tính",
                              hint: "Nam",
                              controller: _genderCtrl,
                            ),

                            AppLabeledTextField(
                              label: "Ngày sinh",
                              hint: "12/12/2003",
                              controller: _dobCtrl,
                            ),

                            AppLabeledTextField(
                              label: "Địa chỉ",
                              hint: "Xã Điềm Thụy, Tỉnh Thái Nguyên",
                              controller: _addressCtrl,
                            ),

                            if (!isChild)
                              AppLabeledCheckbox(
                                label: "Quyền theo dõi",
                                text: "Cho phép đối phương theo dõi vị trí",
                                value: allowLocationTracking,
                                onChanged: (v) {
                                  setState(() {
                                    allowLocationTracking = v;
                                  });
                                  debugPrint("changed: $allowLocationTracking");
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- SHEET ----------------
class MoreActionSheet extends StatelessWidget {
  const MoreActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserVm>().profile?.role;
    final isParent = roleFromString(role ?? 'child') == UserRole.parent;

    return AppOverlaySheet(
      // height: 240,
      showHandle: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),

            SettingItem(
              title: "Giao diện ứng dụng",
              iconPath: "assets/icons/color_palette.svg",
              iconType: AppIconType.svg,
              iconSize: 20,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppAppearanceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            SettingItem(
              title: "About app",
              iconPath: "assets/icons/info.png",
              iconType: AppIconType.png,
              iconSize: 17,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                );
              },
            ),
            const SizedBox(height: 10),

            if (isParent) ...[
              SettingItem(
                title: "Thêm tài khoản",
                iconPath: "assets/icons/account.png",
                iconType: AppIconType.png,
                iconSize: 18,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddAccountScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            SettingItem(
              title: "Đăng xuất",
              iconPath: "assets/icons/log_out.png",
              iconType: AppIconType.png,
              iconSize: 17,
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 100), () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const ConfirmLogoutSheet(),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmLogoutSheet extends StatelessWidget {
  const ConfirmLogoutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> _logout() async {
      final authVM = context.read<AuthVM>();
      final notiVM = context.read<NotificationVM>();
      final rootNav = Navigator.of(context, rootNavigator: true);

      await notiVM.clear();
      await authVM.logout();

      rootNav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SessionGuard()),
        (_) => false,
      );
    }

    final vm = context.watch<AuthVM>();
    if (vm.error != null) {
      return Text(vm.error!);
    }

    return Stack(
      children: [
        AppOverlaySheet(
          height: 210,
          showHandle: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 345,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: const Color(0xFFEDF1F7),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Text(
                  'Bạn muốn đăng xuất?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF212121),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.38,
                    letterSpacing: -0.41,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          height: 50,
                          text: 'Hủy bỏ',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          backgroundColor: const Color(0xFFE6F5FF),
                          foregroundColor: const Color(0xFF3A7DFF),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: AppButton(
                          height: 50,
                          text: 'Xác nhận',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          onPressed: () async {
                            await _logout();
                          },
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (vm.loading) LoadingOverlay(),
      ],
    );
  }
}

class SettingItem extends StatelessWidget {
  final String title;
  final String iconPath;
  final AppIconType iconType;
  final double iconSize;
  final VoidCallback onTap;

  const SettingItem({
    super.key,
    required this.title,
    required this.iconPath,
    required this.iconType,
    required this.onTap,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AppIcon(path: iconPath, type: iconType, size: iconSize),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF212121),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  letterSpacing: -0.41,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
