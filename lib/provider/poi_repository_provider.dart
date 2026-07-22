import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/poi_repository.dart';

final poiRepositoryProvider = Provider<PoiRepository>((ref) {
  return PoiRepository();
});

final poiByIdProvider = FutureProvider.family<PointOfInterest?, String>((
  ref,
  poiID,
) async {
  final supabase = Supabase.instance.client;

  final result = await supabase
      .from('pois')
      .select()
      .eq('id', poiID)
      .maybeSingle();

  if (result == null) return null;
  return PointOfInterest.fromSupabase(result);
});
