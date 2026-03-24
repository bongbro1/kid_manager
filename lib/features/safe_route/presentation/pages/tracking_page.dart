library kid_manager.safe_route.tracking_page;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/features/map_engine/controllers/camera_controller.dart';
import 'package:kid_manager/features/safe_route/data/datasources/safe_route_remote_data_source.dart';
import 'package:kid_manager/features/safe_route/data/repositories/safe_route_repository_impl.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_active_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_suggested_routes_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_trip_history_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/start_trip_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/stream_live_location_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/update_trip_status_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/pages/safe_route_history_page.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_tracking_visuals.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_tracking_state.dart';
import 'package:kid_manager/features/safe_route/presentation/viewmodels/safe_route_tracking_view_model.dart';
import 'package:kid_manager/features/safe_route/presentation/widgets/safe_route_bottom_panel.dart';
import 'package:kid_manager/features/subscription/subscription_quota_gate.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/services/location/map_avatar_marker_factory.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/utils/cupertino_time_picker.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';
import 'package:kid_manager/widgets/map/map_place_search_sheet.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

part 'tracking_page/tracking_page_actions.dart';
part 'tracking_page/tracking_page_map_sync.dart';
part 'tracking_page/tracking_page_ui.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({
    super.key,
    required this.childId,
    this.childAvatarUrl,
    this.initialStartPoint,
  });

  final String childId;
  final String? childAvatarUrl;
  final RoutePoint? initialStartPoint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ChangeNotifierProvider(
      create: (_) {
        final repository = SafeRouteRepositoryImpl(
          FirebaseSafeRouteRemoteDataSource(),
        );
        final viewModel = SafeRouteTrackingViewModel(
          childId: childId,
          getSuggestedRoutesUseCase: GetSuggestedRoutesUseCase(repository),
          startTripUseCase: StartTripUseCase(repository),
          streamLiveLocationUseCase: StreamLiveLocationUseCase(repository),
          updateTripStatusUseCase: UpdateTripStatusUseCase(repository),
          getActiveTripByChildIdUseCase: GetActiveTripByChildIdUseCase(
            repository,
          ),
          getTripHistoryByChildIdUseCase: GetTripHistoryByChildIdUseCase(
            repository,
          ),
          getRouteByIdUseCase: GetRouteByIdUseCase(repository),
          l10n: l10n,
          profileRepository: context.read<ProfileRepository>(),
          accessControl: context.read<AccessControlService>(),
        );

        if (initialStartPoint != null) {
          viewModel.applyInitialStartPoint(initialStartPoint!);
        }
        viewModel.initialize();
        return viewModel;
      },
      child: _TrackingPageBody(childAvatarUrl: childAvatarUrl),
    );
  }
}

class _TrackingPageBody extends StatefulWidget {
  const _TrackingPageBody({this.childAvatarUrl});

  final String? childAvatarUrl;

  @override
  State<_TrackingPageBody> createState() => _TrackingPageBodyState();
}

class _TrackingPageBodyState extends State<_TrackingPageBody> {
  static const _emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

  static const _routeSourceId = 'safe-route-source';
  static const _progressSourceId = 'safe-route-progress-source';
  static const _altRouteSourceId = 'safe-route-alt-route-source';
  static const _liveSourceId = 'safe-route-live-source';
  static const _startSourceId = 'safe-route-start-source';
  static const _endSourceId = 'safe-route-end-source';
  static const _hazardSourceId = 'safe-route-hazard-source';
  static const _hazardAreaSourceId = 'safe-route-hazard-area-source';
  static const _liveMarkerIconProperty = 'live_icon_id';
  static const _liveAccuracyProperty = 'accuracy_radius';
  static const _childMarkerSafeIconId = 'safe-route-child-marker-safe';
  static const _childMarkerWarningIconId = 'safe-route-child-marker-warning';
  static const _childMarkerDangerIconId = 'safe-route-child-marker-danger';

