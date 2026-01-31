import 'package:flutter/material.dart';
import '../controllers/poi_thumbnails_controller.dart';
import '../widgets/poi_pin_marker.dart';
import '../widgets/poi_thumbnail.dart';
import '../models/poi.dart';

class PoiThumbnailsLayer extends StatefulWidget {
  final PoiThumbnailsController controller;
  final List<PointOfInterest> visiblePOIs;
  final void Function(PointOfInterest poi) onTapPoi;
  final double zoom;

  const PoiThumbnailsLayer({
    super.key,
    required this.controller,
    required this.visiblePOIs,
    required this.onTapPoi,
    required this.zoom,
  });

  @override
  State<PoiThumbnailsLayer> createState() => _PoiThumbnailsLayerState();
}

class _PoiThumbnailsLayerState extends State<PoiThumbnailsLayer> {
  final Map<int, Size> poiSizes = {};

  @override
  Widget build(BuildContext context) {
    final showThumbnails = widget.zoom >= 14.0;

    return Stack(
      // Fix overflow issues with thumbnails at the edges
      clipBehavior: Clip.hardEdge,
      children: widget.controller.poiScreenPositions.entries.expand((entry) {
        final poiId = entry.key;
        final pos = entry.value;

        final matching = widget.visiblePOIs.where((p) => p.id == poiId);
        if (matching.isEmpty) {
          return const Iterable<Widget>.empty();
        }
        final poi = matching.first;

        return [
          Positioned(
            left: showThumbnails
                ? poiSizes[poi.id] == null
                      ? pos.dx - 50
                      : pos.dx - poiSizes[poi.id]!.width / 2.5
                : pos.dx - 10,
            top: showThumbnails
                ? pos.dy - 24
                : poiSizes[poi.id] == null
                ? pos.dy - 24
                : pos.dy - poiSizes[poi.id]!.height,
            child: showThumbnails
                ? PoiThumbnail(
                    poi: poi,
                    onTap: () => widget.onTapPoi(poi),
                    onSize: (size) {
                      poiSizes[poi.id] = size;
                    },
                  )
                : PinMarker(
                    poi: poi,
                    onTap: () => widget.onTapPoi(poi),
                    onSize: (size) {
                      poiSizes[poi.id] = size;
                    },
                  ),
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
        ];
      }).toList(),
    );
  }
}
