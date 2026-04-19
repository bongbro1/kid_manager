import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/user/app_user_extensions.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/widgets/common/avatar.dart';
import 'package:kid_manager/widgets/location/device_battery_widgets.dart';

class ParentChildListItem extends StatelessWidget {
  final AppUser member;
  final LocationData? location;

  final VoidCallback onOpenHistory;
  final VoidCallback onLocate;
  final VoidCallback onChat;
  final VoidCallback onPhone;

  const ParentChildListItem({
    super.key,
    required this.member,
    this.location,
    required this.onOpenHistory,
    required this.onLocate,
    required this.onChat,
    required this.onPhone,
  });

  bool get isOnline {
    if (location == null) return false;

    final last = DateTime.fromMillisecondsSinceEpoch(location!.timestamp);
    return DateTime.now().difference(last).inMinutes <= 5;
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = member.displayLabel;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final batteryState = DeviceBatteryUiState.fromSnapshot(
      batteryLevel: member.isChild ? location?.batteryLevel : null,
      isCharging: member.isChild ? location?.isCharging : null,
      timestampMs: member.isChild ? location?.timestamp : null,
    );

    final onlineColor = Colors.green;
    final offlineColor = colorScheme.onSurface.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onOpenHistory,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        AppAvatar(user: member, size: 40),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isOnline ? onlineColor : offlineColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
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
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${_roleLabel(l10n)} - '
                                '${isOnline ? l10n.memberManagementOnline : l10n.memberManagementOffline}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: isOnline ? onlineColor : offlineColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // if (member.isChild)
                              //   DeviceBatteryCompactBadge(state: batteryState),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionPill(onChat: onChat, onLocate: onLocate, onPhone: onPhone),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final VoidCallback onChat;
  final VoidCallback onLocate;
  final VoidCallback onPhone;

  const _ActionPill({
    required this.onChat,
    required this.onLocate,
    required this.onPhone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 43,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onChat,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SvgPicture.asset(
                'assets/icons/message.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: colorScheme.outline.withOpacity(0.7),
          ),
          InkWell(
            onTap: onPhone,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.call_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: colorScheme.outline.withOpacity(0.7),
          ),
          InkWell(
            onTap: onLocate,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SvgPicture.asset(
                'assets/icons/gps.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