  static const _corridorLayerId = 'safe-route-corridor-layer';
  static const _altRouteLayerId = 'safe-route-alt-route-layer';
  static const _routeLayerId = 'safe-route-line-layer';
  static const _progressLayerId = 'safe-route-progress-layer';
  static const _liveAccuracyLayerId = 'safe-route-live-accuracy-layer';
  static const _liveLayerId = 'safe-route-live-layer';
  static const _startLayerId = 'safe-route-start-layer';
  static const _endLayerId = 'safe-route-end-layer';
  static const _hazardAreaLayerId = 'safe-route-hazard-area-layer';
  static const _hazardLayerId = 'safe-route-hazard-layer';

  MapboxMap? _map;
  CameraController? _camera;
  String? _lastRenderedRouteId;
  String? _lastErrorMessage;
  bool _focusedOnce = false;
  bool _showHazards = true;
  bool _isAutoFollowEnabled = true;
  bool _safeRouteStyleReady = false;
  Future<void>? _safeRouteStyleSetupFuture;
  int? _safeRouteStyleSetupSession;
  RouteSelectionMode _lastSelectionMode = RouteSelectionMode.none;
  int? _lastAutoFollowTimestamp;
  DateTime? _lastAutoFollowAt;
  int _mapSession = 0;
  bool _disposed = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final AppMapViewController _mapViewController = AppMapViewController();

  @override
  void initState() {
    super.initState();
    _prefetchChildMarkerImages();
  }

  void _prefetchChildMarkerImages() {
    unawaited(
      Future.wait([
        MapAvatarMarkerFactory.build(
          photoUrlOrData: widget.childAvatarUrl,
          accentColor: const Color(0xFF2563EB),
          size: 72,
        ),
        MapAvatarMarkerFactory.build(
          photoUrlOrData: widget.childAvatarUrl,
          accentColor: const Color(0xFFF59E0B),
          size: 72,
        ),
        MapAvatarMarkerFactory.build(
          photoUrlOrData: widget.childAvatarUrl,
          accentColor: const Color(0xFFEF4444),
          size: 72,
        ),
      ]),
    );
  }

  void _attachMap(MapboxMap map, {bool resetStyle = false}) {
    final isNewMap = !identical(_map, map);
    _mapSession++;
    _map = map;
    _camera = CameraController(map);
    if (resetStyle || isNewMap) {
      _safeRouteStyleReady = false;
      _safeRouteStyleSetupFuture = null;
      _safeRouteStyleSetupSession = null;
      _lastRenderedRouteId = null;
      _focusedOnce = false;
    }
  }

  bool _isMapSessionActive(MapboxMap map, int session) {
    return !_disposed &&
        mounted &&
        identical(_map, map) &&
        _mapSession == session;
  }

  bool _isDetachedChannelError(Object error) {
    if (error is! PlatformException) return false;
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('channel-error') ||
        message.contains('unable to establish connection on channel');
  }

  Future<T?> _runMapQuery<T>({
    required MapboxMap map,
    required int session,
    required String label,
    required Future<T> Function() call,
  }) async {
    if (!_isMapSessionActive(map, session)) return null;
    try {
      return await call();
    } catch (error) {
      if (_isDetachedChannelError(error) ||
          !_isMapSessionActive(map, session)) {
        _log('skip map query after detach: $label');
        return null;
      }
      rethrow;
    }
  }

