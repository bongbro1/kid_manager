import 'package:flutter/material.dart';
import 'package:kid_manager/core/network/network_action_guard.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/widgets/common/avatar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/widgets/location/batterIcon.dart';
import 'package:kid_manager/widgets/location/child_connection_presenter.dart';
import 'package:kid_manager/widgets/location/device_battery_widgets.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';

class ChildInfoSheet extends StatefulWidget {
  final AppUser member;
  final LocationData? latest;
  final List<Schedule> daySchedules;
  final List<Schedule> upcomingSchedules;
  final VoidCallback onOpenChat;
  final Future<void> Function(String message) onSendQuickMessage;

  const ChildInfoSheet({
    super.key,
    required this.member,
    required this.latest,
    required this.daySchedules,
    required this.upcomingSchedules,
    required this.onOpenChat,
    required this.onSendQuickMessage,
  });

  @override
  State<ChildInfoSheet> createState() => _ChildInfoSheetState();
}

class _ChildInfoSheetState extends State<ChildInfoSheet> {
  final TextEditingController _msgCtl = TextEditingController();
  final ScrollController _scheduleScrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtl.dispose();
    _scheduleScrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final ok = await runGuardedNetworkVoidAction(
        context,
        action: () => widget.onSendQuickMessage(text),
      );
      if (!ok) {
        return;
      }
      _msgCtl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).locationMessageSent),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).familyChatSendFailed('$e'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _fmt(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.hour)}:${two(dt.minute)}';
  }

  String _fmtRange(DateTime s, DateTime e) => '${_fmt(s)} – ${_fmt(e)}';

  bool _isOngoing(Schedule s) {
    final now = DateTime.now();
    return !s.startAt.isAfter(now) && s.endAt.isAfter(now);
  }

  Schedule? _currentOrNext(List<Schedule> schedules) {
    final now = DateTime.now();
    for (final s in schedules) {
      if (!s.startAt.isAfter(now) && s.endAt.isAfter(now)) return s;
    }
    for (final s in schedules) {
      if (s.startAt.isAfter(now)) return s;
    }
    return null;
  }

  bool _isVi(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'vi';

  String _dayLabel(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = DateTime(
      dt.year,
      dt.month,
      dt.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return _isVi(context) ? 'Hôm nay' : 'Today';
    if (diff == 1) return _isVi(context) ? 'Ngày mai' : 'Tomorrow';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}';
  }

  String _roleLabel(AppLocalizations l10n, AppUser member) {
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
    final scheme = Theme.of(context).colorScheme;
    final member = widget.member;
    final latest = widget.latest;
    final isVi = _isVi(context);
    final connectionPresentation = ChildConnectionPresentation.fromLocation(
      latest,
    );
    final secondaryStatus = connectionPresentation.secondaryLabel(l10n);

    final panelColor = locationPanelColor(scheme);
    final panelMutedColor = locationPanelMutedColor(scheme);
    final panelBorderColor = locationPanelBorderColor(scheme);

    final name = (member.displayName?.isNotEmpty ?? false)
        ? member.displayName!
        : (member.email ?? '');

    final daySchedules = List<Schedule>.from(widget.daySchedules)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final scheduleNeedsScroll = daySchedules.length > 4;
    const scheduleListMaxHeight = 196.0;

    final upcomingSchedules = List<Schedule>.from(widget.upcomingSchedules)
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final activeSchedule = _currentOrNext(upcomingSchedules);

    final batteryState = DeviceBatteryUiState.fromSnapshot(
      batteryLevel: member.isChild ? latest?.batteryLevel : null,
      isCharging: member.isChild ? latest?.isCharging : null,
      timestampMs: member.isChild ? latest?.timestamp : null,
    );

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: panelColor,
              borderRadius: BorderRadius.circular(28),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // -- drag handle --
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: panelBorderColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // -- profile card --
                      _SectionCard(
                        borderColor: panelBorderColor,
                        mutedColor: panelMutedColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (member.isChild) ...[
                              ChildConnectionStatusHeader(
                                presentation: connectionPresentation,
                                scheme: scheme,
                                backgroundColor: panelColor,
                                borderColor: panelBorderColor,
                              ),
                              const SizedBox(height: 10),
                            ],
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    AppAvatar(user: member, size: 52),
                                    Positioned(
                                      bottom: 1,
                                      right: 1,
                                      child: Container(
                                        width: 11,
                                        height: 11,
                                        decoration: BoxDecoration(
                                          color: connectionPresentation
                                              .dotColor(scheme),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: panelMutedColor,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _roleLabel(l10n, member),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (!member.isChild &&
                                          secondaryStatus != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            secondaryStatus,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _IconBtn(
                                  onTap: widget.onOpenChat,
                                  borderColor: panelBorderColor,
                                  backgroundColor: panelColor,
                                  child: SvgPicture.asset(
                                    'assets/icons/message.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter: ColorFilter.mode(
                                      scheme.primary,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // -- quick message --
                      // ===== quick message =====
                      Container(
                        width: 350,
                        height: 49,
                        decoration: BoxDecoration(
                          color: panelMutedColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: panelBorderColor, width: 1),
                        ),
                        child: Stack(
                          children: [
                            TextField(
                              controller: _msgCtl,
                              decoration: InputDecoration(
                                hintText: l10n.locationQuickMessageHint,
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.fromLTRB(
                                  12,
                                  14,
                                  44,
                                  14,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: scheme.onSurface,
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                            ),
                            Positioned(
                              right: 10,
                              top: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _sending ? null : _send,
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: _sending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : SvgPicture.asset(
                                          "assets/icons/send-message.svg",
                                          fit: BoxFit.contain,
                                          colorFilter: ColorFilter.mode(
                                            scheme.primary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // -- schedule + status row --
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // left: today's schedules
                            Expanded(
                              child: _SectionCard(
                                borderColor: panelBorderColor,
                                mutedColor: panelMutedColor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(
                                      icon: Icons.calendar_month_rounded,
                                      label: l10n.scheduleScreenTitle,
                                      scheme: scheme,
                                    ),
                                    const SizedBox(height: 10),
                                    if (daySchedules.isEmpty)
                                      Text(
                                        isVi ? 'Hôm nay rảnh' : 'Free today',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      )
                                    else
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: scheduleNeedsScroll
                                              ? scheduleListMaxHeight
                                              : double.infinity,
                                        ),
                                        child: Scrollbar(
                                          controller: _scheduleScrollController,
                                          thumbVisibility: scheduleNeedsScroll,
                                          child: SingleChildScrollView(
                                            controller:
                                                _scheduleScrollController,
                                            primary: false,
                                            child: Column(
                                              children: daySchedules
                                                  .asMap()
                                                  .entries
                                                  .map((e) {
                                                    final isLast =
                                                        e.key ==
                                                        daySchedules.length - 1;
                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: isLast ? 0 : 10,
                                                      ),
                                                      child: _ScheduleItem(
                                                        title: e.value.title,
                                                        time: _fmtRange(
                                                          e.value.startAt,
                                                          e.value.endAt,
                                                        ),
                                                        scheme: scheme,
                                                      ),
                                                    );
                                                  })
                                                  .toList(growable: false),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // right: active/next schedule + battery
                            Expanded(
                              child: Column(
                                children: [
                                  // active / next schedule card
                                  Expanded(
                                    child: _SectionCard(
                                      borderColor: panelBorderColor,
                                      mutedColor: panelMutedColor,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activeSchedule != null &&
                                                    _isOngoing(activeSchedule)
                                                ? (isVi
                                                      ? 'Đang diễn ra'
                                                      : 'Ongoing')
                                                : (isVi ? 'Sắp tới' : 'Next'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurfaceVariant,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            activeSchedule == null
                                                ? (isVi
                                                      ? 'Chưa có lịch'
                                                      : 'No schedule')
                                                : activeSchedule.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.2,
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                          if (activeSchedule != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_dayLabel(context, activeSchedule.startAt)} · ${_fmtRange(activeSchedule.startAt, activeSchedule.endAt)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: scheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _isOngoing(activeSchedule)
                                                  ? (isVi
                                                        ? 'Kết thúc lúc ${_fmt(activeSchedule.endAt)}'
                                                        : 'Ends at ${_fmt(activeSchedule.endAt)}')
                                                  : (isVi
                                                        ? 'Bắt đầu lúc ${_fmt(activeSchedule.startAt)}'
                                                        : 'Starts at ${_fmt(activeSchedule.startAt)}'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: scheme.primary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                  // battery row — only for children
                                  if (member.isChild) ...[
                                    const SizedBox(height: 10),
                                    _BatteryBar(
                                      state: batteryState,
                                      borderColor: panelBorderColor,
                                      mutedColor: panelMutedColor,
                                      scheme: scheme,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // -- coordinates footer --
                      if (latest != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: connectionPresentation.dotColor(scheme),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.locationCoordinatesSummary(
                                latest.latitude.toStringAsFixed(4),
                                latest.longitude.toStringAsFixed(4),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -- shared section card ------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color mutedColor;

  const _SectionCard({
    required this.child,
    required this.borderColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mutedColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

// -- section label chip -------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.primary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// -- icon button --------------------------------------------------------------

class _IconBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color borderColor;
  final Color backgroundColor;

  const _IconBtn({
    required this.onTap,
    required this.child,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// -- schedule item ------------------------------------------------------------

class _ScheduleItem extends StatelessWidget {
  final String title;
  final String time;
  final ColorScheme scheme;

  const _ScheduleItem({
    required this.title,
    required this.time,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -- battery bar --------------------------------------------------------------

class _BatteryBar extends StatelessWidget {
  final DeviceBatteryUiState state;
  final Color borderColor;
  final Color mutedColor;
  final ColorScheme scheme;

  const _BatteryBar({
    required this.state,
    required this.borderColor,
    required this.mutedColor,
    required this.scheme,
  });

  Color _barColor() {
    final level = state.level ?? 0;
    if (state.isCharging == true) return const Color(0xFF16A34A);
    if (level <= 20) return const Color(0xFFDC2626);
    if (level <= 50) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    final level = state.level;
    final hasValue = level != null;
    final barColor = _barColor();
    final foreground = hasValue ? barColor : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: mutedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          BatteryIcon(
            level: level ?? 0,
            color: foreground,
            width: 18,
            height: 10,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: hasValue ? (level! / 100.0) : 0,
                minHeight: 5,
                backgroundColor: scheme.outlineVariant.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hasValue ? '$level%' : '--',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
