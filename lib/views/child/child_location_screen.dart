import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/sos/incoming_sos_overlay.dart';
import 'package:kid_manager/widgets/sos/sos_view.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/features/map_engine/map_engine.dart';
import 'package:kid_manager/features/safe_route/data/datasources/safe_route_remote_data_source.dart';
import 'package:kid_manager/features/safe_route/data/repositories/safe_route_repository_impl.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_active_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/child_safe_route_guidance.dart';
import 'package:kid_manager/features/safe_route/presentation/states/child_safe_route_state.dart';
import 'package:kid_manager/features/safe_route/presentation/viewmodels/child_safe_route_view_model.dart';
import 'package:kid_manager/features/safe_route/presentation/widgets/child_safe_route_hud.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/viewmodels/locale_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/location/map_bottom_controls.dart';
import 'package:kid_manager/widgets/location/map_top_bar.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';
import 'package:kid_manager/widgets/sos/incoming_sos_overlay.dart';
import 'package:kid_manager/widgets/sos/sos_view.dart';

class ChildLocationScreen extends StatefulWidget {
  const ChildLocationScreen({super.key});

  @override
  State<ChildLocationScreen> createState() => _ChildLocationScreenState();
}
class _ChildLocationScreenState extends State<ChildLocationScreen> {
  MapboxMap? _map;
  MapEngine? _engine;

  bool _autoFollow = true;
  VoidCallback? _vmListener;
  ChildSafeRouteViewModel? _safeRouteVm;
  VoidCallback? _safeRouteListener;
  String? _safeRouteChildId;
  String _safeRouteLanguageCode = 'vi';
  String? _renderedSafeRouteId;
  ChildSafeRouteSeverity? _lastSafeRouteSeverity;
  String? _transientSafeRouteBanner;
  Timer? _transientSafeRouteBannerTimer;

  late ChildLocationViewModel _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildLocationViewModel>().startLocationSharing(
        background: true,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vm = context.read<ChildLocationViewModel>();
  }

  @override
  void dispose() {
    if (_vmListener != null) {
      _vm.removeListener(_vmListener!);
    }
    _disposeSafeRouteVm();
    super.dispose();
  }

  void _disposeSafeRouteVm() {
    if (_safeRouteVm != null && _safeRouteListener != null) {
      _safeRouteVm!.removeListener(_safeRouteListener!);
    }
    _safeRouteVm?.dispose();
    _safeRouteVm = null;
    _safeRouteListener = null;
    _safeRouteChildId = null;
    _renderedSafeRouteId = null;
    _lastSafeRouteSeverity = null;
    _transientSafeRouteBannerTimer?.cancel();
    _transientSafeRouteBannerTimer = null;
  }

