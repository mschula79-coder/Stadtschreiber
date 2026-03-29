import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class PoiMarkerPositions {
  final List<PoiMarkerPosition> poiMarkerPositions;

  const PoiMarkerPositions({
    required this.poiMarkerPositions,
  });
}

class PoiMarkerPosition {
  final String poiId;
  final Geographic location;
  final Offset screenPosition;

  const PoiMarkerPosition({
    required this.poiId,
    required this.location,
    required this.screenPosition,
  });
}
