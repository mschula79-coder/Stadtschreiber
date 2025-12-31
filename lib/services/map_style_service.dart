import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapStyleService {
  Future<void> loadImages(MapLibreMapController controller) async {
    await _addImage(controller, 'park-icon', 'assets/icon_nature_people.png');
    await _addImage(
      controller,
      'playground-icon',
      'assets/icon_playground.png',
    );
    await _addImage(controller, 'forest-icon', 'assets/icon_forest.png');
  }

  Future<void> _addImage(
    MapLibreMapController controller,
    String name,
    String assetPath,
  ) async {
    final bytes = await rootBundle.load(assetPath);
    await controller.addImage(name, bytes.buffer.asUint8List());
  }
}
