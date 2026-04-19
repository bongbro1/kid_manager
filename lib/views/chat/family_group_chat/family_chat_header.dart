import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_ui_utils.dart';

class FamilyChatHeader extends StatelessWidget {
  const FamilyChatHeader({
    super.key,
    required this.members,
    required this.myUid,
    required this.isLoading,
  });

  final List<FamilyChatMember> members;
  final String myUid;
  final bool isLoading;

  String _safeDisplayName(FamilyChatMember member, AppLocalizations l10n) {
    if (member.uid == myUid) {
      return l10n.familyChatYou;
    }
    return sanitizeMemberLabel(member.displayName, l10n);
  }

  String _memberSummary(AppLocalizations l10n) {
    if (isLoading) {
      return l10n.familyChatLoadingMembers;
    }
    if (members.isEmpty) {
      return l10n.familyChatNoMembersFound;
    }

    final names = members
        .map((member) => _safeDisplayName(member, l10n))
        .toList(growable: false);

    const maxVisible = 3;
    if (names.length <= maxVisible) {
      return names.join(', ');
    }

    final visible = names.take(maxVisible).join(', ');
    return l10n.familyChatMemberCountOverflow(
      visible,
      names.length - maxVisible,
    );
  }

  String _memberCountLabel(AppLocalizations l10n) {
    if (members.isEmpty) {
      return '';
    }
    if (members.length == 1) {
      return l10n.familyChatOneMember;
    }
    return l10n.familyChatManyMembers(members.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final countLabel = _memberCountLabel(l10n);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: familyChatHighlightColor(scheme),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.groups_rounded, color: scheme.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.familyChatTitleLarge,
                style: TextStyle(
                  fontSize: Theme.of(
                    context,
                  ).appTypography.inlineHeaderTitle.fontSize!,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _memberSummary(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Theme.of(
                    context,
                  ).appTypography.supporting.fontSize!,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (countLabel.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: familyChatHighlightColor(scheme),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: familyChatBorderColor(scheme)),
            ),
            child: Text(
              countLabel,
              style: TextStyle(
                fontSize: Theme.of(context).appTypography.meta.fontSize!,
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class FamilyChatMembersBar extends StatelessWidget {
  const FamilyChatMembersBar({
    super.key,
    required this.members,
    required this.myUid,
    required this.isLoading,
  });

  final List<FamilyChatMember> members;
  final String myUid;
  final bool isLoading;

  String _safeDisplayName(String rawName, AppLocalizations l10n) {
    return sanitizeMemberLabel(rawName, l10n);
  }

  String _initialOf(String rawName, AppLocalizations l10n) {
    final text = sanitizeMemberLabel(rawName, l10n);
    if (text.isEmpty) {
      return '?';
    }
    return text.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (isLoading && members.isEmpty) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (members.isEmpty) {
      return const SizedBox(height: 8);
    }

    return Container(
      height: 64,
      color: familyChatSurfaceColor(scheme),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final member = members[index];
          final isMe = member.uid == myUid;
          final roleColor = switch (member.role) {
            UserRole.parent => const Color(0xFFF59E0B),
            UserRole.guardian => const Color(0xFF38BDF8),
            UserRole.child => const Color(0xFF22C55E),
          };

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isMe
                  ? familyChatHighlightColor(scheme)
                  : familyChatBackgroundColor(scheme),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: familyChatBorderColor(scheme)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: roleColor.withAlpha(30),
                  child: Text(
                    _initialOf(member.displayName, l10n),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: Theme.of(context).appTypography.meta.fontSize!,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isMe
                      ? l10n.familyChatYou
                      : _safeDisplayName(member.displayName, l10n),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: Theme.of(
                      context,
                    ).appTypography.supporting.fontSize!,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
