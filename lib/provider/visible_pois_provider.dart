import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_display_modes.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/manual_pois_provider.dart';
import 'package:stadtschreiber/provider/poi_display_mode_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';

final visiblePoisProvider = FutureProvider<List<PointOfInterest>>((ref) async {
  final repo = ref.watch(poiRepositoryProvider);
  final mode = ref.watch(poiDisplayModeProvider);

  final selectedCategories = ref
      .watch(categoriesSelectionProvider)
      .selectedValues;
  /*   final searchSelection = ref.watch(searchSelectionProvider);
 */
  final selectedPoi = ref.watch(selectedPoiProvider);

  // 1) Suchauswahl hat Vorrang
  /*  if (searchSelection.isNotEmpty) {
    return searchSelection;
  } */

  if (mode == PoiDisplayMode.manual) {
    return ref.watch(manualPoisProvider);
  }

  // ⭐ 3) Deine bestehende Kategorien‑Logik
  final catPois = await repo.loadPoisforSelectedCategories(selectedCategories);

  if (selectedPoi == null) return catPois;

  final index = catPois.indexWhere((p) => p.id == selectedPoi.id);

  if (index == -1) {
    return [...catPois, selectedPoi];
  }

  final updated = [...catPois];
  updated[index] = selectedPoi;
  return updated;
});

final sortedVisiblePoisProvider = Provider<List<PointOfInterest>>((ref) {
  final poisAsync = ref.watch(visiblePoisProvider);
  final correctedCamera = ref.watch(cameraPositionPanelCorrectedProvider);

  return poisAsync.when(
    data: (pois) {
      final sorted = [...pois];

      sorted.sort((a, b) {
        final da = geoDistanceMeters(
          Geographic(lon: a.location.lon, lat: a.location.lat),
          correctedCamera,
        );

        final db = geoDistanceMeters(
          Geographic(lon: b.location.lon, lat: b.location.lat),
          correctedCamera,
        );

        return da.compareTo(db);
      });

      return sorted;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
