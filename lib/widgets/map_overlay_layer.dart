import 'package:flutter/material.dart';
import '../controllers/map_overlay_controller.dart';
import '../widgets/map_thumbnail.dart';
import '../models/poi.dart';

class MapOverlayLayer extends StatelessWidget {
  final MapOverlayController controller;
  final List<PointOfInterest> visiblePOIs;
  final void Function(PointOfInterest poi) onTapPoi;

  const MapOverlayLayer({
    super.key,
    required this.controller,
    required this.visiblePOIs,
    required this.onTapPoi,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: controller.screenPositions.entries.map((entry) {
        final poiName = entry.key;
        final pos = entry.value;
        final PointOfInterest poi = visiblePOIs.firstWhere((p) => p.name == poiName);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 🖼️ Thumbnail (on top)
            Positioned(
              left: pos.dx - 55,
              top: pos.dy - 20,
              child: MapThumbnail(poi: poi, onTap: () => onTapPoi(poi)),
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
