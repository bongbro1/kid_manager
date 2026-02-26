import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/features/map_engine/map_engine.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';

class ChildDetailMapScreen extends StatefulWidget {
  final String childId;
  const ChildDetailMapScreen({super.key, required this.childId});

  @override
  State<ChildDetailMapScreen> createState() => _ChildDetailMapScreenState();
}

class _ChildDetailMapScreenState extends State<ChildDetailMapScreen> {
  MapEngine? _engine;
  StreamSubscription<LocationData>? _sub;

  List<LocationData> _cachedHistory = const [];
  LocationData? _latest;

  Timer? _renderDebounce;
  DateTime _lastMapMatchAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _sub?.cancel();
    _renderDebounce?.cancel();
    super.dispose();
  }

  String _transportLabel(TransportMode t) {
    switch (t) {
      case TransportMode.walking: return "Đi bộ";
      case TransportMode.bicycle: return "Xe đạp";
      case TransportMode.vehicle: return "Đi xe";
      case TransportMode.still: return "Đứng yên";
      default: return "Không rõ";
    }
  }

  void _appendRealtime(LocationData loc) {
    if (_cachedHistory.isEmpty || _cachedHistory.last.timestamp != loc.timestamp) {
      _cachedHistory = [..._cachedHistory, loc];
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latest;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          latest == null ? "Chi tiết vị trí" : "Trạng thái: ${_transportLabel(latest.transport)}",
        ),
      ),
      body: AppMapView(
        onMapCreated: (_) {},
        onStyleLoaded: (map) async {
          _engine = MapEngine(map);
          await _engine!.init();
          _engine!.resetRouteCache();

          final vm = context.read<ParentLocationVm>();

          // load history ban đầu
          if (_cachedHistory.isEmpty) {
            _cachedHistory = await vm.loadLocationHistory(widget.childId);
          }
          await _engine!.loadHistory(_cachedHistory, context);
          _lastMapMatchAt = DateTime.now();

          // realtime
          await _sub?.cancel();
          _sub = vm.watchChildLocation(widget.childId).listen((loc) {
            _latest = loc;
            _appendRealtime(loc);

            //  update points realtime (mượt, không tốn API)
            _renderDebounce?.cancel();
            _renderDebounce = Timer(const Duration(milliseconds: 300), () async {
              if (!mounted || _engine == null) return;
              await _engine!.renderHistoryFast(_cachedHistory, context); // points-only
            });

            //  route bám đường theo chu kỳ (tốn API nhưng ít)
            final now = DateTime.now();
            if (now.difference(_lastMapMatchAt) >= const Duration(seconds: 20) &&
                _cachedHistory.length >= 6) {
              _lastMapMatchAt = now;
              _engine!.updateMatchedRouteIncremental(_cachedHistory, context);
            }

            if (mounted) setState(() {});
          });        },
      ),
    );
  }
}