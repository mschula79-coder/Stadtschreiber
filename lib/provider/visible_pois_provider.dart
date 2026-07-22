import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_display_modes.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/manual_pois_provider.dart';
import 'package:stadtschreiber/provider/poi_display_mode_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_top10_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';

final visiblePoisProvider = FutureProvider<List<PointOfInterest>>((ref) async {
  final repo = ref.watch(poiRepositoryProvider);
  final mode = ref.watch(poiDisplayModeProvider);
  final top10 = ref.watch(top10StateProvider);

  final selectedCategories = ref
      .watch(categoriesSelectionProvider)
      .selectedValues;
  final searchSelection = ref.watch(searchSelectionProvider);
  final selectedPoi = ref.watch(selectedPoiProvider);

  // 1) Suchauswahl hat Vorrang
  if (searchSelection.isNotEmpty) {
    return searchSelection;
  }

  // ⭐ 2) Top‑10 Modus
  if (mode == PoiDisplayMode.top10) {
    if (top10.category == null || top10.criterion == null) {
      return [];
    }

    return repo.loadTopNPois(
      categoryId: top10.category!.id,
      criterionId: top10.criterion!.id,
      limit: top10.listLength,
    );
  }

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
