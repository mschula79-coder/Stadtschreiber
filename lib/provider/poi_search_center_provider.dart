import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_search_center.dart';

final poiSearchCenterProvider =
    NotifierProvider<
      PoiSearchCenterNotifier,
      PoiSearchCenter?
    >(
      PoiSearchCenterNotifier.new,
    );

class PoiSearchCenterNotifier
    extends Notifier<PoiSearchCenter?> {
  @override
  PoiSearchCenter? build() {
    return null;
  }

  void setCenter({
    required double lat,
    required double lon,
  }) {
    state = PoiSearchCenter(
      lat: lat,
      lon: lon,
    );
  }

  void clear() {
    state = null;
  }
}