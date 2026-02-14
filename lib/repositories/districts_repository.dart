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

      /* await supabase
          .from('districts')
          .update({'lat': district.location.lat, 'lon': district.location.lon})
          .eq('id', district.id); */
    }

    return districts;
  }
}
