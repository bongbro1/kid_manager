import 'package:flutter/material.dart';
import 'package:kid_manager/core/enums/enums.dart';
import 'package:kid_manager/features/presentation/shared/state/mapbox_controller.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

class AppMapView extends StatefulWidget {
  final Function(MapboxMap) onMapCreated;
  final Function()? onStyleLoaded;

  const AppMapView({
    super.key,
    required this.onMapCreated,
    this.onStyleLoaded,
  });


  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  MapboxMap? _map;
  AppMapType _type = AppMapType.street;
  bool _initialCameraSet = false;

  String get _styleUri {
    switch (_type) {
      case AppMapType.street:
        return Theme.of(context).brightness == Brightness.dark
            ? "mapbox://styles/mapbox/dark-v11"
            : "mapbox://styles/mapbox/streets-v12";
      case AppMapType.satellite:
        return "mapbox://styles/mapbox/satellite-streets-v12";
      case AppMapType.terrain:
        return "mapbox://styles/mapbox/outdoors-v12";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: ValueKey(_styleUri),
          styleUri: _styleUri,

          /// ❌ BỎ cameraOptions đi
          /// KHÔNG set camera mặc định mỗi rebuild

          onMapCreated: (map) async {
            _map = map;

            if (!_initialCameraSet) {
              _initialCameraSet = true;
              await map.setCamera(
                CameraOptions(
                  center: Point(
                    coordinates: Position(105.8542, 21.0285),
                  ),
                  zoom: 13,
                ),
              );
            }

            widget.onMapCreated(map); // 👈 để cha xử lý attach
          },
        ),

        Positioned(
          right: 16,
          bottom: 120,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _showMapSelector,
            child: const Icon(Icons.layers, color: Colors.black),
          ),
        ),
      ],
    );
  }

  void _showMapSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile("Street", AppMapType.street),
          _tile("Satellite", AppMapType.satellite),
          _tile("Terrain", AppMapType.terrain),
        ],
      ),
    );
  }

  Widget _tile(String title, AppMapType type) {
    return ListTile(
      title: Text(title),
      trailing: _type == type
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: () {
        setState(() => _type = type);
        Navigator.pop(context);
      },
    );
  }
}