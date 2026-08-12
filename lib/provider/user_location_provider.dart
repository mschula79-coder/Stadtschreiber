import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;


final userLocationProvider = StreamProvider<geo.Position>((ref) {
  return geo.Geolocator.getPositionStream(
    locationSettings: const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 5,
    ),
  );
});
