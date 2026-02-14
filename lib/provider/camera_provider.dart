import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/camera_notifier.dart';
import '../state/camera_state.dart';

final cameraProvider = NotifierProvider<CameraNotifier, CameraState>(() {
  return CameraNotifier();
});