  void _showTransientSafeRouteBanner(String message) {
    _transientSafeRouteBannerTimer?.cancel();
    if (mounted) {
      setState(() {
        _transientSafeRouteBanner = message;
      });
    }
    _transientSafeRouteBannerTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _transientSafeRouteBanner = null;
      });
    });
  }

  void _ensureSafeRouteVm({
    required String childId,
    required String languageCode,
    LocationData? initialLocation,
  }) {
    if (_safeRouteVm != null && _safeRouteChildId == childId) {
      if (_safeRouteLanguageCode != languageCode) {
        _safeRouteLanguageCode = languageCode;
        _safeRouteVm!.updateLanguageCode(languageCode);
      }
      return;
    }

    _disposeSafeRouteVm();

    final repository = SafeRouteRepositoryImpl(
      FirebaseSafeRouteRemoteDataSource(),
    );
    final viewModel = ChildSafeRouteViewModel(
      childId: childId,
      getActiveTripByChildIdUseCase: GetActiveTripByChildIdUseCase(repository),
      getRouteByIdUseCase: GetRouteByIdUseCase(repository),
    );

    _safeRouteVm = viewModel;
    _safeRouteChildId = childId;
    _safeRouteLanguageCode = languageCode;
    _safeRouteListener = () {
      final nextSeverity = viewModel.state.guidance?.severity;
      final languageCode = _safeRouteLanguageCode;
      final recoveredToRoute =
          _lastSafeRouteSeverity == ChildSafeRouteSeverity.offRoute &&
          (nextSeverity == ChildSafeRouteSeverity.safe ||
              nextSeverity == ChildSafeRouteSeverity.arrived);
      if (recoveredToRoute) {
        _showTransientSafeRouteBanner(
          languageCode.startsWith('en')
              ? 'Back on the safe route'
              : 'Đã quay lại tuyến an toàn',
        );
      }
      _lastSafeRouteSeverity = nextSeverity;
      unawaited(_syncSafeRouteOverlay());
      if (mounted) {
        setState(() {});
      }
    };
    viewModel.addListener(_safeRouteListener!);
    viewModel.initialize(
      languageCode: languageCode,
      initialLocation: initialLocation,
    );
  }

  Future<void> _syncSafeRouteOverlay() async {
    final engine = _engine;
    final route = _safeRouteVm?.state.activeRoute;
    if (engine == null) return;

    if (route == null) {
      if (_renderedSafeRouteId == null) return;
      await engine.route.renderRoad(const []);
      await engine.route.renderStraightSegments(const []);
      await engine.startEndMarkers.clear();
      _renderedSafeRouteId = null;
      return;
    }

    if (_renderedSafeRouteId == route.id) return;

    final points = _normalizedRoutePoints(route);
    final coords = points
        .map((point) => <double>[point.longitude, point.latitude])
        .toList(growable: false);

    await engine.route.renderRoad(coords);
    await engine.route.renderStraightSegments(const []);

    final markers = [
      _routePointToLocation(points.first, 0),
      _routePointToLocation(points.last, 1),
    ];
    await engine.startEndMarkers.render(markers);

    final fitPoints = points
        .asMap()
        .entries
        .map((entry) => _routePointToLocation(entry.value, entry.key))
        .toList(growable: false);
    if (fitPoints.length >= 2) {
      await engine.camera.fitToRoute(fitPoints);
    }

    _renderedSafeRouteId = route.id;
  }

  List<RoutePoint> _normalizedRoutePoints(SafeRoute route) {
    final routePoints = [...route.points]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (routePoints.length >= 2) {
      return routePoints;
    }
    return [
      route.startPoint.copyWith(sequence: 0),
      route.endPoint.copyWith(sequence: 1),
    ];
  }

  LocationData _routePointToLocation(RoutePoint point, int index) {
    return LocationData(
      latitude: point.latitude,
      longitude: point.longitude,
      accuracy: 0,
      timestamp: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ChildLocationViewModel>();
    final familyId = context.watch<UserVm>().familyId;
    final myUid = context.select<UserVm, String?>((userVm) => userVm.me?.uid);
    final localeCode = context.watch<LocaleVm>().locale.languageCode;
    final hasSosOverlay = familyId != null && myUid != null;

    if (myUid != null) {
      _ensureSafeRouteVm(
        childId: myUid,
        languageCode: localeCode,
        initialLocation: vm.currentLocation,
      );
    }

    final safeRouteState =
        _safeRouteVm?.state ?? ChildSafeRouteState.initial(myUid ?? '');
    final combinedError = vm.error ?? safeRouteState.errorMessage;

    return Stack(
      children: [
        AppMapView(
          onMapCreated: (map) {
            _map = map;
          },
          onStyleLoaded: (map) async {
            _engine = MapEngine(map, enableChildDot: true);
            await _engine!.init();
            if (!mounted) return;
            _renderedSafeRouteId = null;

            final vm = _vm;

            if (_vmListener != null) {
              vm.removeListener(_vmListener!);
            }

            _vmListener = () {
              final loc = vm.currentLocation;
              if (loc == null) return;

              _safeRouteVm?.updateCurrentLocation(loc);
              _engine?.updateChildRealtime(loc);

              if (_autoFollow) {
                _map?.easeTo(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(loc.longitude, loc.latitude),
                    ),
                    zoom: 16,
                  ),
                  MapAnimationOptions(duration: 600),
                );
              }
            };

            vm.addListener(_vmListener!);

            final loc = vm.currentLocation;
            if (loc != null) {
              _safeRouteVm?.updateCurrentLocation(loc);
              await _engine!.updateChildRealtime(loc);
            }
            await _syncSafeRouteOverlay();
          },
        ),

        MapTopBar(onMenuTap: () {}, onAvatarTap: () {}),

        if (_transientSafeRouteBanner != null)
          Positioned(
            left: 20,
            right: 20,
            top: 54,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                child: _SafeRouteNoticeBanner(
                  message: _transientSafeRouteBanner!,
                ),
              ),
            ),
          ),

        if (safeRouteState.guidance != null)
          ChildSafeRouteHud(
            state: safeRouteState,
            languageCode: localeCode,
            topOffset: 88,
            bottomOffset: hasSosOverlay ? 190 : 96,
          ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: MapBottomControls(
              children: const [],
              onMyLocation: () {
                final loc = vm.currentLocation;
                if (loc == null) return;

                _autoFollow = true;

                _map?.easeTo(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(loc.longitude, loc.latitude),
                    ),
                    zoom: 16,
                  ),
                  MapAnimationOptions(duration: 600),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: safeRouteState.guidance != null ? 196 : 90,
          child: SafeArea(
            top: false,
            child: SosCircleButton(
              onPressed: () async {
                final vm = context.read<ChildLocationViewModel>();
                final loc = vm.currentLocation;
                final displayName =
                    context.read<UserVm>().me?.displayName ??
                    l10n.parentLocationUnknownUser;
                final sosVm = context.read<SosViewModel>();

                debugPrint('SOS child tapped');
                debugPrint('SOS loc=$loc');
                debugPrint('SOS sending=${sosVm.sending}');
                debugPrint('SOS familyId=${context.read<UserVm>().familyId}');
                debugPrint('SOS uid=${context.read<UserVm>().me?.uid}');

                if (loc == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.currentLocationError)),
                  );
                  return;
                }

                if (sosVm.sending) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.childLocationSosSending)),
                  );
                  return;
                }

                try {
                  final sosId = await sosVm.triggerSos(
                    lat: loc.latitude,
                    lng: loc.longitude,
                    acc: loc.accuracy,
                    createdByName: displayName,
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sosId != null
                            ? l10n.parentLocationSosSent
                            : l10n.parentLocationSosFailed,
                      ),
                    ),
                  );
                } catch (error, stackTrace) {
                  debugPrint('triggerSos error: $error');
                  debugPrint('$stackTrace');

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.childLocationSosError('$e'))),
                  );
                }
              },
            ),
          ),
        ),
        if (combinedError != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: hasSosOverlay ? 260 : 150,
            child: _ErrorBanner(message: combinedError),
          ),

        if (familyId != null && myUid != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 110,
            child: IncomingSosOverlay(
              key: ValueKey('sos-$familyId'),
              familyId: familyId,
              myUid: myUid,
            ),
          ),
      ],
    );
  }
}

class _SafeRouteNoticeBanner extends StatelessWidget {
  const _SafeRouteNoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5).withOpacity(0.96),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.route_rounded,
                color: Color(0xFF16A34A),
                size: 18,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade600,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
