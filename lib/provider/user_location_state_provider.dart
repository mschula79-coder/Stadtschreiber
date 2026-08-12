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

final userLocationStateProvider =
    NotifierProvider<UserLocationStateNotifier, geo.Position?>(
  UserLocationStateNotifier.new,
);

class UserLocationStateNotifier extends Notifier<geo.Position?> {
  @override
  geo.Position? build() {
    ref.listen<AsyncValue<geo.Position>>(userLocationProvider, (_, next) {
      next.whenData((pos) => state = pos);
    });
    return null;
  }
}
