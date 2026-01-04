import '../models/park.dart';
import '../services/debug_service.dart';

class PoiRepository {
  final List<Map<String, String>> _parkMetadata = [
    {
      "name": "Schützenmattpark",
      "photoUrl":
          "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
    },
    {
      "name": "Kannenfeldpark",
      "photoUrl":
          "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
    },
    {
      "name": "Erlenmattpark",
      "photoUrl":
          "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
    },
  ];

  Future<List<Park>> loadParksFromGeojson(Map<String, dynamic> geojson) async {
    final features = geojson['features'] as List;

    return features.map((feature) {
      final props = feature['properties'] as Map<String, dynamic>?;

      final name = props?['name']?.toString() ?? '';

      if (name.isEmpty) {
        DebugService.log("⚠️ Feature without a valid name: $feature");
      }

      final meta = _parkMetadata.firstWhere(
        (m) => m['name'] == name,
        orElse: () {
          DebugService.log("⚠️ No metadata found for park: $name");
          return {"name": name, "photoUrl": ""};
        },
      );

      return Park.fromFeature(
        feature as Map<String, dynamic>,
        photoUrl: meta["photoUrl"] ?? "",
      );
    }).toList();
  }
}
