import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/live_location.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';

enum RouteSelectionMode {
  none,
  selectingStart,
  selectingEnd,
}

class SafeRouteTrackingState {
  static const Object _unset = Object();

  final String childId;
  final bool isLoading;
  final bool isFetchingSuggestions;
  final bool isStartingTrip;
  final TripMutationState tripMutation;
  final RouteSelectionMode selectionMode;
  final SafeRouteTravelMode selectedTravelMode;
  final RoutePoint? selectedStart;
  final RoutePoint? selectedEnd;
  final String? selectedStartLabel;
  final String? selectedEndLabel;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final List<int> repeatWeekdays;
  final List<SafeRoute> suggestedRoutes;
  final SafeRoute? selectedRoute;
  final List<String> selectedAlternativeRouteIds;
  final Trip? activeTrip;
  final SafeRoute? activeRoute;
  final List<SafeRoute> activeAlternativeRoutes;
  final LiveLocation? liveLocation;
  final String? completedTripConfirmationTripId;
  final String? errorMessage;

  const SafeRouteTrackingState({
    required this.childId,
    required this.isLoading,
    required this.isFetchingSuggestions,
    required this.isStartingTrip,
    required this.tripMutation,
    required this.selectionMode,
    required this.selectedTravelMode,
    required this.selectedStart,
    required this.selectedEnd,
    required this.selectedStartLabel,
    required this.selectedEndLabel,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.repeatWeekdays,
    required this.suggestedRoutes,
    required this.selectedRoute,
    required this.selectedAlternativeRouteIds,
    required this.activeTrip,
    required this.activeRoute,
    required this.activeAlternativeRoutes,
    required this.liveLocation,
    required this.completedTripConfirmationTripId,
    required this.errorMessage,
  });

  factory SafeRouteTrackingState.initial(String childId) {
    return SafeRouteTrackingState(
      childId: childId,
      isLoading: false,
      isFetchingSuggestions: false,
      isStartingTrip: false,
      tripMutation: TripMutationState.none,
      selectionMode: RouteSelectionMode.none,
      selectedTravelMode: SafeRouteTravelMode.walking,
      selectedStart: null,
      selectedEnd: null,
      selectedStartLabel: null,
      selectedEndLabel: null,
      scheduledDate: null,
      scheduledTime: null,
      repeatWeekdays: const [],
      suggestedRoutes: const [],
      selectedRoute: null,
      selectedAlternativeRouteIds: const [],
      activeTrip: null,
      activeRoute: null,
      activeAlternativeRoutes: const [],
      liveLocation: null,
      completedTripConfirmationTripId: null,
      errorMessage: null,
    );
  }

  bool get hasActiveTrip => activeTrip != null;

  SafeRouteTrackingState copyWith({
    bool? isLoading,
    bool? isFetchingSuggestions,
    bool? isStartingTrip,
    TripMutationState? tripMutation,
    RouteSelectionMode? selectionMode,
    SafeRouteTravelMode? selectedTravelMode,
    Object? selectedStart = _unset,
    Object? selectedEnd = _unset,
    Object? selectedStartLabel = _unset,
    Object? selectedEndLabel = _unset,
    Object? scheduledDate = _unset,
    Object? scheduledTime = _unset,
    List<int>? repeatWeekdays,
    List<SafeRoute>? suggestedRoutes,
    List<String>? selectedAlternativeRouteIds,
    SafeRoute? selectedRoute,
    Trip? activeTrip,
    SafeRoute? activeRoute,
    List<SafeRoute>? activeAlternativeRoutes,
    LiveLocation? liveLocation,
    Object? completedTripConfirmationTripId = _unset,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearSelectedRoute = false,
    bool clearActiveTrip = false,
    bool clearActiveRoute = false,
  }) {
    return SafeRouteTrackingState(
      childId: childId,
      isLoading: isLoading ?? this.isLoading,
      isFetchingSuggestions: isFetchingSuggestions ?? this.isFetchingSuggestions,
      isStartingTrip: isStartingTrip ?? this.isStartingTrip,
      tripMutation: tripMutation ?? this.tripMutation,
      selectionMode: selectionMode ?? this.selectionMode,
      selectedTravelMode: selectedTravelMode ?? this.selectedTravelMode,
      selectedStart: identical(selectedStart, _unset)
          ? this.selectedStart
          : selectedStart as RoutePoint?,
      selectedEnd: identical(selectedEnd, _unset)
          ? this.selectedEnd
          : selectedEnd as RoutePoint?,
      selectedStartLabel: identical(selectedStartLabel, _unset)
          ? this.selectedStartLabel
          : selectedStartLabel as String?,
      selectedEndLabel: identical(selectedEndLabel, _unset)
          ? this.selectedEndLabel
          : selectedEndLabel as String?,
      scheduledDate: identical(scheduledDate, _unset)
          ? this.scheduledDate
          : scheduledDate as DateTime?,
      scheduledTime: identical(scheduledTime, _unset)
          ? this.scheduledTime
          : scheduledTime as TimeOfDay?,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      suggestedRoutes: suggestedRoutes ?? this.suggestedRoutes,
      selectedAlternativeRouteIds:
          selectedAlternativeRouteIds ?? this.selectedAlternativeRouteIds,
      selectedRoute: clearSelectedRoute ? null : selectedRoute ?? this.selectedRoute,
      activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
      activeRoute: clearActiveRoute ? null : activeRoute ?? this.activeRoute,
      activeAlternativeRoutes:
          clearActiveRoute ? const [] : activeAlternativeRoutes ?? this.activeAlternativeRoutes,
      liveLocation: liveLocation ?? this.liveLocation,
      completedTripConfirmationTripId:
          identical(completedTripConfirmationTripId, _unset)
          ? this.completedTripConfirmationTripId
          : completedTripConfirmationTripId as String?,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
