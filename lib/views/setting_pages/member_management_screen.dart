import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/add_account_screen.dart';
import 'package:kid_manager/widgets/common/smart_network_image.dart';
import 'package:provider/provider.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  String _text(BuildContext context, String vi, String en) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code == 'vi' ? vi : en;
  }

  String _guardianTrackingSummary(BuildContext context, AppUser guardian) {
    final count = guardian.managedChildIds.length;
    if (count <= 0) {
      return _text(
        context,
        'Chua chon be nao de theo doi',
        'No tracked children assigned',
      );
    }
    return _text(
      context,
      'Dang theo doi $count be',
      'Tracking $count children',
    );
  }

  Future<void> _openGuardianChildPicker(
    BuildContext context, {
    required AppUser guardian,
    required List<AppUser> availableChildren,
  }) async {
    final vm = context.read<UserVm>();
    final selectedIds = guardian.managedChildIds.toSet();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        return StatefulBuilder(
          builder: (bottomSheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(
                        bottomSheetContext,
                        'Chon be cho nguoi giam ho',
                        'Assign children to guardian',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      guardian.displayName?.trim().isNotEmpty == true
                          ? guardian.displayName!.trim()
                          : (guardian.email ?? guardian.uid),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (availableChildren.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _text(
                            bottomSheetContext,
                            'Chua co be nao de gan.',
                            'No children available to assign.',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: availableChildren.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (itemContext, index) {
                            final child = availableChildren[index];
                            final isSelected = selectedIds.contains(child.uid);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: saving
                                  ? null
                                  : (value) {
                                      setSheetState(() {
                                        if (value == true) {
                                          selectedIds.add(child.uid);
                                        } else {
                                          selectedIds.remove(child.uid);
                                        }
                                      });
                                    },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: scheme.surface,
                              activeColor: scheme.primary,
                              title: Text(
                                child.displayName?.trim().isNotEmpty == true
                                    ? child.displayName!.trim()
                                    : (child.email ?? child.uid),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _text(
                                  bottomSheetContext,
                                  'Tai khoan be',
                                  'Child account',
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: Text(_text(bottomSheetContext, 'Huy', 'Cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    setSheetState(() => saving = true);
                                    try {
                                      await vm.assignGuardianChildren(
                                        guardianUid: guardian.uid,
                                        childIds: selectedIds.toList(
                                          growable: false,
                                        ),
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _text(
                                              context,
                                              'Da cap nhat danh sach be theo doi',
                                              'Tracked children updated',
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    } finally {
                                      if (sheetContext.mounted) {
                                        setSheetState(() => saving = false);
                                      }
                                    }
                                  },
                            child: saving
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : Text(_text(bottomSheetContext, 'Luu', 'Save')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    final vm = context.read<UserVm>();
    final uid = context.read<StorageService>().getString(StorageKeys.uid);
    if (uid != null && uid.isNotEmpty) {
      vm.watchFamilyMembersByParent(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final actor = context.select<UserVm, AppUser?>((vm) => vm.actorSnapshot);
    final canAddAccount = actor != null &&
        context.read<AccessControlService>().canAddManagedAccounts(actor: actor);
    final canAssignGuardianChildren = actor?.role == UserRole.parent;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scheme.surface,
        centerTitle: true,
        title: Text(
          l10n.memberManagementTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canAddAccount) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_add_alt_1,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.memberManagementAddMemberTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.memberManagementAddMemberSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddAccountScreen(),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.memberManagementAddNowButton,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                l10n.memberManagementFamilyMembersLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<UserVm>(
                  builder: (context, vm, _) {
                    final members = vm.familyMembers;
                    final children = members
                        .where((user) => user.role == UserRole.child)
                        .toList(growable: false);

                    if (members.isEmpty) {
                      return Center(child: Text(l10n.memberManagementEmpty));
                    }

                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final user = members[index];

                        return MemberItem(
                          user: user,
                          name: user.displayName?.trim().isNotEmpty == true
                              ? user.displayName!.trim()
                              : (user.email ?? ''),
                          role: user.role,
                          avatar: user.avatarUrl ?? 'assets/images/u1.png',
                          online: user.isActive,
                          trailingInfo: user.role == UserRole.guardian
                              ? _guardianTrackingSummary(context, user)
                              : null,
                          onManageAssignments:
                              canAssignGuardianChildren &&
                                  user.role == UserRole.guardian
                              ? () => _openGuardianChildPicker(
                                  context,
                                  guardian: user,
                                  availableChildren: children,
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberItem extends StatelessWidget {
  const MemberItem({
    super.key,
    required this.user,
    required this.name,
    required this.role,
    required this.avatar,
    this.online = false,
    this.trailingInfo,
    this.onManageAssignments,
  });

  final AppUser user;
  final String name;
  final UserRole role;
  final String avatar;
  final bool online;
  final String? trailingInfo;
  final VoidCallback? onManageAssignments;

  Widget _buildAvatarPhoto(String? avatarUrl) {
    return SmartNetworkImage(
      imageUrl: avatarUrl,
      fallbackAsset: 'assets/images/u1.png',
      width: 60,
      height: 60,
      fit: BoxFit.cover,
    );
  }

  String _localizedRole(AppLocalizations l10n) {
    switch (role) {
      case UserRole.child:
        return l10n.userRoleChild;
      case UserRole.guardian:
        return l10n.userRoleGuardian;
      case UserRole.parent:
        return l10n.userRoleParent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: scheme.primary.withOpacity(.25),
                      ),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: _buildAvatarPhoto(avatar),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: online ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_localizedRole(l10n)} • '
                      '${online ? l10n.memberManagementOnline : l10n.memberManagementOffline}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (trailingInfo != null && trailingInfo!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        trailingInfo!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onManageAssignments != null) ...[
                IconButton(
                  tooltip: 'Chon be theo doi',
                  onPressed: onManageAssignments,
                  icon: Icon(
                    Icons.tune_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: online
                      ? scheme.primary.withOpacity(.12)
                      : scheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  online
                      ? l10n.memberManagementOnline
                      : l10n.memberManagementOffline,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: online ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.memberManagementMessageButton,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.memberManagementLocationButton,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
