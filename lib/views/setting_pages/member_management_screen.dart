import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/add_account_screen.dart';
import 'package:kid_manager/widgets/app/app_scroll_effects.dart';
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
        'Chưa có bé nào theo dõi',
        'No tracked children assigned',
      );
    }
    return _text(
      context,
      'Đang theo dõi $count bé',
      'Tracking $count children',
    );
  }

  void _openAddAccount(BuildContext context) {
    Navigator.push(
      context,
      AppPageTransitions.route(builder: (_) => const AddAccountScreen()),
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
                  bottom:
                      MediaQuery.of(bottomSheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(
                        bottomSheetContext,
                        'Chọn bé cho người giám hộ',
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
                            'Chưa có bé để gắn.',
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
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
                                  'Tài khoản bé',
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
                            child: Text(
                              _text(bottomSheetContext, 'Hủy', 'Cancel'),
                            ),
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
                                      if (!mounted) return;
                                      Navigator.of(sheetContext).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _text(
                                              context,
                                              'Đã cập nhập danh sách bé theo dõi',
                                              'Tracked children updated',
                                            ),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
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
                                : Text(
                                    _text(bottomSheetContext, 'Lưu', 'Save'),
                                  ),
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
    final canAddAccount =
        actor != null &&
        context.read<AccessControlService>().canAddManagedAccounts(
          actor: actor,
        );
    final canAssignGuardianChildren = actor?.role == UserRole.parent;

    return Scaffold(
      // ── Soft tinted background ──────────────────────────────────────────
      backgroundColor: Color.alphaBlend(
        scheme.primary.withOpacity(.035),
        scheme.surface,
      ),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
          leadingWidth: 72,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RoundIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        title: Text(
          l10n.memberManagementTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
          ),
        ),
        // ── "+" shortcut in AppBar when canAddAccount ──────────────────
        actions: [
          if (canAddAccount)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _RoundIconButton(
                icon: Icons.add_rounded,
                filled: true,
                onTap: () => _openAddAccount(context),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Consumer<UserVm>(
          builder: (context, vm, _) {
            final members = vm.familyMembers;
            final children = members
                .where((user) => user.role == UserRole.child)
                .toList(growable: false);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero add-member card ─────────────────────────────
                  if (canAddAccount) ...[
                    _AddMemberHeroCard(
                      title: l10n.memberManagementAddMemberTitle,
                      subtitle: l10n.memberManagementAddMemberSubtitle,
                      ctaText: l10n.memberManagementAddNowButton,
                      onTap: () => _openAddAccount(context),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // ── Section label ────────────────────────────────────
                  Text(
                    '${l10n.memberManagementFamilyMembersLabel} · ${members.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Member list ──────────────────────────────────────
                  Expanded(
                    child: members.isEmpty
                        ? Center(
                            child: AppScrollReveal(
                              index: 0,
                              child: Text(
                                l10n.memberManagementEmpty,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: AppScrollEffects.physics,
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                ...members.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final user = entry.value;

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == members.length - 1
                                          ? 0
                                          : 12,
                                    ),
                                    child: AppScrollReveal(
                                      index: index,
                                      child: MemberItem(
                                        user: user,
                                        name:
                                            user.displayName
                                                    ?.trim()
                                                    .isNotEmpty ==
                                                true
                                            ? user.displayName!.trim()
                                            : (user.email ?? ''),
                                        role: user.role,
                                        avatar: user.avatarUrl,
                                        online: user.isActive,
                                        trailingInfo:
                                            user.role == UserRole.guardian
                                            ? _guardianTrackingSummary(
                                                context,
                                                user,
                                              )
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
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar icon button (plain or filled-primary circle)
// ─────────────────────────────────────────────────────────────────────────────
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: filled ? scheme.primary : scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled
                  ? scheme.primary.withOpacity(.18)
                  : scheme.outlineVariant.withOpacity(.8),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: filled ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero "add member" card — solid primary background, decorative circles
// ─────────────────────────────────────────────────────────────────────────────
class _AddMemberHeroCard extends StatelessWidget {
  const _AddMemberHeroCard({
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String ctaText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.07),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: scheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onPrimary.withOpacity(.82),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(.28),
                        ),
                      ),
                      child: Text(
                        ctaText,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member card
// ─────────────────────────────────────────────────────────────────────────────
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
  final String? avatar;
  final bool online;
  final String? trailingInfo;
  final VoidCallback? onManageAssignments;

  // ── Helpers ──────────────────────────────────────────────────────────────

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

  /// Two-letter initials derived from display name.
  String _initials() {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final v = parts.first;
      return (v.length >= 2 ? v.substring(0, 2) : v).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Avatar background/foreground palette keyed by role.
  _AvatarPalette _palette(ColorScheme scheme) {
    switch (role) {
      case UserRole.parent:
        return _AvatarPalette(
          bg: Color.alphaBlend(
            scheme.primary.withOpacity(.14),
            scheme.primaryContainer,
          ),
          fg: scheme.onPrimaryContainer,
          border: scheme.primary.withOpacity(.24),
        );
      case UserRole.guardian:
        return _AvatarPalette(
          bg: Color.alphaBlend(
            scheme.secondary.withOpacity(.16),
            scheme.secondaryContainer,
          ),
          fg: scheme.onSecondaryContainer,
          border: scheme.secondary.withOpacity(.24),
        );
      case UserRole.child:
        return _AvatarPalette(
          bg: Color.alphaBlend(
            scheme.tertiary.withOpacity(.18),
            scheme.tertiaryContainer,
          ),
          fg: scheme.onTertiaryContainer,
          border: scheme.tertiary.withOpacity(.24),
        );
    }
  }

  /// Role chip background/foreground.
  _ChipStyle _roleChip(ColorScheme scheme) {
    switch (role) {
      case UserRole.parent:
        return _ChipStyle(
          bg: Color.alphaBlend(
            scheme.primary.withOpacity(.14),
            scheme.primaryContainer,
          ),
          fg: scheme.onPrimaryContainer,
        );
      case UserRole.guardian:
        return _ChipStyle(
          bg: Color.alphaBlend(
            scheme.secondary.withOpacity(.16),
            scheme.secondaryContainer,
          ),
          fg: scheme.onSecondaryContainer,
        );
      case UserRole.child:
        return _ChipStyle(
          bg: Color.alphaBlend(
            scheme.tertiary.withOpacity(.18),
            scheme.tertiaryContainer,
          ),
          fg: scheme.onTertiaryContainer,
        );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pal = _palette(scheme);
    final roleStyle = _roleChip(scheme);
    final avatarUrl = avatar?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + online dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: pal.bg,
                        border: Border.all(color: pal.border, width: 1.5),
                      ),
                      child: ClipOval(
                        child: hasAvatar
                            ? SmartNetworkImage(
                                imageUrl: avatarUrl,
                                fallbackAsset: 'assets/images/u1.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  _initials(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: pal.fg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: online
                              ? scheme.primary
                              : scheme.outlineVariant,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name + badges + tracking
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Role badge
                          _Chip(
                            label: _localizedRole(l10n),
                            bg: roleStyle.bg,
                            fg: roleStyle.fg,
                          ),
                          // Online / offline badge with dot
                          _Chip(
                            label: online
                                ? l10n.memberManagementOnline
                                : l10n.memberManagementOffline,
                            bg: online
                                ? Color.alphaBlend(
                                    scheme.primary.withOpacity(.12),
                                    scheme.surface,
                                  )
                                : scheme.surfaceVariant,
                            fg: online
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            dotColor: online
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ],
                      ),
                      // Tracking info (guardian only)
                      if (trailingInfo != null &&
                          trailingInfo!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.route_rounded,
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                trailingInfo!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Tune button (guardian assignment)
                if (onManageAssignments != null) ...[
                  const SizedBox(width: 8),
                  _TuneButton(onTap: onManageAssignments!),
                ],
              ],
            ),
          ),
          // ── Divider ─────────────────────────────────────────────────
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withOpacity(.7),
          ),
          // ── Action row ───────────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ActionCell(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: l10n.memberManagementMessageButton,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 0.5,
                  color: scheme.outlineVariant.withOpacity(.7),
                ),
                Expanded(
                  child: _ActionCell(
                    icon: Icons.location_on_outlined,
                    label: l10n.memberManagementLocationButton,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarPalette {
  const _AvatarPalette({
    required this.bg,
    required this.fg,
    required this.border,
  });
  final Color bg;
  final Color fg;
  final Color border;
}

class _ChipStyle {
  const _ChipStyle({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}

/// Pill badge with optional leading dot.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    this.dotColor,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Square button for guardian assignment.
class _TuneButton extends StatelessWidget {
  const _TuneButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withOpacity(.08),
              scheme.surface,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant.withOpacity(.6)),
          ),
          child: Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
        ),
      ),
    );
  }
}

/// Bottom action cell (Message / Location).
class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
