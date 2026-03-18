import 'package:flutter/material.dart';

class PoiMarkerPositionStateData {
  final Map<String, Offset> positions;
  final double zoom;

  const PoiMarkerPositionStateData({
    required this.positions,
    required this.zoom,
  });

  PoiMarkerPositionStateData copyWith({
    Map<String, Offset>? positions,
    double? zoom,
  }) {
    return PoiMarkerPositionStateData(
      positions: positions ?? this.positions,
      zoom: zoom ?? this.zoom,
    );
  }

  static const initial = PoiMarkerPositionStateData(
    positions: {},
    zoom: 14.0,
  );
}
