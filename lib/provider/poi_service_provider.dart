import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/services/poi_service.dart';

final poiServiceProvider = Provider<PoiService>((ref) {
  final repo = ref.read(poiRepositoryProvider);
  return PoiService(repo);
});
