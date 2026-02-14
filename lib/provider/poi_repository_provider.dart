import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/poi_repository.dart';
import '../controllers/poi_controller.dart';

final poiRepositoryProvider = Provider<PoiRepository>((ref) {
  return PoiRepository();
});

final poiControllerProvider = Provider<PoiController>((ref) {
  final repo = ref.watch(poiRepositoryProvider);
  return PoiController(repo);
});
