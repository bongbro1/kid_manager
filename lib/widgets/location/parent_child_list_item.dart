import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/user/app_user_extensions.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/widgets/common/avatar.dart';
import 'package:kid_manager/widgets/location/child_connection_presenter.dart';
import 'package:kid_manager/widgets/location/device_battery_widgets.dart';

class ParentChildListItem extends StatelessWidget {
  const ParentChildListItem({
    super.key,
    required this.member,
    this.location,
    required this.onOpenHistory,
    required this.onLocate,
    required this.onChat,
    required this.onPhone,
  });

  final AppUser member;
  final LocationData? location;
  final VoidCallback onOpenHistory;
  final VoidCallback onLocate;
  final VoidCallback onChat;
  final VoidCallback onPhone;

  String _roleLabel(AppLocalizations l10n) {
    switch (member.role) {
      case UserRole.parent:
        return l10n.userRoleParent;
      case UserRole.child:
        return l10n.userRoleChild;
      case UserRole.guardian:
        return l10n.userRoleGuardian;
    }
  }

  String _callLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'en'
        ? 'Call'
        : 'Gọi điện';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final childConnection = member.isChild
        ? ChildConnectionPresentation.fromLocation(location)
        : null;
    final batteryState = DeviceBatteryUiState.fromSnapshot(
      batteryLevel: member.isChild ? location?.batteryLevel : null,
      isCharging: member.isChild ? location?.isCharging : null,
      timestampMs: member.isChild ? location?.timestamp : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outline.withOpacity(0.18),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (childConnection != null)
              _StatusStrip(
                label: childConnection.summaryLabel(l10n),
                accentColor: childConnection.textColor(scheme),
                dotColor: childConnection.dotColor(scheme),
              ),
            InkWell(
              onTap: onOpenHistory,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(childConnection != null ? 0 : 20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AppAvatar(user: member, size: 56),
                        ),
                        if (childConnection != null)
                          Positioned(
                            right: -1,
                            bottom: -1,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: childConnection.dotColor(scheme),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withOpacity(
                                0.7,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _roleLabel(l10n),
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (member.isChild)
                      DeviceBatteryCompactBadge(state: batteryState),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.outline.withOpacity(0.12),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _ActionButton(
                    icon: SvgPicture.asset(
                      'assets/icons/message.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        scheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: l10n.memberManagementMessageButton,
                    onTap: onChat,
                    isFirst: true,
                  ),
                  _ActionDivider(color: scheme.outline.withOpacity(0.16)),
                  _ActionButton(
                    icon: Icon(
                      Icons.call_rounded,
                      size: 20,
                      color: scheme.onSurface,
                    ),
                    label: _callLabel(context),
                    onTap: onPhone,
                  ),
                  _ActionDivider(color: scheme.outline.withOpacity(0.16)),
                  _ActionButton(
                    icon: SvgPicture.asset(
                      'assets/icons/gps.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        scheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: l10n.memberManagementLocationButton,
                    onTap: onLocate,
                  ),
                  _ActionDivider(color: scheme.outline.withOpacity(0.16)),
                  _ActionButton(
                    icon: Icon(
                      Icons.timeline_rounded,
                      size: 20,
                      color: scheme.onSurface,
                    ),
                    label: l10n.childLocationHistoryButton,
                    onTap: onOpenHistory,
                    isLast: true,
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

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.label,
    required this.accentColor,
    required this.dotColor,
  });

  final String label;
  final Color accentColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          bottomLeft: isFirst ? const Radius.circular(20) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 0.8, height: 34, color: color);
  }
}
