import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poi.dart';

final selectedPoiProvider =
    NotifierProvider<SelectedPoiNotifier, PointOfInterest?>(
      SelectedPoiNotifier.new,
      name: 'selectedPoiProvider'
    );

class SelectedPoiNotifier extends Notifier<PointOfInterest?> {
  @override
  PointOfInterest? build() => null; // initial: kein POI ausgewählt

  void setPoi(PointOfInterest poi) {
    state = poi;
  }

  void updatePoi(PointOfInterest poi) {
    state = poi;
  }

  void clear() {
    state = null;
  }
}
