import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/provider/map_controller_provider.dart';
import 'package:stadtschreiber/provider/user_location_provider.dart';

final autoLocateProvider = Provider<void>((ref) {
  final posAsync = ref.watch(userLocationProvider);

  posAsync.whenData((pos) {
    final controller = ref.read(mapControllerProvider);
    if (controller == null) return;

    controller.moveCamera(
      center: Geographic(
        lat: pos.latitude,
        lon: pos.longitude,
      ),
      zoom: 16.0,
    );
  });
});
