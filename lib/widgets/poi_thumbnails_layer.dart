import 'package:flutter/material.dart';
import '../controllers/poi_thumbnails_controller.dart';
import '../widgets/poi_thumbnail.dart';
import '../models/poi.dart';

class PoiThumbnailsLayer extends StatelessWidget {
  final PoiThumbnailsController controller;
  final List<PointOfInterest> visiblePOIs;
  final void Function(PointOfInterest poi) onTapPoi;

  const PoiThumbnailsLayer({
    super.key,
    required this.controller,
    required this.visiblePOIs,
    required this.onTapPoi,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: controller.screenPositions.entries.map((entry) {
        final poiId = entry.key;
        final pos = entry.value;
        final poi = visiblePOIs.firstWhere((p) => p.id == poiId);

        return Positioned(
          left: pos.dx - 55,
          top: pos.dy - 20,
          child: PoiThumbnail(poi: poi, onTap: () => onTapPoi(poi)),
        );
      }).toList(),
    );
  }
}

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
