import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/district.dart';

class DistrictsRepository {
  final supabase = Supabase.instance.client;

  Future<List<District>> loadDistricts() async {
    final response = await supabase
        .from('districts')
        .select('id, name, geom'); // geom = GeoJSON

    return (response as List).map((row) => District.fromJson(row)).toList();
  }
}
