part of kid_manager.safe_route.tracking_page;

extension _TrackingPageActions on _TrackingPageBodyState {
  Future<void> _focusLiveLocation(SafeRouteTrackingState state) async {
    final map = _map;
    final session = _mapSession;
    if (map == null) return;
    final live = state.liveLocation;
    if (live == null) return;

    await _runMapWrite(
      map: map,
      session: session,
      label: 'setCamera:focusLiveLocation',
      call: () => map.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(live.longitude, live.latitude)),
          zoom: 15.8,
        ),
      ),
    );
  }

  Future<void> _toggleHazards(SafeRouteTrackingState state) async {
    setState(() => _showHazards = !_showHazards);
    await _syncMap(state);
  }

  Future<void> _toggleAutoFollow(SafeRouteTrackingState state) async {
    final nextValue = !_isAutoFollowEnabled;
    setState(() => _isAutoFollowEnabled = nextValue);

    if (nextValue) {
      _lastAutoFollowTimestamp = null;
      _lastAutoFollowAt = null;
      await _focusLiveLocation(state);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          nextValue
              ? AppLocalizations.of(context).safeRouteSnackbarAutoFollowEnabled
              : AppLocalizations.of(
                  context,
                ).safeRouteSnackbarAutoFollowDisabled,
        ),
      ),
    );
  }

  Future<void> _moveCameraToPoint(RoutePoint point) async {
    final map = _map;
    final session = _mapSession;
    if (map == null) return;
    await _runMapWrite(
      map: map,
      session: session,
      label: 'setCamera:moveToPoint',
      call: () => map.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(point.longitude, point.latitude)),
          zoom: 15.6,
        ),
      ),
    );
  }

  Future<void> _searchStartPlace(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final result = await showMapPlaceSearchSheet(
      context: context,
      title: AppLocalizations.of(context).safeRouteSearchStartTitle,
      hintText: AppLocalizations.of(context).safeRouteSearchStartHint,
      initialQuery: state.selectedStartLabel ?? '',
      proximityLatitude: state.liveLocation?.latitude,
      proximityLongitude: state.liveLocation?.longitude,
    );
    if (!mounted || result == null) return;

    final point = RoutePoint(
      latitude: result.latitude,
      longitude: result.longitude,
      sequence: 0,
    );
    vm.setStartPoint(point, label: result.name);
    await _moveCameraToPoint(point);
  }

  Future<void> _searchEndPlace(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final proximityLat =
        state.selectedStart?.latitude ?? state.liveLocation?.latitude;
    final proximityLng =
        state.selectedStart?.longitude ?? state.liveLocation?.longitude;

    final result = await showMapPlaceSearchSheet(
      context: context,
      title: AppLocalizations.of(context).safeRouteSearchEndTitle,
      hintText: AppLocalizations.of(context).safeRouteSearchEndHint,
      initialQuery: state.selectedEndLabel ?? '',
      proximityLatitude: proximityLat,
      proximityLongitude: proximityLng,
    );
    if (!mounted || result == null) return;

    final point = RoutePoint(
      latitude: result.latitude,
      longitude: result.longitude,
      sequence: 1,
    );
    vm.setEndPoint(point, label: result.name);
    await _moveCameraToPoint(point);
  }

  Future<void> _pickScheduleDate(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.scheduledDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: AppLocalizations.of(context).safeRouteSelectScheduleDateHelp,
      cancelText: AppLocalizations.of(context).cancelButton,
      confirmText: AppLocalizations.of(context).confirmButton,
    );
    if (!mounted || picked == null) return;
    vm.setScheduledDate(picked);
  }

  Future<void> _pickScheduleTime(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final picked = await AppWheelTimePicker.show(
      context,
      title: AppLocalizations.of(context).safeRouteSelectScheduleTimeTitle,
      initial: state.scheduledTime,
      minuteInterval: 1,
    );
    if (!mounted || picked == null) return;
    vm.setScheduledTime(picked);
  }

  Future<void> _showTripHistory(SafeRouteTrackingViewModel vm) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SafeRouteHistoryPage(
          childId: vm.state.childId,
          childAvatarUrl: widget.childAvatarUrl,
        ),
      ),
    );
  }

  Future<void> _showArrivedSuccessDialog(SafeRouteTrackingViewModel vm) async {
    await NotificationDialog.show(
      context,
      type: DialogType.success,
      title: AppLocalizations.of(context).safeRouteArrivedDialogTitle,
      message: AppLocalizations.of(context).safeRouteArrivedDialogMessage,
      confirmText: AppLocalizations.of(context).safeRouteArrivedDialogConfirm,
      onConfirm: () {
        vm.returnToRouteSelection();
        vm.clearCompletedTripConfirmation();
      },
    );
  }

  Future<void> _handleCompleteTrip(SafeRouteTrackingViewModel vm) async {
    final activeTrip = vm.state.activeTrip;
    if (activeTrip == null) return;

    if (activeTrip.status == TripStatus.completed) {
      vm.returnToRouteSelection();
      return;
    }

    await vm.completeTrip();
  }

  Future<void> _confirmCancelTrip(SafeRouteTrackingViewModel vm) async {
    final activeTrip = vm.state.activeTrip;
    if (activeTrip == null) return;

    final isPlanned = activeTrip.status == TripStatus.planned;
    await NotificationDialog.show(
      context,
      type: DialogType.warning,
      title: isPlanned
          ? AppLocalizations.of(context).safeRouteCancelPlannedTitle
          : AppLocalizations.of(context).safeRouteCancelActiveTitle,
      message: isPlanned
          ? AppLocalizations.of(context).safeRouteCancelPlannedMessage
          : AppLocalizations.of(context).safeRouteCancelActiveMessage,
      confirmText: isPlanned
          ? AppLocalizations.of(context).safeRouteCancelPlannedConfirm
          : AppLocalizations.of(context).safeRouteCancelActiveConfirm,
      cancelText: AppLocalizations.of(context).safeRouteDialogBack,
      onConfirm: () {
        unawaited(vm.cancelTrip());
      },
    );
  }
}
