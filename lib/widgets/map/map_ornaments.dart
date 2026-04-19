import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

Future<void> hideMapOrnaments(mbx.MapboxMap map) async {
  try {
    await map.compass.updateSettings(mbx.CompassSettings(enabled: false));
  } catch (e) {
    debugPrint('hide compass failed: $e');
  }

  try {
    await map.scaleBar.updateSettings(mbx.ScaleBarSettings(enabled: false));
  } catch (e) {
    debugPrint('hide scale bar failed: $e');
  }

  try {
    await map.logo.updateSettings(mbx.LogoSettings(enabled: false));
  } catch (e) {
    debugPrint('hide logo failed: $e');
  }

  try {
    await map.attribution.updateSettings(
      mbx.AttributionSettings(enabled: false, clickable: false),
    );
  } catch (e) {
    debugPrint('hide attribution failed: $e');
  }
}
