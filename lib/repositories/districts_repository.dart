import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/district.dart';

class DistrictsRepository {
  final supabase = Supabase.instance.client;

  Future<List<District>> loadDistricts() async {
    final response = await supabase
        .from('districts')
        .select('id, name, geom');

    final districts = <District>[];

    for (final row in response as List) {
      final district = District.fromJson(row);
      districts.add(district);
    }

    return districts;
  }
}
