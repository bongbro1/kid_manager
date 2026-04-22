import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/helpers/zone/zone_circle.dart';
import 'package:kid_manager/helpers/zone/zone_overlap.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';
import 'package:kid_manager/widgets/map/marker_icon_factory.dart';
import 'package:kid_manager/widgets/map/map_ornaments.dart';
import 'package:kid_manager/widgets/map/zone_map_renderer.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

import 'zone_circle_painter.dart';
import 'zone_overlay_widgets.dart';

class EditZoneScreen extends StatefulWidget {
  final String childId;
  final GeoZone? zone;
  final List<GeoZone> existingZones;

  const EditZoneScreen({
    super.key,
    required this.childId,
    required this.zone,
    required this.existingZones,
  });

  @override
  State<EditZoneScreen> createState() => _EditZoneScreenState();
}

class _EditZoneScreenState extends State<EditZoneScreen> {
  mbx.MapboxMap? _map;
  ZoneMapRenderer? _renderer;

  late ZoneType _type;
  late double _radiusM;
  late String _name;
  late final TextEditingController _nameCtrl;

  bool _styleReady = false;
  mbx.Position? _center;
  double _metersPerPixel = 1;

  final GlobalKey _overlayKey = GlobalKey();
  bool _draggingHandle = false;

  bool _isOverlapping = false;
  GeoZone? _overlapWith;

