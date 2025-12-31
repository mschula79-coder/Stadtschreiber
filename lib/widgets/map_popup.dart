import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapPopup {
  static void show({
    required BuildContext context,
    required String name,
    required String history,
    required String leisure,
    required LatLng coords,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("Type: $leisure"),
              const SizedBox(height: 8),
              Text(history),
              const SizedBox(height: 16),
              Text(
                "Location: ${coords.latitude}, ${coords.longitude}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
