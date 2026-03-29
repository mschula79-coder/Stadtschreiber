import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';

final visiblePoisProvider = FutureProvider<List<PointOfInterest>>((ref) async {
  final repo = ref.watch(poiRepositoryProvider);
  final selectedCategories = ref.watch(categoriesSelectionProvider).selectedValues;
  final searchSelection = ref.watch(searchSelectionProvider);

  // 1) Suchauswahl hat Vorrang
  if (searchSelection.isNotEmpty) {
    return searchSelection;
  }

  // 2) Kategorienfilter → POIs vom Server laden
  return await repo.loadPoisforSelectedCategories(selectedCategories);
});


