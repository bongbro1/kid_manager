import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

extension SafeRouteL10nX on AppLocalizations {
  String safeRouteTripStatusLabel(TripStatus? status) {
    switch (status) {
      case TripStatus.active:
        return safeRouteTripStatusActive;
      case TripStatus.temporarilyDeviated:
        return safeRouteTripStatusTemporarilyDeviated;
      case TripStatus.deviated:
        return safeRouteTripStatusDeviated;
      case TripStatus.completed:
        return safeRouteTripStatusCompleted;
      case TripStatus.cancelled:
        return safeRouteTripStatusCancelled;
      case TripStatus.planned:
        return safeRouteTripStatusPlanned;
      case null:
        return safeRouteTripStatusNoTrip;
    }
  }

  String safeRouteTravelModeLabel(SafeRouteTravelMode mode) {
    switch (mode) {
      case SafeRouteTravelMode.walking:
        return safeRouteTravelModeWalking;
      case SafeRouteTravelMode.motorbike:
        return safeRouteTravelModeMotorbike;
      case SafeRouteTravelMode.pickup:
        return safeRouteTravelModePickup;
      case SafeRouteTravelMode.otherVehicle:
        return safeRouteTravelModeOtherVehicle;
    }
  }

  String safeRouteWeekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return scheduleWeekdayMon;
      case 2:
        return scheduleWeekdayTue;
      case 3:
        return scheduleWeekdayWed;
      case 4:
        return scheduleWeekdayThu;
      case 5:
        return scheduleWeekdayFri;
      case 6:
        return scheduleWeekdaySat;
      case 7:
        return scheduleWeekdaySun;
    }
    return '';
  }

  String safeRouteDistanceLabel(double meters) {
    if (meters >= 1000) {
      return safeRouteDistanceKilometers((meters / 1000).toStringAsFixed(1));
    }
    return safeRouteDistanceMeters(meters.round());
  }

  String safeRouteDistanceCompactLabel(double meters) {
    if (meters <= 0) {
      return safeRouteDistanceMeters(0);
    }
    if (meters >= 1000) {
      return safeRouteDistanceKilometers(
        (meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1),
      );
    }
    return safeRouteDistanceMeters(meters.round());
  }

  String safeRouteDurationLabel(double durationSeconds) {
    final minutes = (durationSeconds / 60).round();
    if (minutes <= 0) return '--';
    if (minutes < 60) {
      return safeRouteDurationMinutes(minutes);
    }
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    if (remainMinutes == 0) {
      return safeRouteDurationHours(hours);
    }
    return safeRouteDurationHoursMinutes(hours, remainMinutes);
  }

  String safeRouteDurationShortLabel(double durationSeconds) {
    final minutes = (durationSeconds / 60).round();
    if (minutes <= 0) return '--';
    if (minutes < 60) {
      return safeRouteDurationMinutes(minutes);
    }
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    if (remainMinutes == 0) {
      return safeRouteDurationHours(hours);
    }
    return safeRouteDurationHoursMinutesShort(hours, remainMinutes);
  }

  String safeRouteEtaApproxLabel(double durationSeconds) {
    final minutes = (durationSeconds / 60).round();
    if (minutes <= 0) return '--';
    if (minutes < 60) {
      return safeRouteEtaApproxMinutes(minutes);
    }
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    if (remainMinutes == 0) {
      return safeRouteEtaApproxHours(hours);
    }
    return safeRouteEtaApproxHoursMinutes(hours, remainMinutes);
  }

  String safeRouteFormattedDateLabel(DateTime? value) {
    if (value == null) return safeRouteTodayLabel;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final normalized = DateTime(value.year, value.month, value.day);

    if (normalized == today) return safeRouteTodayLabel;
    if (normalized == tomorrow) return safeRouteTomorrowLabel;

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String safeRouteFormattedTimeLabel(TimeOfDay? value) {
    if (value == null) return safeRouteNowLabel;
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String safeRouteDateTimeLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')} · '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String safeRouteDateTimeShortLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String safeRouteUpdatedLabel(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inSeconds < 5) return notificationJustNow;
    if (diff.inMinutes < 1) return safeRouteSecondsAgo(diff.inSeconds);
    if (diff.inHours < 1) return notificationMinutesAgo(diff.inMinutes);
    return safeRouteFormatTime(value.hour, value.minute);
  }

  String safeRouteScheduleSummary(
    TimeOfDay? scheduledTime,
    List<int> repeatWeekdays,
  ) {
    final pieces = <String>[];
    if (scheduledTime != null) {
      pieces.add(safeRouteFormattedTimeLabel(scheduledTime));
    }
    if (repeatWeekdays.isNotEmpty) {
      pieces.add(repeatWeekdays.map(safeRouteWeekdayShort).join(', '));
    }
    if (pieces.isEmpty) return safeRouteTrackNowLabel;
    return pieces.join(' · ');
  }

  String safeRouteRepeatSummary(List<int> repeatWeekdays) {
    if (repeatWeekdays.isEmpty) {
      return safeRouteNoRepeatSummary;
    }
    return safeRouteRepeatSummaryText(
      repeatWeekdays.map(safeRouteWeekdayShort).join(', '),
    );
  }

  String safeRouteCurrentRouteUsageLabel(
    String? activeRouteId,
    String? primaryRouteId,
    List<String> alternativeRouteIds,
  ) {
    if (activeRouteId == null || primaryRouteId == null) {
      return safeRouteCurrentRoutePrimary;
    }
    if (activeRouteId == primaryRouteId) {
      return safeRouteCurrentRoutePrimary;
    }
    final alternativeIndex = alternativeRouteIds.indexOf(activeRouteId);
    if (alternativeIndex >= 0) {
      return safeRouteCurrentRouteAlternativeIndexed(alternativeIndex + 1);
    }
    return safeRouteCurrentRouteAlternative;
  }

  String safeRouteRouteFallbackName(String routeId) {
    final shortId = routeId.substring(
      0,
      routeId.length < 8 ? routeId.length : 8,
    );
    return safeRouteRouteFallbackNameText(shortId);
  }
}
