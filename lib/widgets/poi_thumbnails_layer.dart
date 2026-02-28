import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/poi_thumbnails_controller.dart';
import '../state/app_state.dart';
import '../models/poi.dart';
import '../services/debug_service.dart';
import '../widgets/poi_pin_marker.dart';
import '../widgets/poi_thumbnail.dart';
import '../widgets/district_thumbnail.dart';

class PoiThumbnailsLayer extends StatefulWidget {
  final PoiThumbnailsController controller;
  final List<PointOfInterest> visiblePOIs;
  final void Function(PointOfInterest poi) onTapPoi;
  final void Function(PointOfInterest poi) onLongPressPoi;
  final double zoom;

  const PoiThumbnailsLayer({
    super.key,
    required this.controller,
    required this.visiblePOIs,
    required this.onTapPoi,
    required this.onLongPressPoi,
    required this.zoom,
  });

  @override
  State<PoiThumbnailsLayer> createState() => _PoiThumbnailsLayerState();
}

class _PoiThumbnailsLayerState extends State<PoiThumbnailsLayer> {

  // TODO poiSizes is never set

  final Map<int, Size> poiSizes = {};

  @override
  Widget build(BuildContext context) {
        DebugService.log('Build PoiThumbnailsLayer');

    final showThumbnails = widget.zoom >= 14.0;

    final screenSize = MediaQuery.of(context).size;
    
    int thumbnailCount = 0;
    
    widget.controller.poiScreenPositions.forEach((poiId, pos) {
      if (pos.dx >= 0 &&
            pos.dx <= screenSize.width &&
            pos.dy >= 0 &&
            pos.dy <= screenSize.height)
      {
        thumbnailCount++;
        }
    });

    final allowLabels = thumbnailCount <= 30;

    return Stack(
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
            child: poi.categories != null && poi.categories!.contains('districts')
                ? DistrictThumbnail(
                    poi: poi,
                    onSize: (size) {
                      poiSizes[poi.id!] = size;
                    },
                    allowLabel: allowLabels,
                    onTap: () => widget.onTapPoi(poi),
                    onLongPress: () => widget.onLongPressPoi(poi) ,
                  )
                : showThumbnails && poi.featuredImageUrl.isNotEmpty && context.watch<AppState>().isPoiEditMode == false
                ? PoiThumbnail(
                    poi: poi,
                    onTap: () => widget.onTapPoi(poi),
                    onLongPress: () => widget.onLongPressPoi(poi) ,
                    onSize: (size) {
                      poiSizes[poi.id!] = size;
                    },
                    allowLabel: allowLabels,
                  )
                : PinMarker(
                    poi: poi,
                    onTap: () => widget.onTapPoi(poi),
                    onLongPress: () => widget.onLongPressPoi(poi) ,
                    onSize: (size) {
                      poiSizes[poi.id!] = size;
                    },
                    allowLabel: allowLabels,
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
