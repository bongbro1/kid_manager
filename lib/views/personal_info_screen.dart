import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
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
import 'package:kid_manager/widgets/common/smart_network_image.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/common/tappable_photo.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final vm = context.read<UserVm>();

    try {
      final profile = await vm.loadProfile(
        uid: authUid,
        caller: 'PersonalInfoScreen',
      );

      if (!mounted) return;

      if (profile != null && !_initialized) {
        setState(() {
          _fillForm(profile);
          _initialized = true;
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    }
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

    if (ok) {
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
    await context.read<UserVm>().refreshProfile();
  }

  Widget _buildCoverPhoto(String? coverUrl) {
    return SmartNetworkImage(
      imageUrl: coverUrl,
      fallbackAsset: "assets/images/cover.png",
      width: double.infinity,
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

  Widget _buildProfileHeaderSkeleton() {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 35,
          child: Container(
            height: 170,
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 82,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHighest,
                      border: Border.all(width: 2, color: scheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<UserVm>();
    final p = vm.profile;
    final isAdultManager = p?.isAdultManager == true;
    final isChild = p?.role == UserRole.child;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 12,
      regular: 16,
    );
    const compactLabelSpacing = 6.0;
    const compactTextFieldMinHeight = 50.0;
    const compactDropdownFieldHeight = 50.0;
    const compactDropdownMinHeight = 50.0;
    const compactTextFieldPadding = EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    );
    const compactDropdownPadding = EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 60,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              RawDialogRoute<void>(
                barrierDismissible: true,
                barrierLabel: l10n.birthdayCloseButton,
                barrierColor: Colors.black.withValues(alpha: 0.12),
                transitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (routeContext, animation, secondaryAnimation) {
                  return const MoreActionSheet();
                },
              ),
            );
          },
          // borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.menu, size: 26, color: scheme.onSurface),
          ),
        ),
        title: Text(
          l10n.personalInfoTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
          ),
        ),
        actions: const [SizedBox(width: 60)],
      ),
      body: Skeletonizer(
        enabled: _isInitializing,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 190,
                        child: _isInitializing
                            ? _buildProfileHeaderSkeleton()
                            : Skeleton.ignore(
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
                                          fallbackAsset:
                                              "assets/images/cover.png",
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
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Builder(
                                          builder: (context) {
                                            return Container(
                                              height: 82,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: scheme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: scheme.shadow
                                                        .withOpacity(0.15),
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
                                                    fallbackAsset:
                                                        "assets/images/u1.png",
                                                    cropType:
                                                        CropPhotoType.avatar,
                                                    onReplace:
                                                        (index, file) async {
                                                          vm.updateLocalPhoto(
                                                            file,
                                                            UserPhotoType
                                                                .avatar,
                                                          );
                                                          return vm
                                                              .updateUserPhoto(
                                                                file: file,
                                                                type:
                                                                    UserPhotoType
                                                                        .avatar,
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
                                                        child:
                                                            _buildAvatarPhoto(
                                                              p?.avatarUrl,
                                                            ),
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 14),

                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          p?.name ?? '',
                                                          style: theme
                                                              .textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                color: scheme
                                                                    .onSurface,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: Theme.of(context)
                                                                    .appTypography
                                                                    .screenTitle
                                                                    .fontSize!,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          l10n.yearsOld
                                                              .replaceFirst(
                                                                '%d',
                                                                _age.toString(),
                                                              ),
                                                          style: theme
                                                              .textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color: scheme
                                                                    .onSurfaceVariant,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: _updateUserInfo,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Ink(
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .transparent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          child: Icon(
                                                            Icons.edit,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
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
                      ),

                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),

                            AppLabeledTextField(
                              label: l10n.fullNameLabel,
                              hint: l10n.fullNameHint,
                              controller: _nameCtrl,
                              minFieldHeight: compactTextFieldMinHeight,
                              labelBottomSpacing: compactLabelSpacing,
                              contentPadding: compactTextFieldPadding,
                            ),

                            AppLabeledTextField(
                              label: l10n.phoneLabel,
                              hint: l10n.phoneHint,
                              controller: _phoneCtrl,
                              minFieldHeight: compactTextFieldMinHeight,
                              labelBottomSpacing: compactLabelSpacing,
                              contentPadding: compactTextFieldPadding,
                            ),

                            AppLabeledDropdownField<String>(
                              label: l10n.genderLabel,
                              hint: l10n.genderHint,
                              value: _selectedGender,
                              fieldHeight: compactDropdownFieldHeight,
                              minFieldHeight: compactDropdownMinHeight,
                              labelBottomSpacing: compactLabelSpacing,
                              contentPadding: compactDropdownPadding,
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
                              minFieldHeight: compactTextFieldMinHeight,
                              labelBottomSpacing: compactLabelSpacing,
                              contentPadding: compactTextFieldPadding,
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                size: 18,
                              ),
                            ),

                            AppLabeledTextField(
                              label: l10n.addressLabel,
                              hint: l10n.addressHint,
                              controller: _addressCtrl,
                              minFieldHeight: compactTextFieldMinHeight,
                              labelBottomSpacing: compactLabelSpacing,
                              contentPadding: compactTextFieldPadding,
                            ),

                            if (!isChild)
                              AppLabeledCheckbox(
                                label: l10n.locationTrackingLabel,
                                text: l10n.allowLocationTrackingText,
                                value: allowLocationTracking,
                                labelBottomSpacing: compactLabelSpacing,
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
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: scheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: scheme.outline.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 36,
                                          width: 36,
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: scheme.onSurface,
                                                      fontSize:
                                                          Theme.of(context)
                                                              .appTypography
                                                              .itemTitle
                                                              .fontSize!,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                l10n.personalInfoManageAccountsSubtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: scheme.onSurface,
                                                  fontSize: Theme.of(context)
                                                      .appTypography
                                                      .supporting
                                                      .fontSize!,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: scheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              l10n.personalInfoDetailsButton,
                                              style: TextStyle(
                                                color: scheme.onPrimary,
                                                fontSize: Theme.of(
                                                  context,
                                                ).appTypography.body.fontSize!,
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
      ),
    );
  }
}

/// ---------------- SHEET ----------------
class MoreActionSheet extends StatelessWidget {
  const MoreActionSheet({super.key});

  void _navigateFromSheet(BuildContext context, Widget page) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    rootNavigator.pop();

    // Wait one tick so the sheet route is removed before pushing next screen.
    Future<void>.delayed(Duration.zero, () {
      if (!rootNavigator.mounted) return;
      rootNavigator.push(MaterialPageRoute(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
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
              iconSize: 19,
              onTap: () =>
                  _navigateFromSheet(context, const AppAppearanceScreen()),
            ),

            const SizedBox(height: 10),

            SettingItem(
              title: AppLocalizations.of(context).aboutAppTitle,
              iconPath: "assets/icons/info.svg",
              iconType: AppIconType.svg,
              iconSize: 20,
              onTap: () => _navigateFromSheet(context, const AboutAppScreen()),
            ),

            const SizedBox(height: 10),

            SettingItem(
              title: AppLocalizations.of(context).logoutTitle,
              iconPath: "assets/icons/logout.svg",
              iconType: AppIconType.svg,
              iconSize: 20,
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
      final rootNav = Navigator.of(context, rootNavigator: true);

      await authVM.logout();
      if (!rootNav.mounted) return;
      if (rootNav.canPop()) {
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
            padding: EdgeInsets.symmetric(
              horizontal: context.adaptiveHorizontalPadding(
                compact: 16,
                regular: 30,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),

                /// divider
                Container(
                  width: double.infinity,
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
                          height: 40,
                          text: l10n.cancelButton,
                          fontSize: 15,
                          onPressed: vm.logoutInProgress
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.primary,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: AppButton(
                          height: 40,
                          text: l10n.confirmButton,
                          fontSize: 15,
                          loading: vm.logoutInProgress,
                          onPressed: vm.logoutInProgress ? null : logout,
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
                  fontSize: Theme.of(context).appTypography.title.fontSize!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
