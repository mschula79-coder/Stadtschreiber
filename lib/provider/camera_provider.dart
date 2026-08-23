import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';
import '../state/camera_notifier.dart';
import '../state/camera_state.dart';

final cameraProvider = NotifierProvider<CameraNotifier, CameraState>(() {
  return CameraNotifier();
});

final cameraPositionPanelCorrectedProvider = Provider<Geographic>((ref) {
  final selectedPoi = ref.watch(selectedPoiProvider);
  final appState = ref.watch(appStateProvider);
  final camera = ref.watch(cameraProvider);

  final panelHeight = appState.panelHeight;
  final showPoiList = appState.isPoiListVisible;

  // Sichtbare Panelhöhe bestimmen
  double visiblePanelHeight;

  if (selectedPoi != null) {
    visiblePanelHeight = panelHeight;
  } else if (showPoiList) {
    // Nur Liste sichtbar → Liste ist 45px kleiner
    visiblePanelHeight = panelHeight - 45;
  } else {
    // Kein Panel sichtbar
    visiblePanelHeight = 0;
  }

  // Pixel-Offset nach oben (Panel nimmt unten Platz weg)
  final pixelOffsetY = visiblePanelHeight / 4;

  // Pixel → Meter
  final metersPerPx = metersPerPixel(camera.lat, camera.zoom);
  final dyMeters = pixelOffsetY * metersPerPx;

  // Meter → Grad (Lat)
  final correctedLat = camera.lat + metersToLat(dyMeters);

  // Longitude bleibt gleich
  final correctedLon = camera.lon;

  return Geographic(lon: correctedLon, lat: correctedLat);
});