  Future<bool> _runMapWrite({
    required MapboxMap map,
    required int session,
    required String label,
    required Future<void> Function() call,
  }) async {
    if (!_isMapSessionActive(map, session)) return false;
    try {
      await call();
      return true;
    } catch (error) {
      if (_isDetachedChannelError(error) ||
          !_isMapSessionActive(map, session)) {
        _log('skip map write after detach: $label');
        return false;
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _mapSession++;
    _map = null;
    _camera = null;
    _safeRouteStyleReady = false;
    _safeRouteStyleSetupFuture = null;
    _safeRouteStyleSetupSession = null;
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SafeRouteTrackingViewModel>(
      builder: (context, vm, _) {
        _scheduleSync(vm.state);
        _syncSheetForSelectionMode(vm.state);
        _maybeShowError(vm);

        final state = vm.state;
        final isSelectingOnMap = state.selectionMode != RouteSelectionMode.none;
        final initialSheetSize = isSelectingOnMap
            ? 0.14
            : (state.activeTrip != null ? 0.28 : 0.46);
        final minSheetSize = isSelectingOnMap
            ? 0.12
            : (state.activeTrip != null ? 0.22 : 0.30);

        return Scaffold(
          body: Stack(
            children: [
              AppMapView(
                controller: _mapViewController,
                showInternalMapTypeButton: false,
                followThemeForStreetStyle: false,
                onMapCreated: (map) {
                  _attachMap(map);
                },
                onStyleLoaded: (map) async {
                  if (!mounted || _disposed) return;
                  _attachMap(map, resetStyle: true);
                  await _ensureSafeRouteStyle();
                  if (!mounted || _disposed) return;
                  await _syncMap(state);
                },
                onTapListener: (gesture) async {
                  if (!mounted || _disposed) return;
                  final vm = context.read<SafeRouteTrackingViewModel>();
                  final latestState = vm.state;

                  _log(
                    'tap received with latest mode=${latestState.selectionMode}',
                  );

                  if (latestState.selectionMode == RouteSelectionMode.none) {
                    _log('tap ignored because latest selectionMode = none');
                    return;
                  }

                  final coordinates = gesture.point.coordinates;
                  final mode = latestState.selectionMode;

                  _log(
                    'map tapped: mode=$mode, lat=${coordinates.lat}, lng=${coordinates.lng}',
                  );

                  final pickedPoint = RoutePoint(
                    latitude: coordinates.lat.toDouble(),
                    longitude: coordinates.lng.toDouble(),
                    sequence: mode == RouteSelectionMode.selectingEnd ? 1 : 0,
                  );

                  await _showPickedPointMarker(pickedPoint, mode);

                  vm.onMapPointSelected(
                    pickedPoint.latitude,
                    pickedPoint.longitude,
                  );

                  await _moveCameraToPoint(pickedPoint);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1200),
                      content: Text(
                        mode == RouteSelectionMode.selectingEnd
                            ? AppLocalizations.of(
                                context,
                              ).safeRouteSnackbarSelectedEndPoint
                            : AppLocalizations.of(
                                context,
                              ).safeRouteSnackbarSelectedStartPoint,
                      ),
                    ),
                  );
                },
              ),
              _buildTopBar(state, vm),
              if (isSelectingOnMap) _buildSelectionBanner(state, vm),
              if (!isSelectingOnMap) _buildFloatingControls(state),
              if (!isSelectingOnMap)
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: initialSheetSize,
                  minChildSize: minSheetSize,
                  maxChildSize: 0.82,
                  builder: (context, scrollController) {
                    return SafeRouteBottomPanel(
                      state: state,
                      safetyStatusLabel: vm.safetyStatusLabel,
                      speedLabel: vm.speedLabel,
                      batteryLabel: vm.batteryLabel,
                      lastUpdatedLabel: _lastUpdatedLabel(state),
                      scrollController: scrollController,
                      onUseLiveLocationAsStart: vm.useLiveLocationAsStart,
                      onSearchStart: () => _searchStartPlace(vm, state),
                      onSearchEnd: () => _searchEndPlace(vm, state),
                      onStartSelectingStart: vm.startSelectingStart,
                      onStartSelectingEnd: vm.startSelectingEnd,
                      onClearStart: vm.clearStartPoint,
                      onClearEnd: vm.clearEndPoint,
                      onSelectTravelMode: vm.selectTravelMode,
                      onSwapPoints: vm.swapSelectedPoints,
                      onPickScheduleDate: () => _pickScheduleDate(vm, state),
                      onPickScheduleTime: () => _pickScheduleTime(vm, state),
                      onResetSchedule: vm.resetSchedule,
                      onToggleRepeatWeekday: vm.toggleRepeatWeekday,
                      onShowHistory: () => _showTripHistory(vm),
                      onFetchSuggestedRoutes: vm.fetchSuggestedRoutes,
                      onSelectRoute: vm.selectSuggestedRoute,
                      onToggleAlternativeRoute:
                          vm.toggleAlternativeSuggestedRoute,
                      onStartTrip: vm.startTrip,
                      onCompleteTrip: () => _handleCompleteTrip(vm),
                      onCancelTrip: () => _confirmCancelTrip(vm),
                      onFocusRoute: () => _focusVisibleRoutes(state),
                    );
                  },
                ),
              _buildMapSelectionBottomHint(state),
              if (state.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
