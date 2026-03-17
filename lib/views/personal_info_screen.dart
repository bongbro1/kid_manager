import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/features/sessionguard/session_guard.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/about_app_screen.dart';
import 'package:kid_manager/views/setting_pages/add_account_screen.dart';
import 'package:kid_manager/views/setting_pages/app_appearance_screen.dart';
import 'package:kid_manager/views/setting_pages/member_management_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';
import 'package:kid_manager/widgets/app/app_input_component.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/widgets/common/smart_network_image.dart';
import 'package:kid_manager/widgets/common/tappable_photo.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/views/language_selector_sheet.dart';
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _genderCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateUserInfo() async {
    final dob = parseDateFromText(_dobCtrl.text);
    final l10n = AppLocalizations.of(context);

    if (dob == null) {
      NotificationDialog.show(
        context,
        type: DialogType.error,
        title: l10n.updateErrorTitle,
        message: l10n.invalidBirthDate,
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
        title: l10n.updateSuccessTitle,
        message: l10n.updateSuccessMessage,
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

  Widget _buildCoverPhoto(String? coverUrl) {
    return SmartNetworkImage(
      imageUrl: coverUrl,
      fallbackAsset: "assets/images/cover.png",
      width: 500,
      height: 200,
      fit: BoxFit.cover,
    );
  }

  Widget _buildAvatarPhoto(String? avatarUrl) {
    return SmartNetworkImage(
      imageUrl: avatarUrl,
      fallbackAsset: "assets/images/u1.png",
      width: 60,
      height: 60,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    final isParent = p?.role.toString() == roleToString(UserRole.parent);
    final isChild = p?.role.toString() == roleToString(UserRole.child);

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
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.personalInfoTitle,
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
                                  child: _buildCoverPhoto(p?.coverUrl),
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
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              width: 2,
                                              color: const Color(0xFF5EC8F2),
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: _buildAvatarPhoto(
                                              p?.avatarUrl,
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
                                              l10n.yearsOld.replaceFirst(
                                                '%d',
                                                _age.toString(),
                                              ),
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
                              label: l10n.fullNameLabel,
                              hint: l10n.fullNameHint,
                              controller: _nameCtrl,
                            ),

                            AppLabeledTextField(
                              label: l10n.phoneLabel,
                              hint: l10n.phoneHint,
                              controller: _phoneCtrl,
                            ),

                            AppLabeledTextField(
                              label: l10n.genderLabel,
                              hint: l10n.genderHint,
                              controller: _genderCtrl,
                            ),

                            AppLabeledTextField(
                              label: l10n.birthDateLabel,
                              hint: l10n.birthDateHint,
                              controller: _dobCtrl,
                            ),

                            AppLabeledTextField(
                              label: l10n.addressLabel,
                              hint: l10n.addressHint,
                              controller: _addressCtrl,
                            ),

                            if (!isChild)
                              AppLabeledCheckbox(
                                label: l10n.locationTrackingLabel,
                                text: l10n.allowLocationTrackingText,
                                value: allowLocationTracking,
                                onChanged: (v) {
                                  setState(() {
                                    allowLocationTracking = v;
                                  });
                                  debugPrint("changed: $allowLocationTracking");
                                },
                              ),

                            if (isParent) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E5E5), // màu viền
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E90FA),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.manage_accounts,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Quản lý tài khoản',
                                            style: TextStyle(
                                              color: Color(0xFF3E3E3E),
                                              fontSize: 16,
                                              fontFamily: 'Public Sans',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Quản lý tài khoản của thành viên',
                                            style: TextStyle(
                                              color: Color(0xFF3E3E3E),
                                              fontSize: 12,
                                              fontFamily: 'Public Sans',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MemberManagementScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E90FA),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Chi tiết',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
              title: AppLocalizations.of(context).appAppearanceTitle,
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
              title: AppLocalizations.of(context).aboutAppTitle,
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
            SettingItem(
              title: AppLocalizations.of(context).languageSetting,
              iconPath: "assets/icons/menu.svg",
              iconType: AppIconType.svg,
              iconSize: 20,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const LanguageSelectorSheet(),
                );
              },
            ),
            const SizedBox(height: 10),
            SettingItem(
              title: AppLocalizations.of(context).logoutTitle,
              iconPath: "assets/icons/log_out.png",
              iconType: AppIconType.png,
              iconSize: 17,
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (!context.mounted) return;
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
    final l10n = AppLocalizations.of(context);

    Future<void> logout() async {
      final authVM = context.read<AuthVM>();
      final userVm = context.read<UserVm>();
      final appManagementVm = context.read<AppManagementVM>();
      final parentLocationVm = context.read<ParentLocationVm>();
      final notiVM = context.read<NotificationVM>();
      final rootNav = Navigator.of(context, rootNavigator: true);

      await parentLocationVm.stopWatchingAllChildren();
      await parentLocationVm.stopMyLocation();
      await notiVM.clear();
      await userVm.clear();
      await appManagementVm.clear();
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
                  l10n.confirmLogoutQuestion,
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
                          text: l10n.cancelButton,
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
                          text: l10n.confirmButton,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          onPressed: () async {
                            await logout();
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
