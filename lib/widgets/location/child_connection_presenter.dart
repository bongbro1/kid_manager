import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';

enum ChildConnectionState { live, connectionLost, noLocationYet }

class ChildConnectionPresentation {
  const ChildConnectionPresentation({
    required this.state,
    required this.latest,
  });

  factory ChildConnectionPresentation.fromLocation(
    LocationData? latest, {
    DateTime? now,
    Duration staleAfter = const Duration(minutes: 5),
  }) {
    if (latest == null) {
      return const ChildConnectionPresentation(
        state: ChildConnectionState.noLocationYet,
        latest: null,
      );
    }

    final anchor = now ?? DateTime.now();
    final isStale =
        anchor.difference(latest.dateTime).inMilliseconds >
        staleAfter.inMilliseconds;

    return ChildConnectionPresentation(
      state: isStale
          ? ChildConnectionState.connectionLost
          : ChildConnectionState.live,
      latest: latest,
    );
  }

  final ChildConnectionState state;
  final LocationData? latest;

  bool get isLive => state == ChildConnectionState.live;
  bool get hasLocation => latest != null;

  String label(AppLocalizations l10n) {
    switch (state) {
      case ChildConnectionState.live:
        return l10n.memberManagementOnline;
      case ChildConnectionState.connectionLost:
        return l10n.childConnectionLost;
      case ChildConnectionState.noLocationYet:
        return l10n.childNoLocationYet;
    }
  }

  String? secondaryLabel(AppLocalizations l10n) {
    if (state != ChildConnectionState.connectionLost || latest == null) {
      return null;
    }
    return l10n.childLastSeenAt(_formatTime(latest!.dateTime));
  }

  String? activityLabel(AppLocalizations l10n, {DateTime? now}) {
    final current = latest;
    if (current == null) {
      return null;
    }

    final anchor = now ?? DateTime.now();
    final diff = anchor.difference(current.dateTime);
    if (diff.inSeconds < 60) {
      return l10n.childLocationUpdatedJustNow;
    }
    if (diff.inMinutes == 1) {
      return l10n.childLocationUpdatedOneMinuteAgo;
    }
    if (diff.inMinutes < 60) {
      return l10n.childLocationUpdatedMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours == 1) {
      return l10n.childLocationUpdatedOneHourAgo;
    }
    return l10n.childLocationUpdatedHoursAgo(diff.inHours);
  }

  String summaryLabel(AppLocalizations l10n, {DateTime? now}) {
    final detail = switch (state) {
      ChildConnectionState.live => activityLabel(l10n, now: now),
      ChildConnectionState.connectionLost => secondaryLabel(l10n),
      ChildConnectionState.noLocationYet => null,
    };
    if (detail == null || detail.isEmpty) {
      return label(l10n);
    }
    return '${label(l10n)} · $detail';
  }

  Color dotColor(ColorScheme scheme) {
    switch (state) {
      case ChildConnectionState.live:
        return const Color(0xFF16A34A);
      case ChildConnectionState.connectionLost:
        return const Color(0xFFD97706);
      case ChildConnectionState.noLocationYet:
        return scheme.outline;
    }
  }

  Color textColor(ColorScheme scheme) {
    switch (state) {
      case ChildConnectionState.live:
        return const Color(0xFF16A34A);
      case ChildConnectionState.connectionLost:
        return const Color(0xFFD97706);
      case ChildConnectionState.noLocationYet:
        return scheme.onSurfaceVariant;
    }
  }

  String _formatTime(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }
}

class ChildConnectionStatusHeader extends StatelessWidget {
  const ChildConnectionStatusHeader({
    super.key,
    required this.presentation,
    required this.scheme,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  final ChildConnectionPresentation presentation;
  final ColorScheme scheme;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = presentation.textColor(scheme);
    final secondary = presentation.secondaryLabel(l10n);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: presentation.dotColor(scheme),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  presentation.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          if (secondary != null) ...[
            const SizedBox(height: 4),
            Text(
              secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
