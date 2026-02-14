import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'camera_state.dart';

class CameraNotifier extends Notifier<CameraState> {
  @override
  CameraState build() {
    return const CameraState(lat: 0, lon: 0, zoom: 14);
  }

  void update(double lat, double lon, double zoom) {
    state = CameraState(lat: lat, lon: lon, zoom: zoom);
  }
}
