import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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

  late ZoneType _type;
  late double _radiusM;
  late String _name;

  bool _styleReady = false;
  mbx.Position? _center; // camera center

  // meters per pixel from zoom+lat
  double _metersPerPixel = 1;

  // overlay / handle drag
  final GlobalKey _overlayKey = GlobalKey();
  bool _draggingHandle = false;

  // overlap state (để đổi UI như hình)
  bool _isOverlapping = false;
  GeoZone? _overlapWith;

  // debounce camera updates
  Timer? _camDebounce;

  // Mapbox markers for existing zones
  mbx.PointAnnotationManager? _annoMgr;
  Uint8List? _homeIconBytes;
  Uint8List? _warnIconBytes;

  // constants
  static const double _minRadiusM = 20; // đồng bộ backend (20..5000)
  static const double _maxRadiusM = 5000;
  static const double _handleSize = 36;
  static const double _ringStroke = 2.5;
  static const double _screenPadding = 14;
  static const double _overlapBufferM = 5; // khoảng cách an toàn thêm

  @override
  void initState() {
    super.initState();
    final z = widget.zone;
    _type = z?.type ?? ZoneType.safe;
    _radiusM = (z?.radiusM ?? 200).clamp(_minRadiusM, _maxRadiusM);
    _name = z?.name ?? "Vùng mới";
    if (z != null) _center = mbx.Position(z.lng, z.lat);
  }

  @override
  void dispose() {
    _camDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _type == ZoneType.danger ? Colors.red : Colors.green;

    // Khi overlap => UI luôn đỏ (giống hình)
    final circleColor = _isOverlapping ? Colors.red : baseColor;

    // Bottom sheet height (ước lượng). Nếu UI khác, chỉnh con số này.
    const bottomSheetApproxH = 260.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Địa chỉ của địa điểm"),
        actions: [
          if (widget.zone != null)
            IconButton(
              onPressed: () {
                // tuỳ bạn: pop signal để xoá
                Navigator.pop(context, "__DELETE__");
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final fullW = constraints.maxWidth;
          final fullH = constraints.maxHeight;

          final mapH = max(200.0, fullH - bottomSheetApproxH);
          final mapW = fullW;

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
                  },
                  onStyleLoadedListener: (_) async {
                    _styleReady = true;
                    await _prepareMarkerIcons();
                    await _setupExistingZoneMarkers();
                    await _syncFromCamera(); // set _center + mpp + overlap
                  },

                  onCameraChangeListener: (_) {
                    if (_draggingHandle) return;
                    _camDebounce?.cancel();
                    _camDebounce =
                        Timer(const Duration(milliseconds: 50), () async {
                          await _syncFromCamera();
                        });
                  },
                  onMapIdleListener: (_) async {
                    if (_draggingHandle) return;
                    await _syncFromCamera();
                  },
                ),
              ),

              // OVERLAY (circle + center icons) - ignore pointer để map pan/zoom bình thường
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: mapH,
                child: IgnorePointer(
                  child: Container(
                    key: _overlayKey,
                    color: Colors.transparent,
                    child: Stack(
                      children: [
                        // circle
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

                        // center icon: nếu overlap => "!" đỏ, else pin màu theo type
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
                                Icon(Icons.location_on, size: 42, color: baseColor),
                              const SizedBox(height: 42),
                            ],
                          ),
                        ),

                        // bubble warning như hình
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

              // HANDLE (chỉ cái nút này bắt drag)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: mapH,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(radiusPx, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) => setState(() => _draggingHandle = true),
                      onPanEnd: (_) => setState(() => _draggingHandle = false),
                      onPanCancel: () => setState(() => _draggingHandle = false),
                      onPanUpdate: (d) {
                        _updateRadiusByDrag(
                          globalPos: d.globalPosition,
                          maxRadiusPx: maxRadiusPx,
                        );
                      },
                      child: _HandleButton(color: Colors.black),
                    ),
                  ),
                ),
              ),

              // BOTTOM actions như ảnh (Lưu + Thay đổi tên)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            _isOverlapping ? Colors.grey.shade600 : Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          onPressed: _isOverlapping
                              ? null
                              : () async {
                            await _syncFromCamera();
                            if (_center == null) return;

                            final now = DateTime.now().millisecondsSinceEpoch;
                            final id = widget.zone?.id ?? _randomId();
                            final createdAt = widget.zone?.createdAt ?? now;

                            final zone = GeoZone(
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

                            // chặn chắc lần cuối
                            final hit = _findOverlap(zone);
                            if (hit != null) {
                              setState(() {
                                _isOverlapping = true;
                                _overlapWith = hit;
                              });
                              return;
                            }

                            Navigator.pop(context, zone);
                          },
                          child: const Text("Lưu",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final v = await _showRenameDialog(context, _name);
                          if (v != null) setState(() => _name = v);
                        },
                        child: const Text(
                          "Thay đổi tên",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // Overlap logic
  // =========================

  GeoZone? _findOverlap(GeoZone candidate) {
    for (final z in widget.existingZones) {
      if (z.id == candidate.id) continue;
      final d = _haversineMeters(candidate.lat, candidate.lng, z.lat, z.lng);
      if (d < (candidate.radiusM + z.radiusM + _overlapBufferM)) return z;
    }
    return null;
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
    final hit = _findOverlap(tmp);
    setState(() {
      _isOverlapping = hit != null;
      _overlapWith = hit;
    });
  }

  // =========================
  // Map sync + meters/px
  // =========================

  double _metersPerPixelFromZoomLat({required double zoom, required double lat}) {
    final mpp = 156543.03392 * cos(lat * pi / 180.0) / pow(2.0, zoom);
    return max(0.01, mpp);
  }

  Future<void> _syncFromCamera() async {
    if (_map == null || !_styleReady) return;
    final cs = await _map!.getCameraState();
    _center = cs.center.coordinates;

    final zoom = cs.zoom;
    final lat = _center!.lat.toDouble();
    _metersPerPixel = _metersPerPixelFromZoomLat(zoom: zoom, lat: lat);

    // clamp radius to max bound
    _radiusM = _radiusM.clamp(_minRadiusM, _maxRadiusM);

    _recalcOverlap();
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

    final meters =
    (radiusPx * max(0.01, _metersPerPixel)).clamp(_minRadiusM, _maxRadiusM);

    setState(() => _radiusM = meters);
    _recalcOverlap();
  }

  // =========================
  // Markers (existing zones)
  // =========================

  Future<void> _prepareMarkerIcons() async {
    _homeIconBytes ??= await _iconToBytes(Icons.home, Colors.white, 48,
        bg: const Color(0xFF1E88E5));
    _warnIconBytes ??= await _iconToBytes(Icons.warning_amber_rounded, Colors.white, 48,
        bg: const Color(0xFFE53935));
  }

  Future<void> _setupExistingZoneMarkers() async {
    if (_map == null) return;

    _annoMgr ??= await _map!.annotations.createPointAnnotationManager();
    await _annoMgr!.deleteAll();

    for (final z in widget.existingZones) {
      final isSafe = z.type == ZoneType.safe;
      final bytes = isSafe ? _homeIconBytes : _warnIconBytes;
      if (bytes == null) continue;

      await _annoMgr!.create(
        mbx.PointAnnotationOptions(
          geometry: mbx.Point(coordinates: mbx.Position(z.lng, z.lat)),
          image: bytes,
          iconSize: 1.0,
        ),
      );
    }
  }

  Future<Uint8List> _iconToBytes(
      IconData icon,
      Color iconColor,
      double size, {
        Color bg = Colors.black,
      }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final r = size / 2;
    final paintBg = Paint()..color = bg;
    canvas.drawCircle(Offset(r, r), r, paintBg);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.62,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
        ),
      ),
    )..layout();

    final dx = r - textPainter.width / 2;
    final dy = r - textPainter.height / 2;
    textPainter.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // =========================
  // helpers
  // =========================

  String _randomId() => DateTime.now().millisecondsSinceEpoch.toString();

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<String?> _showRenameDialog(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đổi tên địa điểm"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nhập tên..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Huỷ")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
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
  final Color color;
  const _HandleButton({required this.color});

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
      child: Center(
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