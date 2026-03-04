import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/zone/zone_circle.dart';
import 'package:kid_manager/helpers/zone/zone_overlap.dart';
import 'package:kid_manager/widgets/map/marker_icon_factory.dart';
import 'package:kid_manager/widgets/map/zone_map_renderer.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

import 'package:kid_manager/models/zones/geo_zone.dart';


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

  Timer? _camDebounce;

  Uint8List? _safeIcon;
  Uint8List? _dangerIcon;

  static const double _minRadiusM = 20;
  static const double _maxRadiusM = 5000;
  static const double _handleSize = 36;
  static const double _ringStroke = 2.5;
  static const double _screenPadding = 14;
  static const double _overlapBufferM = 5;

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    _type = z?.type ?? ZoneType.safe;
    _radiusM = (z?.radiusM ?? 200).clamp(_minRadiusM, _maxRadiusM);
    _name = z?.name ?? "Vùng mới";
    _nameCtrl = TextEditingController(text: _name);
    if (z != null) _center = mbx.Position(z.lng, z.lat);
  }

  @override
  void dispose() {
    _camDebounce?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _type == ZoneType.danger ? Colors.red : Colors.green;
    final circleColor = _isOverlapping ? Colors.red : baseColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Địa chỉ của địa điểm"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final fullW = constraints.maxWidth;
          final fullH = constraints.maxHeight;

          // Overlay max radius theo vùng map đang hiển thị (lấy gần đúng cho đẹp)
          final mapW = fullW;
          final mapH = fullH; // do sheet kéo, mình cho max theo fullH để đơn giản/mượt

          final maxRadiusPx = max(
            12.0,
            min(mapW, mapH) / 2 - _screenPadding - _handleSize / 2,
          );

          final radiusPx =
          (_radiusM / max(0.01, _metersPerPixel)).clamp(6.0, maxRadiusPx);

          return Stack(
            children: [
              // MAP
              Positioned.fill(
                child: mbx.MapWidget(
                  key: const ValueKey("edit-zone-map"),
                  styleUri: "mapbox://styles/mapbox/satellite-streets-v12",
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
                    _renderer = ZoneMapRenderer(map);
                  },
                  onStyleLoadedListener: (_) async {
                    _styleReady = true;

                    // icon bytes
                    _safeIcon ??= await MarkerIconFactory.makeCircleIcon(
                      icon: Icons.home,
                      bg: const Color(0xFF1E88E5),
                      fg: Colors.white,
                      size: 48,
                    );
                    _dangerIcon ??= await MarkerIconFactory.makeCircleIcon(
                      icon: Icons.warning_amber_rounded,
                      bg: const Color(0xFFE53935),
                      fg: Colors.white,
                      size: 48,
                    );

                    // map circles + icons for all zones
                    await _renderer!.ensureLayers();
                    await _renderer!.syncZoneCircles(widget.existingZones);
                    await _renderer!.syncZoneIcons(
                      zones: widget.existingZones,
                      safeIcon: _safeIcon!,
                      dangerIcon: _dangerIcon!,
                    );

                    await _syncFromCamera();
                  },

                  onCameraChangeListener: (_) {
                    if (_draggingHandle) return;
                    _camDebounce?.cancel();
                    _camDebounce = Timer(const Duration(milliseconds: 50), () async {
                      await _syncFromCamera();
                    });
                  },
                  onMapIdleListener: (_) async {
                    if (_draggingHandle) return;
                    await _syncFromCamera();
                  },
                ),
              ),

              // OVERLAY (circle + icon + warning)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    key: _overlayKey,
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        Center(
                          child: CustomPaint(
                            painter: _ZoneCirclePainter(
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

                        // center icon + warning
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isOverlapping)
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    "!",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  _type == ZoneType.safe ? Icons.home : Icons.warning_amber_rounded,
                                  size: 42,
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
                              child: _WarningPill(
                                text: "Các địa điểm không nên chồng chéo",
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // HANDLE drag radius
              Positioned.fill(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(radiusPx, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) => setState(() => _draggingHandle = true),
                      onPanEnd: (_) => setState(() => _draggingHandle = false),
                      onPanCancel: () => setState(() => _draggingHandle = false),
                      onPanUpdate: (d) => _updateRadiusByDrag(
                        globalPos: d.globalPosition,
                        maxRadiusPx: maxRadiusPx,
                      ),
                      child: const _HandleButton(),
                    ),
                  ),
                ),
              ),

              // DRAGGABLE bottom sheet (giữ UI cũ)
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x16000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SingleChildScrollView(
                        controller: scrollController,
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
                                  color: const Color(0x22000000),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),

                              TextField(
                                decoration: const InputDecoration(
                                  labelText: "Tên vùng",
                                  border: OutlineInputBorder(),
                                ),
                                controller: _nameCtrl,
                                onChanged: (v) => _name = v,
                              ),
                              const SizedBox(height: 10),

                              DropdownButtonFormField<ZoneType>(
                                value: _type,
                                items: const [
                                  DropdownMenuItem(value: ZoneType.safe, child: Text("Vùng an toàn")),
                                  DropdownMenuItem(value: ZoneType.danger, child: Text("Vùng nguy hiểm")),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _type = v);
                                  _recalcOverlap();
                                },
                                decoration: const InputDecoration(
                                  labelText: "Loại vùng",
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text("Bán kính"),
                                  const Spacer(),
                                  Text(
                                    "${_radiusM.toStringAsFixed(0)} m",
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isOverlapping
                                        ? Colors.grey.shade600
                                        : baseColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _isOverlapping ? null : _onSavePressed,
                                  child: const Text(
                                    "Tiếp tục",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),

                              if (_isOverlapping && _overlapWith != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  "Đang chồng lên: ${_overlapWith!.name}",
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
    await _syncFromCamera();
    if (_center == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = widget.zone?.id ?? _randomId();
    final createdAt = widget.zone?.createdAt ?? now;

    final candidate = GeoZone(
      id: id,
      name: _name.trim().isEmpty ? "Vùng" : _name.trim(),
      type: _type,
      lat: _center!.lat.toDouble(),
      lng: _center!.lng.toDouble(),
      radiusM: _radiusM,
      enabled: true,
      createdBy: widget.zone?.createdBy ?? "", // VM sẽ set nếu rỗng
      createdAt: createdAt,
      updatedAt: now,
    );

    final hit = findOverlappingZone(
      candidate: candidate,
      existing: widget.existingZones,
      bufferM: _overlapBufferM,
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

  Future<void> _syncFromCamera() async {
    if (_map == null || !_styleReady) return;

    final cs = await _map!.getCameraState();
    _center = cs.center.coordinates;

    final zoom = cs.zoom;
    final lat = _center!.lat.toDouble();
    _metersPerPixel = metersPerPixelFromZoomLat(zoom: zoom, lat: lat);

    _radiusM = _radiusM.clamp(_minRadiusM, _maxRadiusM);
    _recalcOverlap();
    if (mounted) setState(() {});
  }

  void _recalcOverlap() {
    if (_center == null) return;

    final tmp = GeoZone(
      id: widget.zone?.id ?? "_draft",
      name: _name,
      type: _type,
      lat: _center!.lat.toDouble(),
      lng: _center!.lng.toDouble(),
      radiusM: _radiusM,
      enabled: true,
      createdBy: widget.zone?.createdBy ?? "",
      createdAt: widget.zone?.createdAt ?? 0,
      updatedAt: 0,
    );

    final hit = findOverlappingZone(
      candidate: tmp,
      existing: widget.existingZones,
      bufferM: _overlapBufferM,
    );

    _isOverlapping = hit != null;
    _overlapWith = hit;
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
    final radiusPx = (dist - _handleSize / 2).clamp(0.0, maxRadiusPx);

    final meters = (radiusPx * max(0.01, _metersPerPixel))
        .clamp(_minRadiusM, _maxRadiusM);

    setState(() => _radiusM = meters);
    _recalcOverlap();
  }

  String _randomId() => DateTime.now().millisecondsSinceEpoch.toString();
}

class _ZoneCirclePainter extends CustomPainter {
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;

  _ZoneCirclePainter({
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;

    final fill = Paint()..color = fillColor..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(c, r, fill);
    canvas.drawCircle(c, r, stroke);
  }

  @override
  bool shouldRepaint(covariant _ZoneCirclePainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
          oldDelegate.fillColor != fillColor ||
          oldDelegate.strokeWidth != strokeWidth;
}

class _HandleButton extends StatelessWidget {
  const _HandleButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: const Center(
        child: Icon(Icons.edit, size: 18, color: Colors.white),
      ),
    );
  }
}

class _WarningPill extends StatelessWidget {
  final String text;
  const _WarningPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}