import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/poi_repository.dart';

final poiRepositoryProvider = Provider<PoiRepository>((ref) {
  return PoiRepository();
});