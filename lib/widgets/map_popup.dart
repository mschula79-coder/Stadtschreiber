import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:stadtschreiber/repositories/poi_repository.dart';

class MapPopup {
  static void show({
    required BuildContext context,
    required bool isAdmin,
    required int poiId,
    required String name,
    required String history,
    required LatLng coords,
    String featuredImageUrl = "",
  }) {
    final historyController = TextEditingController(text: history);
    final imageController = TextEditingController(text: featuredImageUrl);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (featuredImageUrl.isNotEmpty)
                Image.network(
                  featuredImageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: historyController,
                enabled: isAdmin,
                maxLines: 10,
                decoration: const InputDecoration(labelText: "Geschichte"),
              ),
              const SizedBox(height: 16),
              Text(
                "Location: ${coords.latitude}, ${coords.longitude}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (isAdmin)
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await PoiRepository.updatePoi(
                      poiId,
                      historyController.text,
                      imageController.text,
                    );
                    navigator.pop();
                  },
                  child: const Text("Speichern"),
                ),
            ],
          ),
        );
      },
    );
  }

// TODO Ersetze MapPopup.show(...) durch: 
}
/* showDialog(
  context: context,
  builder: (_) => Dialog(
    child: MapPopupTabs(
      name: poi.name,
      history: poi.history ?? "",
      coords: poi.location,
      featuredImageUrl: poi.photoUrl ?? "",
      isAdmin: isAdmin,
      poiId: poi.id,
    ),
  ),
); */
