import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchRadiusKmProvider =
    NotifierProvider<SearchRadiusKmNotifier, double>(
      SearchRadiusKmNotifier.new,
    );

class SearchRadiusKmNotifier extends Notifier<double> {
  @override
  double build() {
    return 2;
  }

  void setRadius(double radiusKm) {
    state = radiusKm.clamp(
      0.5,
      20,
    ).toDouble();
  }
}