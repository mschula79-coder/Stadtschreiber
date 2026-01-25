import 'package:flutter/material.dart';
import '../controllers/map_poi_overlay_controller.dart';
import '../widgets/poi_thumbnail.dart';
import '../models/poi.dart';

class MapPoiOverlayLayer extends StatelessWidget {
  final MapPoiOverlayController controller;
  final List<PointOfInterest> visiblePOIs;
  final void Function(PointOfInterest poi) onTapPoi;

  const MapPoiOverlayLayer({
    super.key,
    required this.controller,
    required this.visiblePOIs,
    required this.onTapPoi,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: controller.screenPositions.entries.map((entry) {
        final poiId = entry.key;  
        final pos = entry.value;
        final PointOfInterest poi = visiblePOIs.firstWhere((p) => p.id == poiId);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 🖼️ Thumbnail (on top)
            Positioned(
              left: pos.dx - 55,
              top: pos.dy - 20,
              child: PoiThumbnail(poi: poi, onTap: () => onTapPoi(poi)),
              
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
