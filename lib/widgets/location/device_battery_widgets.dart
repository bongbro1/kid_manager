import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/location/batterIcon.dart';

enum DeviceBatterySeverity { unavailable, normal, low, critical }

class DeviceBatteryUiState {
  const DeviceBatteryUiState({
    required this.level,
    required this.isCharging,
    required this.isStale,
    required this.severity,
  });

  factory DeviceBatteryUiState.fromSnapshot({
    required num? batteryLevel,
    required bool? isCharging,
    required int? timestampMs,
    DateTime? now,
    Duration staleAfter = const Duration(minutes: 5),
  }) {
    final normalizedLevel = batteryLevel == null
        ? null
        : batteryLevel.round().clamp(0, 100) as int;
    final charging = isCharging == true;
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final stale =
        timestampMs == null || nowMs - timestampMs > staleAfter.inMilliseconds;

    if (normalizedLevel == null) {
      return const DeviceBatteryUiState(
        level: null,
        isCharging: false,
        isStale: true,
        severity: DeviceBatterySeverity.unavailable,
      );
    }

    if (charging || stale) {
      return DeviceBatteryUiState(
        level: normalizedLevel,
        isCharging: charging,
        isStale: stale,
        severity: DeviceBatterySeverity.normal,
      );
    }

    final severity = normalizedLevel <= 10
        ? DeviceBatterySeverity.critical
        : normalizedLevel <= 20
        ? DeviceBatterySeverity.low
        : DeviceBatterySeverity.normal;

    return DeviceBatteryUiState(
      level: normalizedLevel,
      isCharging: charging,
      isStale: stale,
      severity: severity,
    );
  }

  final int? level;
  final bool isCharging;
  final bool isStale;
  final DeviceBatterySeverity severity;

  bool get hasValue => level != null;

  double get progress {
    final value = level;
    if (value == null) return 0;
    return (value / 100).clamp(0.0, 1.0);
  }

  String percentLabel(AppLocalizations l10n) {
    final value = level;
    if (value == null) {
      return l10n.deviceBatteryUnavailableLabel;
    }
    return '$value%';
  }

  String statusLabel(AppLocalizations l10n) {
    if (level == null) {
      return l10n.deviceBatteryUnavailableLabel;
    }
    if (isStale) {
      return l10n.deviceBatteryLastKnownLabel;
    }
    if (isCharging) {
      return l10n.deviceBatteryChargingLabel;
    }
    switch (severity) {
      case DeviceBatterySeverity.critical:
        return l10n.deviceBatteryCriticalLabel;
      case DeviceBatterySeverity.low:
        return l10n.deviceBatteryLowLabel;
      case DeviceBatterySeverity.normal:
        return l10n.deviceBatteryNormalLabel;
      case DeviceBatterySeverity.unavailable:
        return l10n.deviceBatteryUnavailableLabel;
    }
  }

  Color accentColor() {
    if (level == null || isStale) {
      return const Color(0xFF6B7280);
    }
    if (isCharging) {
      return const Color(0xFF2563EB);
    }
    switch (severity) {
      case DeviceBatterySeverity.critical:
        return const Color(0xFFDC2626);
      case DeviceBatterySeverity.low:
        return const Color(0xFFD97706);
      case DeviceBatterySeverity.normal:
        return const Color(0xFF16A34A);
      case DeviceBatterySeverity.unavailable:
        return const Color(0xFF6B7280);
    }
  }

  Color backgroundTint() {
    final base = accentColor();
    return base.withOpacity(isStale ? 0.08 : 0.14);
  }

  Color borderColor() {
    return accentColor().withOpacity(isStale ? 0.20 : 0.28);
  }

  Color progressColor() {
    return accentColor();
  }

  Color foregroundColor(ColorScheme scheme) {
    if (level == null) {
      return scheme.onSurfaceVariant;
    }
    return isStale ? scheme.onSurfaceVariant : accentColor();
  }
}

class DeviceBatteryCompactBadge extends StatelessWidget {
  const DeviceBatteryCompactBadge({
    super.key,
    required this.state,
    this.showWhenUnavailable = false,
  });

  final DeviceBatteryUiState state;
  final bool showWhenUnavailable;

  @override
  Widget build(BuildContext context) {
    if (!state.hasValue && !showWhenUnavailable) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final label = state.percentLabel(AppLocalizations.of(context));
    final foregroundColor = state.foregroundColor(scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: state.backgroundTint(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: state.borderColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BatteryIcon(
            level: state.level ?? 0,
            color: foregroundColor,
            width: 18,
            height: 10,
          ),
          if (state.isCharging) ...[
            const SizedBox(width: 4),
            Icon(Icons.bolt_rounded, size: 12, color: foregroundColor),
          ],
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceBatteryPanelCard extends StatelessWidget {
  const DeviceBatteryPanelCard({
    super.key,
    required this.state,
    this.title,
    this.showPlaceholderWhenUnavailable = true,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
    this.borderColor,
  });

  final DeviceBatteryUiState state;
  final String? title;
  final bool showPlaceholderWhenUnavailable;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (!state.hasValue && !showPlaceholderWhenUnavailable) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final resolvedTitle = title ?? l10n.deviceBatteryTitle;
    final resolvedBackground =
        backgroundColor ?? state.backgroundTint().withOpacity(0.9);
    final resolvedBorder = borderColor ?? state.borderColor();
    final labelColor = scheme.onSurfaceVariant;
    final foregroundColor = state.foregroundColor(scheme);
    final percentLabel = state.percentLabel(l10n);
    final statusLabel = state.statusLabel(l10n);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: resolvedBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            resolvedTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              BatteryIcon(
                level: state.level ?? 0,
                color: foregroundColor,
                width: 24,
                height: 13,
              ),
              if (state.isCharging) ...[
                const SizedBox(width: 6),
                Icon(Icons.bolt_rounded, size: 16, color: foregroundColor),
              ],
              const Spacer(),
              Text(
                percentLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(state.progressColor()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: state.isStale ? scheme.onSurfaceVariant : foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceBatteryPill extends StatelessWidget {
  const DeviceBatteryPill({
    super.key,
    required this.state,
    this.showPlaceholderWhenUnavailable = true,
  });

  final DeviceBatteryUiState state;
  final bool showPlaceholderWhenUnavailable;

  @override
  Widget build(BuildContext context) {
    if (!state.hasValue && !showPlaceholderWhenUnavailable) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = state.percentLabel(l10n);
    final statusLabel = state.statusLabel(l10n);
    final foregroundColor = state.foregroundColor(scheme);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: state.backgroundTint(),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: state.borderColor()),
      ),
      child: Row(
        children: [
          BatteryIcon(
            level: state.level ?? 0,
            color: foregroundColor,
            width: 24,
            height: 13,
          ),
          if (state.isCharging) ...[
            const SizedBox(width: 6),
            Icon(Icons.bolt_rounded, size: 16, color: foregroundColor),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  state.progressColor(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: state.isStale
                      ? scheme.onSurfaceVariant
                      : foregroundColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
