import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';

final manualPoisProvider =
    NotifierProvider<ManualPoisNotifier, List<PointOfInterest>>(
  ManualPoisNotifier.new,
);

class ManualPoisNotifier extends Notifier<List<PointOfInterest>> {
  @override
  List<PointOfInterest> build() => [];

  void setPois(List<PointOfInterest> pois) {
    state = pois;
  }

  void clear() {
    state = [];
  }
}