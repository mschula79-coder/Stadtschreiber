import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_marker_positions.dart';

PoiMarkerPositions calculatePoiMarkerPositions({
  required List<PointOfInterest> visiblePois,
  required MapController controller,
}) {
  final positions = visiblePois.map((poi) {
    final screen = controller.toScreenLocation(
      Geographic(
        lat: poi.location.lat,
        lon: poi.location.lon,
      ),
    );

    return PoiMarkerPosition(
      poiId: poi.id,
      location: poi.location,
      screenPosition: Offset(screen.dx, screen.dy),
    );
  }).toList();

  return PoiMarkerPositions(poiMarkerPositions: positions);
}
