import 'package:stadtschreiber/models/poi.dart';

abstract class StadtschreiberMapController {
  Future<void> moveTo({
    required double lat,
    required double lon,
    double? zoom,
  });

  Future<void> setZoom(double zoom);

  Future<void> addPoiMarker(PointOfInterest poi);

  Future<void> clearMarkers();
}
