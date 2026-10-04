import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';

final poiSelectionProvider =
    NotifierProvider<PoiSelectionNotifier, List<PointOfInterest>>(
      PoiSelectionNotifier.new,
    );

class PoiSelectionNotifier extends Notifier<List<PointOfInterest>> {
  @override
  List<PointOfInterest> build() => [];

  void toggle(PointOfInterest poi) {
    if (state.any((p) => p.id == poi.id)) {
      state = state.where((p) => p.id != poi.id).toList();
    } else {
      state = [...state, poi];
    }
  }

  void setAll(List<PointOfInterest> pois) {
    state = [...pois];
  }

  void addMany(List<PointOfInterest> pois) {
    state = [...state, ...pois];
  }

  void clear() {
    state = [];
  }

  bool isSelected(String poiId) => state.any((p) => p.id == poiId);

  bool get selectionMode => state.isNotEmpty;
}
