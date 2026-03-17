import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/app_navigator.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/views/chat/family_group_chat_screen.dart';

String birthdayNameFromNotification(
  AppLocalizations l10n,
  AppNotification item,
) {
  final data = item.data;
  final candidates = [
    data['birthdayName'],
    data['childName'],
    data['displayName'],
    data['name'],
  ];

  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  return l10n.birthdayMemberFallback;
}

int? birthdayAgeTurningFromNotification(AppNotification item) {
  final raw = item.data['ageTurning'];
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
}

bool isBirthdaySelfNotification(AppNotification item) {
  final raw = item.data['isSelf']?.toString().trim().toLowerCase();
  return raw == 'true' || raw == '1';
}

String buildBirthdayWishText(AppLocalizations l10n, AppNotification item) {
  final name = birthdayNameFromNotification(l10n, item);
  final ageTurning = birthdayAgeTurningFromNotification(item);

  if (isBirthdaySelfNotification(item)) {
    return ageTurning != null && ageTurning > 0
        ? l10n.birthdayWishSelfWithAge(ageTurning)
        : l10n.birthdayWishSelfDefault;
  }

  return ageTurning != null && ageTurning > 0
      ? l10n.birthdayWishOtherWithAge(name, ageTurning)
      : l10n.birthdayWishOtherDefault(name);
}

Future<void> showBirthdayNotificationSheet(
  BuildContext context, {
  required AppNotification item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BirthdayCelebrationSheet(item: item),
  );
}

class BirthdayNotificationCard extends StatelessWidget {
  const BirthdayNotificationCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final AppNotification item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = birthdayNameFromNotification(l10n, item);
    final ageTurning = birthdayAgeTurningFromNotification(item);
    final isSelf = isBirthdaySelfNotification(item);
    final ctaLabel = isSelf
        ? l10n.birthdayViewWishButton
        : l10n.birthdaySendWishButton;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF2F7), Color(0xFFFFFAF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFAD1E6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14F472B6),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: -10,
                right: 34,
                child: _SoftBubble(size: 56, color: Color(0x33FFFFFF)),
              ),
              const Positioned(
                bottom: 12,
                right: 12,
                child: _SoftBubble(size: 72, color: Color(0x1AF59E0B)),
              ),
              const Positioned(
                top: 18,
                left: 84,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0x66EC4899),
                  size: 16,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BirthdayPulseBadge(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  isSelf
                                      ? l10n.birthdayCongratsYouTitle
                                      : l10n.birthdayCongratsTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (!item.isRead) const _UnreadDot(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _BirthdayInfoChip(
                                icon: isSelf
                                    ? Icons.favorite_rounded
                                    : Icons.cake_outlined,
                                label: isSelf
                                    ? l10n.birthdayTodayIsYourDay
                                    : name,
                              ),
                              if (ageTurning != null && ageTurning > 0)
                                _BirthdayInfoChip(
                                  icon: Icons.stars_rounded,
                                  label: l10n.birthdayTurnsAge(ageTurning),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Flexible(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: InkWell(
                                    onTap: onTap,
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.celebration_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              ctaLabel,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class BirthdayCelebrationSheet extends StatelessWidget {
  const BirthdayCelebrationSheet({super.key, required this.item});

  final AppNotification item;

  Future<void> _openFamilyChat(
    BuildContext context, {
    required String familyId,
    required String wishText,
  }) async {
    Navigator.of(context).pop();

    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) return;

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => FamilyGroupChatScreen(
          initialFamilyId: familyId,
          initialComposerText: wishText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = birthdayNameFromNotification(l10n, item);
    final ageTurning = birthdayAgeTurningFromNotification(item);
    final isSelf = isBirthdaySelfNotification(item);
    final wishText = buildBirthdayWishText(l10n, item);
    final familyId = (item.familyId?.trim().isNotEmpty ?? false)
        ? item.familyId!.trim()
        : (item.data['familyId']?.toString().trim() ?? '');

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 32,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _CelebrationHero(),
                  const SizedBox(height: 22),
                  Text(
                    isSelf
                        ? l10n.birthdayCongratsYouTitle
                        : l10n.birthdayCongratsTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSelf
                        ? (ageTurning != null && ageTurning > 0
                              ? l10n.birthdayYouEnteringAge(ageTurning)
                              : l10n.birthdayYouSpecialDay)
                        : (ageTurning != null && ageTurning > 0
                              ? l10n.birthdayTodayIsBirthdayWithAge(
                                  name,
                                  ageTurning,
                                )
                              : l10n.birthdayTodayIsBirthday(name)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: Color(0xFFEC4899),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.birthdaySuggestionTitle,
                              style: const TextStyle(
                                color: Color(0xFF374151),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          wishText,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!isSelf)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          if (familyId.isNotEmpty) {
                            await _openFamilyChat(
                              context,
                              familyId: familyId,
                              wishText: wishText,
                            );
                            return;
                          }

                          await Clipboard.setData(
                            ClipboardData(text: wishText),
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.birthdayCopiedFallback(name)),
                            ),
                          );
                        },
                        child: Text(
                          l10n.birthdaySendWishButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (!isSelf) const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        isSelf
                            ? l10n.birthdayAwesomeButton
                            : l10n.birthdayCloseButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BirthdayPulseBadge extends StatelessWidget {
  const _BirthdayPulseBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE4EF), Color(0xFFFFF3CD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD0E6)),
        ),
        child: const Icon(
          Icons.cake_rounded,
          color: Color(0xFFDB2777),
          size: 28,
        ),
      ),
    );
  }
}

class _CelebrationHero extends StatelessWidget {
  const _CelebrationHero();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: SizedBox(
        width: 148,
        height: 148,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 148,
              height: 148,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEAF2FF),
              ),
            ),
            Container(
              width: 116,
              height: 116,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDCEAFF),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                color: Color(0xFFEC4899),
                size: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthdayInfoChip extends StatelessWidget {
  const _BirthdayInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF4D1E4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFEC4899)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBubble extends StatelessWidget {
  const _SoftBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(left: 10, top: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        shape: BoxShape.circle,
      ),
    );
  }
}
