import 'package:flutter/material.dart';
import '../controllers/map_overlay_controller.dart';
import '../widgets/map_thumbnail.dart';
import '../models/park.dart';

class MapOverlayLayer extends StatelessWidget {
  final MapOverlayController controller;
  final List<Park> parks;
  final void Function(Park park) onTapPark;

  const MapOverlayLayer({
    super.key,
    required this.controller,
    required this.parks,
    required this.onTapPark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: controller.screenPositions.entries.map((entry) {
        final parkName = entry.key;
        final pos = entry.value;
        final park = parks.firstWhere((p) => p.name == parkName);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 🖼️ Thumbnail (on top)
            Positioned(
              left: pos.dx - 55,
              top: pos.dy - 20,
              child: MapThumbnail(park: park, onTap: () => onTapPark(park)),
            ),

            // 🔴 Red dot (underneath)
            /* Positioned(
              left: pos.dx - 4,
              top: pos.dy - 4,
              child: const SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ), */
          ],
        );
      }).toList(),
    );
  }
}
