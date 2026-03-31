import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/about_app_screen.dart';
import 'package:kid_manager/views/setting_pages/app_appearance_screen.dart';
import 'package:kid_manager/views/setting_pages/crop_photo_screen.dart';
import 'package:kid_manager/views/setting_pages/member_management_screen.dart';
import 'package:kid_manager/views/setting_pages/widgets/date_pick_widget.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';
import 'package:kid_manager/widgets/app/app_input_component.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/widgets/common/smart_network_image.dart';
import 'package:kid_manager/widgets/common/tappable_photo.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const _genderMaleValue = 'Nam';
  static const _genderFemaleValue = 'Nữ';
  static const _genderOtherValue = 'Khác';

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String? _selectedGender;
  bool allowLocationTracking = false;
  bool _initialized = false;
  int _age = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      final vm = context.read<UserVm>();

      final profile = await vm.loadProfile(
        uid: authUid,
        caller: 'PersonalInfoScreen',
      );

      if (!mounted || profile == null || _initialized) return;

      setState(() {
        _fillForm(profile);
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _fillForm(UserProfile p) {
    _nameCtrl.text = p.name;
    _phoneCtrl.text = p.phone;
    _selectedGender = p.gender.isNotEmpty ? p.gender : null;
    _dobCtrl.text = p.dob;
    _addressCtrl.text = p.address;
    allowLocationTracking = p.allowTracking;
    _age = calculateAgeFromDateString(p.dob);
    _initialized = true;
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
      gender: _selectedGender ?? _genderMaleValue,
      dob: _dobCtrl.text,
      address: _addressCtrl.text,
      allowTracking: allowLocationTracking,
    );

    if (!mounted) return;

    if (ok) {
      if (!mounted) return;

      NotificationDialog.show(
        context,
        type: DialogType.success,
        title: l10n.updateSuccessTitle,
        message: l10n.updateSuccessMessage,
      );
      vm.listenProfile();
      context.read<BirthdayViewModel>().refreshFamilyBirthdays(forceSync: true);
    } else {
      debugPrint("Update FAIL: ${vm.error}");
      // show snackbar/dialog nếu muốn
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 10, now.month, now.day);

    final parsed = _parseDate(_dobCtrl.text);
    if (parsed != null) {
      initial = parsed;
    }

    final date = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => WheelDatePicker(initialDate: initial),
    );

    if (date != null) {
      _dobCtrl.text = "${date.day}/${date.month}/${date.year}";
    }
  }

  DateTime? _parseDate(String text) {
    try {
      if (text.isEmpty) return null;

      final parts = text.split("/");
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;

      return DateTime(year, month, day);
    } catch (_) {
      return null;
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
    if (vm.loading) {
      return const LoadingOverlay();
    }

    final isAdultManager = p?.isAdultManager == true;
    final isChild = p?.role == UserRole.child;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 60,
        leading: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              RawDialogRoute<void>(
                barrierDismissible: true,
                barrierLabel: l10n.birthdayCloseButton,
                barrierColor: Colors.black.withOpacity(0.12),
                transitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (routeContext, animation, secondaryAnimation) {
                  return const MoreActionSheet();
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            child: AppIcon(
              path: "assets/icons/menu.svg",
              type: AppIconType.svg,
              size: 20,
            ),
          ),
        ),
        title: Text(
          l10n.personalInfoTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: const [SizedBox(width: 60)],
      ),
      body: Column(
        children: [
          /// BODY
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
                      height: 210,
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
                                cropType: CropPhotoType.cover,
                                onReplace: (index, file) async {
                                  vm.updateLocalPhoto(
                                    file,
                                    UserPhotoType.cover,
                                  );
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
                              child: Builder(
                                builder: (context) {
                                  return Container(
                                    height: 82,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scheme.shadow.withOpacity(
                                            0.15,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
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
                                          cropType: CropPhotoType.avatar,
                                          onReplace: (index, file) async {
                                            vm.updateLocalPhoto(
                                              file,
                                              UserPhotoType.avatar,
                                            );
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
                                                color: scheme.primary,
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
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: scheme.onSurface,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                l10n.yearsOld.replaceFirst(
                                                  '%d',
                                                  _age.toString(),
                                                ),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        GestureDetector(
                                          onTap: _updateUserInfo,
                                          child: Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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

                          AppLabeledDropdownField<String>(
                            label: l10n.genderLabel,
                            hint: l10n.genderHint,
                            value: _selectedGender,
                            items: [
                              DropdownMenuEntry(
                                value: _genderMaleValue,
                                label: l10n.genderMaleOption,
                              ),
                              DropdownMenuEntry(
                                value: _genderFemaleValue,
                                label: l10n.genderFemaleOption,
                              ),
                              DropdownMenuEntry(
                                value: _genderOtherValue,
                                label: l10n.genderOtherOption,
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                          ),
                          AppLabeledTextField(
                            label: l10n.birthDateLabel,
                            hint: l10n.birthDateHint,
                            controller: _dobCtrl,
                            readOnly: true,
                            onTap: pickDate,
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                            ),
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

                          if (isAdultManager) ...[
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                final theme = Theme.of(context);
                                final scheme = theme.colorScheme;

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: scheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: scheme.outline.withOpacity(0.3),
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
                                          color: scheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.manage_accounts,
                                          color: scheme.onPrimary,
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.personalInfoManageAccountsTitle,
                                              style: TextStyle(
                                                color: scheme.onSurface,
                                                fontSize: 16,
                                                fontFamily: 'Public Sans',
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              l10n.personalInfoManageAccountsSubtitle,
                                              style: TextStyle(
                                                color: scheme.onSurface,
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
                                            color: scheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            l10n.personalInfoDetailsButton,
                                            style: TextStyle(
                                              color: scheme.onPrimary,
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
    );
  }
}

/// ---------------- SHEET ----------------
class MoreActionSheet extends StatelessWidget {
  const MoreActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserVm>().profile;
    final showNotificationDebug = profile?.role == UserRole.parent;

    return AppOverlaySheet(
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
              title: AppLocalizations.of(context).logoutTitle,
              iconPath: "assets/icons/log_out.png",
              iconType: AppIconType.png,
              iconSize: 17,
              onTap: () {
                final rootNavigator = Navigator.of(
                  context,
                  rootNavigator: true,
                );
                rootNavigator.pushReplacement(
                  RawDialogRoute<void>(
                    barrierDismissible: true,
                    barrierLabel: AppLocalizations.of(
                      context,
                    ).birthdayCloseButton,
                    barrierColor: Colors.transparent,
                    transitionDuration: const Duration(milliseconds: 280),
                    pageBuilder: (routeContext, animation, secondaryAnimation) {
                      return const ConfirmLogoutSheet();
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
      if (rootNav.mounted && rootNav.canPop()) {
        rootNav.pop();
      }
    }

    final vm = context.watch<AuthVM>();
    if (vm.error != null) {
      return Text(
        vm.error!,
        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
      );
    }

    return Stack(
      children: [
        AppOverlaySheet(
          showHandle: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                /// divider
                Container(
                  width: 345,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: scheme.outline),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  l10n.confirmLogoutQuestion,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
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
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.primary,
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
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (vm.loading) const LoadingOverlay(),
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
  final Color? iconColor;

  const SettingItem({
    super.key,
    required this.title,
    required this.iconPath,
    required this.iconType,
    required this.onTap,
    this.iconSize = 20,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AppIcon(
              path: iconPath,
              type: iconType,
              size: iconSize,
              color: iconColor ?? scheme.onSurfaceVariant,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