  TextStyle _zoneTypeSelectionTextStyle(BuildContext context) {
    final base = Theme.of(context).appTypography.body;
    final resolvedFontSize = context.isCompactPhone
        ? 13.0
        : context.isTabletOrLarger
        ? 15.0
        : 14.0;

    return base.copyWith(
      fontFamily: 'Poppins',
      fontSize: resolvedFontSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }

  Widget _buildZoneTypeOption({
    required BuildContext context,
    required ColorScheme scheme,
    required ZoneType value,
    required String label,
    required IconData icon,
  }) {
    final selected = _type == value;
    final activeColor = value == ZoneType.danger
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);
    final textStyle = _zoneTypeSelectionTextStyle(context).copyWith(
      color: selected ? Colors.white : scheme.onSurface,
    );

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_type == value) return;
            setState(() => _type = value);
            _recalcOverlapMeters();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? activeColor : locationPanelBorderColor(scheme),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : activeColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneTypeSelector(
    BuildContext context,
    ColorScheme scheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.zonesTypeFieldLabel,
          style: Theme.of(context).appTypography.sectionLabel.copyWith(
            fontFamily: 'Poppins',
            color: scheme.onSurface.withOpacity(0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: locationPanelMutedColor(scheme),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: locationPanelBorderColor(scheme)),
          ),
          child: Row(
            children: [
              _buildZoneTypeOption(
                context: context,
                scheme: scheme,
                value: ZoneType.safe,
                label: l10n.zonesTypeSafe,
                icon: Icons.shield_outlined,
              ),
              const SizedBox(width: 8),
              _buildZoneTypeOption(
                context: context,
                scheme: scheme,
                value: ZoneType.danger,
                label: l10n.zonesTypeDanger,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Uint8List? _safeIcon;
  Uint8List? _dangerIcon;

  DateTime _lastCamTick = DateTime.fromMillisecondsSinceEpoch(0);
  bool _camSyncing = false;
  bool _didInitialFocus = false;
  bool _didInitLocalizedName = false;

  static const double _minRadiusM = 20;
  static const double _maxRadiusM = 5000;

  static const double _minRadiusPx = 52;
  static const double _defaultRadiusPx = 58;

  static const double _handleSize = 36;
  static const double _ringStroke = 2.5;
  static const double _screenPadding = 14;

  double _radiusPxFixed = _defaultRadiusPx;

  bool get _isEditing => widget.zone != null;

  @override
  void initState() {
    super.initState();
    final z = widget.zone;

    _type = z?.type ?? ZoneType.safe;
    _radiusM = (z?.radiusM ?? 200).clamp(_minRadiusM, _maxRadiusM);
    _name = z?.name ?? '';
    _nameCtrl = TextEditingController(text: _name);

    if (z != null) {
      _center = mbx.Position(z.lng, z.lat);
      _radiusPxFixed = (_radiusM / 1.0).clamp(_minRadiusPx, 99999);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitLocalizedName) return;
    _didInitLocalizedName = true;

    if (!_isEditing && _nameCtrl.text.trim().isEmpty) {
      final l10n = AppLocalizations.of(context);
      _name = l10n.zonesNewZoneDefaultName;
      _nameCtrl.text = _name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _recalcOverlapMeters() {
    if (_center == null) return;

    final tmp = GeoZone(
      id: widget.zone?.id ?? '_draft',
      name: _name,
      type: _type,
      lat: _center!.lat.toDouble(),
      lng: _center!.lng.toDouble(),
      radiusM: _radiusM,
      enabled: true,
      createdBy: widget.zone?.createdBy ?? '',
      createdAt: widget.zone?.createdAt ?? 0,
      updatedAt: 0,
    );

    final hit = findOverlappingZone(
      candidate: tmp,
      existing: widget.existingZones,
    );

    _isOverlapping = hit != null;
    _overlapWith = hit;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final baseColor = _type == ZoneType.danger ? Colors.red : Colors.green;
    final circleColor = _isOverlapping ? Colors.red : baseColor;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: locationPanelColor(scheme),
        foregroundColor: scheme.onSurface,
        title: Text(
          _isEditing ? l10n.zonesEditTitle : l10n.zonesAddAddressTitle,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final fullW = constraints.maxWidth;
          final fullH = constraints.maxHeight;

          final maxRadiusPx = max(
            12.0,
            min(fullW, fullH) / 2 - _screenPadding - _handleSize / 2,
          );

          final radiusPx = _radiusPxFixed.clamp(_minRadiusPx, maxRadiusPx);
          final avatarSize = (radiusPx * 0.65).clamp(28.0, 44.0);

          return Stack(
            children: [
              Positioned.fill(
                child: mbx.MapWidget(
                  key: const ValueKey('edit-zone-map'),
                  styleUri: 'mapbox://styles/mapbox/satellite-streets-v12',
                  cameraOptions: mbx.CameraOptions(
                    zoom: 15.5,
                    center: mbx.Point(
                      coordinates: _center ?? mbx.Position(105.8342, 21.0278),
                    ),
                  ),
                  mapOptions: mbx.MapOptions(
                    pixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                  onMapCreated: (map) async {
                    _map = map;
                    await hideMapOrnaments(map);
                    _renderer = ZoneMapRenderer(map);
                  },
                  onStyleLoadedListener: (_) async {
                    if (!mounted) return;
                    _styleReady = true;

                    _safeIcon ??= await MarkerIconFactory.makeCircleIcon(
                      icon: Icons.home,
                      bg: scheme.primary,
                      fg: Colors.white,
                      size: avatarSize,
                    );
                    _dangerIcon ??= await MarkerIconFactory.makeCircleIcon(
                      icon: Icons.warning_amber_rounded,
                      bg: const Color(0xFFE53935),
                      fg: Colors.white,
                      size: avatarSize,
                    );
                    if (!mounted) return;

                    final map = _map;
                    final renderer = _renderer ??= map == null
                        ? null
                        : ZoneMapRenderer(map);
                    if (renderer == null) return;

                    await renderer.ensureLayers();
                    final zonesForMap = widget.existingZones
                        .where((z) => z.id != widget.zone?.id)
                        .toList();
                    await renderer.syncZoneCircles(zonesForMap);
                    await renderer.syncZoneIcons(
                      zones: zonesForMap,
                      safeIcon: _safeIcon!,
                      dangerIcon: _dangerIcon!,
                    );
                    if (!mounted) return;

                    if (!_didInitialFocus && _isEditing) {
                      _didInitialFocus = true;
                      final z = widget.zone!;
                      _center = mbx.Position(z.lng, z.lat);
                      _radiusM = z.radiusM.clamp(_minRadiusM, _maxRadiusM);

                      await _map?.flyTo(
                        mbx.CameraOptions(
                          center: mbx.Point(coordinates: _center!),
                          zoom: 15.5,
                        ),
                        mbx.MapAnimationOptions(duration: 600),
                      );

                      await Future.delayed(const Duration(milliseconds: 700));
                      await _syncFromCamera(updateRadiusFromPx: false);
                    } else {
                      await _syncFromCamera(updateRadiusFromPx: !_isEditing);
                    }
                  },
                  onCameraChangeListener: (_) async {
                    if (_draggingHandle) return;

                    final now = DateTime.now();
                    if (now.difference(_lastCamTick).inMilliseconds < 50) {
                      return;
                    }
                    _lastCamTick = now;

                    if (_camSyncing) return;
                    _camSyncing = true;
                    try {
                      await _syncFromCamera(updateRadiusFromPx: !_isEditing);
                    } finally {
                      _camSyncing = false;
                    }
                  },
                  onMapIdleListener: (_) async {
                    if (_draggingHandle) return;
                    await _syncFromCamera(updateRadiusFromPx: false);
                  },
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    key: _overlayKey,
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Center(
                          child: CustomPaint(
                            painter: ZoneCirclePainter(
                              strokeColor: circleColor.withOpacity(0.95),
                              fillColor: circleColor.withOpacity(0.18),
                              strokeWidth: _ringStroke,
                            ),
                            child: SizedBox(
                              width: radiusPx * 2,
                              height: radiusPx * 2,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isOverlapping)
                                const ZoneExclaimBadge()
                              else
                                Icon(
                                  _type == ZoneType.safe
                                      ? Icons.home
                                      : Icons.warning_amber_rounded,
                                  size: avatarSize,
                                  color: baseColor,
                                ),
                              const SizedBox(height: 42),
                            ],
                          ),
                        ),
                        if (_isOverlapping)
                          Center(
                            child: Transform.translate(
                              offset: const Offset(0, -34),
                              child: ZoneWarningPill(
                                text: l10n.zonesOverlapWarningText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(radiusPx, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) => setState(() => _draggingHandle = true),
                      onPanEnd: (_) => setState(() => _draggingHandle = false),
                      onPanCancel: () =>
                          setState(() => _draggingHandle = false),
                      onPanUpdate: (d) => _updateRadiusByDrag(
                        globalPos: d.globalPosition,
                        maxRadiusPx: maxRadiusPx,
                      ),
                      child: const ZoneHandleButton(),
                    ),
                  ),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.26,
                minChildSize: 0.14,
                maxChildSize: 0.60,
                snap: true,
                snapSizes: const [0.14, 0.26, 0.60],
                builder: (context, scrollController) {
                  return Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: locationPanelColor(scheme),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: ConstrainedBox(
                          // ← Thêm wrap này
                          constraints: BoxConstraints(maxWidth: fullW - 52),
                          child: Padding(
                            padding: const EdgeInsets.all(14),

                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 44,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: locationPanelBorderColor(scheme),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                TextField(
                                  decoration: InputDecoration(
                                    labelText: l10n.zonesNameFieldLabel,
                                    filled: true,
                                    fillColor: locationPanelMutedColor(scheme),
                                    border: const OutlineInputBorder(),
                                  ),
                                  controller: _nameCtrl,
                                  onChanged: (v) => _name = v,
                                ),
                                const SizedBox(height: 10),
                                _buildZoneTypeSelector(context, scheme, l10n),
                                /*
                                DropdownButtonFormField<ZoneType>(
                                  value: _type,
                                  isExpanded: true,
                                  style: zoneTypeSelectionTextStyle,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // ← bo góc menu dropdown
                                  menuMaxHeight:
                                      200, // ← tránh menu tràn màn hình
                                  selectedItemBuilder: (context) => [
                                    Text(
                                      l10n.zonesTypeSafe,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: zoneTypeSelectionTextStyle,
                                    ),
                                    Text(
                                      l10n.zonesTypeDanger,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: zoneTypeSelectionTextStyle,
                                    ),
                                  ],
                                  items: [
                                    DropdownMenuItem(
                                      value: ZoneType.safe,
                                      child: Text(
                                        l10n.zonesTypeSafe,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: zoneTypeSelectionTextStyle,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: ZoneType.danger,
                                      child: Text(
                                        l10n.zonesTypeDanger,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: zoneTypeSelectionTextStyle,
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _type = v);
                                    _recalcOverlapMeters();
                                  },
                                  decoration: InputDecoration(
                                    labelText: l10n.zonesTypeFieldLabel,
                                    filled: true,
                                    fillColor: locationPanelMutedColor(scheme),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: locationPanelBorderColor(scheme),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: scheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                                */
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(l10n.zonesRadiusLabel),
                                    const Spacer(),
                                    Text(
                                      '${_radiusM.toStringAsFixed(0)} m',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: _isOverlapping ? 0 : 2,
                                      backgroundColor: _isOverlapping
                                          ? const Color(0xFF9CA3AF)
                                          : baseColor,
                                      disabledBackgroundColor: const Color(
                                        0xFF9CA3AF,
                                      ),
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _isOverlapping
                                        ? null
                                        : _onSavePressed,
                                    child: Text(
                                      l10n.authContinueButton,
                                      style: TextStyle(
                                        fontSize: Theme.of(
                                          context,
                                        ).appTypography.title.fontSize!,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),

                                if (_isOverlapping && _overlapWith != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color.alphaBlend(
                                        Colors.red.withOpacity(0.08),
                                        locationPanelColor(scheme),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Color(0xFFDC2626),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: Theme.of(context)
                                                    .appTypography
                                                    .sectionLabel
                                                    .fontSize!,
                                                height: 1.45,
                                                color: Color(0xFF991B1B),
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: l10n
                                                      .zonesOverlappingPrefix,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: _overlapWith!.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_isOverlapping && _overlapWith != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.zonesOverlappingWith(
                                      _overlapWith!.name,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onSavePressed() async {
    final l10n = AppLocalizations.of(context);
    await _syncFromCamera(updateRadiusFromPx: !_isEditing);
    if (_center == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = widget.zone?.id ?? _randomId();
    final createdAt = widget.zone?.createdAt ?? now;

    final candidate = GeoZone(
      id: id,
      name: _name.trim().isEmpty ? l10n.zonesDefaultNameFallback : _name.trim(),
      type: _type,
      lat: _center!.lat.toDouble(),
      lng: _center!.lng.toDouble(),
      radiusM: _radiusM,
      enabled: true,
      createdBy: widget.zone?.createdBy ?? '',
      createdAt: createdAt,
      updatedAt: now,
    );

    final hit = findOverlappingZone(
      candidate: candidate,
      existing: widget.existingZones,
    );

    if (hit != null) {
      setState(() {
        _isOverlapping = true;
        _overlapWith = hit;
      });
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, candidate);
  }

  Future<void> _syncFromCamera({required bool updateRadiusFromPx}) async {
    if (_map == null || !_styleReady) return;

    final cs = await _map!.getCameraState();
    _center = cs.center.coordinates;

    final zoom = cs.zoom;
    final lat = _center!.lat.toDouble();
    _metersPerPixel = metersPerPixelFromZoomLat(zoom: zoom, lat: lat);

    if (updateRadiusFromPx && !_isEditing) {
      _radiusM = (_radiusPxFixed * _metersPerPixel).clamp(
        _minRadiusM,
        _maxRadiusM,
      );
    }

    if (_isEditing) {
      _radiusPxFixed = (_radiusM / max(0.01, _metersPerPixel)).clamp(
        _minRadiusPx,
        99999,
      );
    }

    _recalcOverlapMeters();

    if (mounted) setState(() {});
  }

  void _updateRadiusByDrag({
    required Offset globalPos,
    required double maxRadiusPx,
  }) {
    final box = _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final local = box.globalToLocal(globalPos);
    final center = Offset(box.size.width / 2, box.size.height / 2);

    final dist = (local - center).distance;
    final newPx = (dist - _handleSize / 2).clamp(_minRadiusPx, maxRadiusPx);

    setState(() {
      _radiusPxFixed = newPx;
      _radiusM = (_radiusPxFixed * _metersPerPixel).clamp(
        _minRadiusM,
        _maxRadiusM,
      );
    });

    _recalcOverlapMeters();
  }

  String _randomId() => DateTime.now().millisecondsSinceEpoch.toString();
}
