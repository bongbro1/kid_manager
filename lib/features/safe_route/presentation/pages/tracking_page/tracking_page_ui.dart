part of kid_manager.safe_route.tracking_page;

extension _TrackingPageUi on _TrackingPageBodyState {
  Widget _buildSelectionBanner(
    SafeRouteTrackingState state,
    SafeRouteTrackingViewModel vm,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (state.selectionMode == RouteSelectionMode.none) {
      return const SizedBox.shrink();
    }

    final text = state.selectionMode == RouteSelectionMode.selectingStart
        ? AppLocalizations.of(context).safeRouteMapHintTapStart
        : AppLocalizations.of(context).safeRouteMapHintTapEnd;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 122,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            scheme.primary.withOpacity(0.86),
            locationPanelColor(scheme),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, color: scheme.onPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: scheme.onPrimary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: vm.cancelSelection,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _lastUpdatedLabel(SafeRouteTrackingState state) {
    final timestamp = state.liveLocation?.timestamp;
    if (timestamp == null) return '--';

    final updatedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return AppLocalizations.of(context).safeRouteUpdatedLabel(updatedAt);
  }

  String _topTitle(SafeRouteTrackingState state) {
    final l10n = AppLocalizations.of(context);
    return state.activeTrip == null
        ? l10n.safeRoutePageSelectRouteTitle
        : l10n.safeRoutePageJourneyTitle;
  }

  String _topSubtitle(
    SafeRouteTrackingState state,
    SafeRouteTrackingViewModel vm,
  ) {
    final l10n = AppLocalizations.of(context);
    if (state.activeTrip != null) {
      if (state.activeTrip!.status == TripStatus.planned) {
        return l10n.safeRouteScheduledAutoActivationPrefix(
          _scheduleSummaryLabel(state),
        );
      }
      final visuals = resolveSafeRouteTrackingVisuals(
        state,
        l10n: l10n,
        fallbackStatusLabel: vm.safetyStatusLabel,
      );
      final prefix = switch (visuals.severity) {
        SafeRouteTrackingSeverity.safe => _currentRouteUsageLabel(state),
        SafeRouteTrackingSeverity.warning => l10n.safeRouteTopSubtitleWarning,
        SafeRouteTrackingSeverity.danger => l10n.safeRouteTopSubtitleDanger,
      };
      return '$prefix · ${_formatTime(DateTime.fromMillisecondsSinceEpoch(state.liveLocation?.timestamp ?? DateTime.now().millisecondsSinceEpoch))}';
    }

    final start = state.selectedStart;
    final end = state.selectedEnd;
    if (start != null && end != null) {
      return l10n.safeRouteTopSubtitleReady;
    }
    if (start != null) {
      return l10n.safeRouteTopSubtitleOnlyStart;
    }
    return l10n.safeRouteTopSubtitleChoosePoints;
  }

  String _dateChipLabel(SafeRouteTrackingState state) {
    final l10n = AppLocalizations.of(context);
    if (state.activeTrip != null) {
      final startedAt = state.activeTrip!.startedAt;
      return '${startedAt.day.toString().padLeft(2, '0')}/${startedAt.month.toString().padLeft(2, '0')}/${startedAt.year}';
    }
    final scheduled = state.scheduledDate;
    if (scheduled == null) {
      return l10n.safeRouteTodayLabel;
    }
    final normalized = DateTime(scheduled.year, scheduled.month, scheduled.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (normalized == today) {
      return l10n.safeRouteTodayLabel;
    }
    if (normalized == tomorrow) {
      return l10n.safeRouteTomorrowLabel;
    }
    return '${scheduled.day.toString().padLeft(2, '0')}/${scheduled.month.toString().padLeft(2, '0')}/${scheduled.year}';
  }

  String _timeChipLabel(SafeRouteTrackingState state) {
    if (state.activeTrip != null) {
      final startedAt = state.activeTrip!.startedAt;
      final liveTimestamp =
          state.liveLocation?.timestamp ??
          DateTime.now().millisecondsSinceEpoch;
      return '${_formatTime(startedAt)} – ${_formatTime(DateTime.fromMillisecondsSinceEpoch(liveTimestamp))}';
    }
    return _scheduleSummaryLabel(state);
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _scheduleSummaryLabel(SafeRouteTrackingState state) {
    return AppLocalizations.of(
      context,
    ).safeRouteScheduleSummary(state.scheduledTime, state.repeatWeekdays);
  }

  String _currentRouteUsageLabel(SafeRouteTrackingState state) {
    final l10n = AppLocalizations.of(context);
    final trip = state.activeTrip;
    final activeRoute = state.activeRoute;
    if (trip == null || activeRoute == null) {
      return l10n.notificationJustNow;
    }
    return l10n.safeRouteCurrentRouteUsageLabel(
      activeRoute.id,
      trip.routeId,
      trip.alternativeRouteIds,
    );
  }

  Widget _buildTopBar(
    SafeRouteTrackingState state,
    SafeRouteTrackingViewModel vm,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = resolveSafeRouteTrackingVisuals(
      state,
      l10n: AppLocalizations.of(context),
      fallbackStatusLabel: vm.safetyStatusLabel,
    );
    final isActiveTrip = state.activeTrip != null;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 14,
      right: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isActiveTrip
                      ? visuals.bannerColor
                      : locationPanelColor(scheme))
                  .withOpacity(0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActiveTrip
                    ? visuals.borderColor.withOpacity(0.82)
                    : locationPanelBorderColor(scheme),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildCircleAction(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _topTitle(state),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color:
                              visuals.severity ==
                                  SafeRouteTrackingSeverity.danger
                              ? const Color(0xFF991B1B)
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: visuals.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _topSubtitle(state, vm),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: visuals.accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildChildAvatarBadge(),
                const SizedBox(width: 10),
                _buildCircleAction(
                  icon: Icons.refresh_rounded,
                  onTap: vm.refreshActiveTrip,
                  tint: isActiveTrip ? visuals.softColor : null,
                  iconColor: isActiveTrip ? visuals.accentColor : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderChip(
                icon: Icons.calendar_today_rounded,
                label: _dateChipLabel(state),
                tint: isActiveTrip
                    ? visuals.softColor
                    : locationPanelColor(scheme),
                foregroundColor: isActiveTrip
                    ? visuals.accentColor
                    : scheme.onSurfaceVariant,
                borderColor: isActiveTrip
                    ? visuals.borderColor.withOpacity(0.72)
                    : locationPanelBorderColor(scheme),
              ),
              _buildHeaderChip(
                icon: Icons.schedule_rounded,
                label: _timeChipLabel(state),
                tint: isActiveTrip
                    ? visuals.softColor
                    : locationPanelColor(scheme),
                foregroundColor: isActiveTrip
                    ? visuals.accentColor
                    : scheme.onSurfaceVariant,
                borderColor: isActiveTrip
                    ? visuals.borderColor.withOpacity(0.72)
                    : locationPanelBorderColor(scheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
    Color? tint,
    Color? iconColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: tint ?? locationPanelColor(scheme),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChildAvatarBadge() {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = widget.childAvatarUrl?.trim() ?? '';
    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locationPanelColor(scheme),
        border: Border.all(color: locationPanelBorderColor(scheme), width: 1.6),
      ),
      child: avatarUrl.isEmpty
          ? Icon(
              Icons.child_care_rounded,
              size: 18,
              color: scheme.primary,
            )
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.child_care_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required Color tint,
    required Color foregroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
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

  Widget _buildFloatingControls(SafeRouteTrackingState state) {
    final visuals = resolveSafeRouteTrackingVisuals(
      state,
      l10n: AppLocalizations.of(context),
      fallbackStatusLabel: AppLocalizations.of(
        context,
      ).safeRouteTripStatusActive,
    );
    return Positioned(
      right: 14,
      top: MediaQuery.of(context).padding.top + 132,
      child: Column(
        children: [
          _buildMapFab(
            icon: Icons.my_location_rounded,
            onTap: () => _focusLiveLocation(state),
            tooltip: AppLocalizations.of(context).safeRouteTooltipFocusChild,
          ),
          const SizedBox(height: 10),
          _buildMapFab(
            icon: Icons.gps_fixed_rounded,
            onTap: () => _toggleAutoFollow(state),
            active: _isAutoFollowEnabled,
            tooltip: _isAutoFollowEnabled
                ? AppLocalizations.of(context).safeRouteTooltipDisableAutoFollow
                : AppLocalizations.of(context).safeRouteTooltipEnableAutoFollow,
            label: AppLocalizations.of(context).safeRouteAutoFollowLabel,
            showLabel: true,
          ),
          const SizedBox(height: 10),
          _buildMapFab(
            icon: Icons.warning_amber_rounded,
            onTap: () => _toggleHazards(state),
            active: _showHazards,
            activeColor: visuals.accentColor,
            tooltip: _showHazards
                ? AppLocalizations.of(context).safeRouteTooltipHideHazards
                : AppLocalizations.of(context).safeRouteTooltipShowHazards,
          ),
          const SizedBox(height: 10),
          _buildMapFab(
            icon: Icons.layers_rounded,
            onTap: _mapViewController.showMapSelector,
            tooltip: AppLocalizations.of(context).safeRouteTooltipMapType,
          ),
        ],
      ),
    );
  }

  Widget _buildMapFab({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool active = false,
    Color activeColor = const Color(0xFF1A73E8),
    String? label,
    bool showLabel = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: active ? activeColor : locationPanelColor(scheme),
            borderRadius: BorderRadius.circular(16),
            elevation: 3,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  icon,
                  color: active ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (showLabel && label != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: locationPanelColor(scheme).withOpacity(0.94),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: active ? activeColor : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapSelectionBottomHint(SafeRouteTrackingState state) {
    final scheme = Theme.of(context).colorScheme;
    if (state.selectionMode == RouteSelectionMode.none) {
      return const SizedBox.shrink();
    }

    final text = state.selectionMode == RouteSelectionMode.selectingStart
        ? AppLocalizations.of(context).safeRouteMapHintPlaceStart
        : AppLocalizations.of(context).safeRouteMapHintPlaceEnd;

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: locationPanelColor(scheme).withOpacity(0.94),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.map_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
