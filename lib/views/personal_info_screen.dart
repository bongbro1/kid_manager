import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/features/sessionguard/session_guard.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/imgbb_service.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/about_app_screen.dart';
import 'package:kid_manager/views/setting_pages/add_account_screen.dart';
import 'package:kid_manager/views/setting_pages/app_appearance_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';
import 'package:kid_manager/widgets/app/app_image_modal.dart';
import 'package:kid_manager/widgets/app/app_input_component.dart';
import 'package:kid_manager/widgets/app/app_notice_card.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';
import 'package:kid_manager/widgets/common/notification_modal.dart';
import 'package:provider/provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with RouteAware, WidgetsBindingObserver {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool allowLocationTracking = false;
  int _age = 0;

  late VoidCallback _tabListener;
  bool _didBind = false;

  DateTime _lastLoadAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isTargetTab =>
      activeTabNotifier.value == 3 || activeTabNotifier.value == 5;

  bool get _isRouteCurrent => (ModalRoute.of(context)?.isCurrent ?? false);

  Future<void> _safeLoadProfile({bool force = false}) async {
    debugPrint("==== _safeLoadProfile CALLED ====");
    debugPrint("mounted: $mounted");
    debugPrint("_isTargetTab: $_isTargetTab");
    debugPrint("_isRouteCurrent: $_isRouteCurrent");
    debugPrint("force: $force");

    if (!mounted) {
      debugPrint("RETURN: not mounted");
      return;
    }

    if (!_isTargetTab) {
      debugPrint("RETURN: not target tab");
      return;
    }

    if (!_isRouteCurrent) {
      debugPrint("RETURN: route not current");
      return;
    }

    final vm = context.read<UserVm>();

    if (vm.loading) {
      debugPrint("RETURN: vm is loading");
      return;
    }

    final now = DateTime.now();
    if (!force && now.difference(_lastLoadAt) < const Duration(seconds: 3)) {
      debugPrint("RETURN: blocked by TTL");
      return;
    }

    _lastLoadAt = now;

    debugPrint(">>> CALLING loadProfile()");
    await vm.loadProfile();

    debugPrint(">>> PROFILE LOADED");
    debugPrint("Profile: ${vm.profile}");
    debugPrint("Avatar: ${vm.profile?.avatarUrl}");
    debugPrint("Cover: ${vm.profile?.coverUrl}");
    debugPrint("=================================");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabListener = () {
      // Khi chuyển tab sang 3/5 (value thay đổi) => load
      if (_isTargetTab) {
        _safeLoadProfile(force: true);
      }
    };
    activeTabNotifier.addListener(_tabListener);

    // Load lần đầu sau frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _safeLoadProfile(force: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    activeTabNotifier.removeListener(_tabListener);
    if (_didBind) routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didBind) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        routeObserver.subscribe(this, route);
        _didBind = true;
      }
    }
  }

  @override
  void didPopNext() {
    // Quay lại từ màn khác => refresh
    _safeLoadProfile(force: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App resume => refresh
    if (state == AppLifecycleState.resumed) {
      _safeLoadProfile(force: true);
    }
  }

  Future<void> _updateUserInfo() async {
    final dob = parseDateFromText(_dobCtrl.text);

    if (dob == null) {
      NotificationModal.show(
        context,
        child: AppNoticeCard(
          type: AppNoticeType.error,
          message: 'Ngày sinh không hợp lệ',
        ),
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
      NotificationModal.show(
        context,
        child: AppNoticeCard(
          type: AppNoticeType.success,
          message: 'Sửa thông tin thành công',
        ),
      );
      await vm.loadProfile();
    } else {
      debugPrint("Update FAIL: ${vm.error}");
      // show snackbar/dialog nếu muốn
    }
  }

  Widget tappablePhoto({
    required BuildContext context,
    required UserVm vm,
    required String? url,
    required String fallbackAsset,
    required UserPhotoType type,
    required Widget child, // widget hiển thị ảnh (Container/Image/...)
  }) {
    final u = (url ?? '').trim();
    final provider = u.isNotEmpty
        ? NetworkImage(u)
        : AssetImage(fallbackAsset) as ImageProvider;

    return GestureDetector(
      onTap: () {
        showImageModal(
          context,
          images: [provider],
          onReplace: (index, file) async {
            final ok = await vm.updateUserPhoto(file: file, type: type);
            if (!ok) {
              NotificationModal.show(
                context,
                child: AppNoticeCard(
                  type: AppNoticeType.error,
                  message: vm.error ?? 'Cập nhật ảnh thất bại',
                ),
              );
            }
          },
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserVm>();
    final p = vm.profile;
    if (p == null) {
      return const SizedBox();
    }

    final isChild = p.role.toString() == "child"; // 👈 đặt ở đây
    _nameCtrl.text = p.name;
    _phoneCtrl.text = p.phone;
    _genderCtrl.text = p.gender;
    _dobCtrl.text = p.dob;
    _addressCtrl.text = p.address;
    allowLocationTracking = p.allowTracking;

    _age = calculateAgeFromDateString(p.dob);

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
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
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                          left: 14,
                          right: 14,
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

                const SizedBox(height: 16),

                SizedBox(
                  width: 500,
                  height: 235,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ẢNH (đặt trước để nằm dưới)
                      // Positioned(
                      //   left: 0,
                      //   right: 0,
                      //   bottom: 25, // chỉnh vị trí ảnh (nằm trên card)
                      //   child: Image.asset(
                      //     "assets/images/cover.png",
                      //     width: 120,
                      //     height: 230,
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 25,
                        child: Center(
                          child: tappablePhoto(
                            context: context,
                            vm: vm,
                            url: p.coverUrl,
                            fallbackAsset: "assets/images/cover.png",
                            type: UserPhotoType.cover,
                            child: Image(
                              image: ((p.coverUrl ?? '').trim().isNotEmpty)
                                  ? NetworkImage((p.coverUrl ?? '').trim())
                                  : const AssetImage("assets/images/cover.png")
                                        as ImageProvider,
                              // width: 500,
                              height: 230,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 350,
                          height: 82,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
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
                                url: p.avatarUrl,
                                fallbackAsset: "assets/images/u1.png",
                                type: UserPhotoType.avatar,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(78.5),
                                    border: Border.all(
                                      width: 2,
                                      color: const Color(0xFF5EC8F2),
                                    ),
                                    image: DecorationImage(
                                      image:
                                          ((p.avatarUrl ?? '')
                                              .trim()
                                              .isNotEmpty)
                                          ? NetworkImage(
                                              (p.avatarUrl ?? '').trim(),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Label
                AppLabeledTextField(
                  label: "Họ và tên",
                  hint: "Nhập họ và tên",
                  controller: _nameCtrl,
                ),
                // Label
                AppLabeledTextField(
                  label: "Số điện thoại",
                  hint: "+84 012345678",
                  controller: _phoneCtrl,
                ),
                // Label
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
                    onChanged: (v) => setState(() => allowLocationTracking = v),
                  ),
              ],
            ),
          ),
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

    return AppOverlaySheet(
      // height: 240,
      showHandle: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
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

            if (roleFromString(role!) == UserRole.parent) ...[
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
      final rootNav = Navigator.of(context, rootNavigator: true);

      await authVM.logout();

      rootNav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SessionGuard()),
        (_) => false,
      );
    }

    return AppOverlaySheet(
      height: 220,
      showHandle: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton(
                    width: 167,
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
                  AppButton(
                    width: 167,
                    height: 50,
                    text: 'Xác nhận',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    onPressed: () async {
                      Navigator.pop(context);
                      await Future.delayed(const Duration(milliseconds: 150));
                      await _logout();
                    },
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
