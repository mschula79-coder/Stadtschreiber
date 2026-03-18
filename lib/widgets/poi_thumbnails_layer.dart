import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/poi_marker_positions_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
import '../models/poi.dart';
import '../services/debug_service.dart';
import '../widgets/poi_pin_marker.dart';
import '../widgets/poi_thumbnail.dart';
import '../widgets/district_thumbnail.dart';

class PoiThumbnailsLayer extends ConsumerStatefulWidget {
  final void Function(PointOfInterest poi) onTapPoi;

  const PoiThumbnailsLayer({
    super.key,
    required this.onTapPoi,
  });

  @override
  ConsumerState<PoiThumbnailsLayer> createState() => _PoiThumbnailsLayerState();
}

class _PoiThumbnailsLayerState extends ConsumerState<PoiThumbnailsLayer> {
  final Map<String, Size> poiSizes = {};

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build PoiThumbnailsLayer');

    final visiblePois = ref.watch(visiblePoisProvider).visible;
    final markerState = ref.watch(poiMarkerPositionProvider);
    final positions = markerState.positions;
    final zoom = markerState.zoom;

    final showThumbnails = zoom >= 14.0;
    final screenSize = MediaQuery.of(context).size;
    DebugService.log(
      "VISIBLE POIS: ${ref.watch(visiblePoisProvider).visible.length}\n Positions: $positions",
    );

    // Anzahl sichtbarer Marker bestimmen
    int thumbnailCount = positions.entries.where((entry) {
      final pos = entry.value;
      return pos.dx >= 0 &&
          pos.dx <= screenSize.width &&
          pos.dy >= 0 &&
          pos.dy <= screenSize.height;
    }).length;

    final allowLabels = thumbnailCount <= 30;
    return LayoutBuilder(
      builder: (context, constraints) {
        DebugService.log("PoiThumbnailsLayer constraints: $constraints");

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: positions.entries.expand((entry) {
            final poiId = entry.key;
            final pos = entry.value;

            final poi = visiblePois.firstWhereOrNull((p) => p.id == poiId);

            /* DebugService.log("""
          --- POI DEBUG ---
          poiId: $poiId
          pos: $pos
          poi found: ${poi != null}
          in screen: dx=${pos.dx >= 0 && pos.dx <= screenSize.width}, dy=${pos.dy >= 0 && pos.dy <= screenSize.height}
          showThumbnails: $showThumbnails
          featuredImageUrl empty: ${poi?.featuredImageUrl.isEmpty}
          categories: ${poi?.categories}
          """); */

            if (poi == null) return const Iterable<Widget>.empty();
            final bool showDot = false;
            return [
              // 🔴 Red dot (underneath)
              if(showDot)
                  // ignore: dead_code
                  Positioned(
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
                    ),
              // 🟦 District Thumbnail
              poi.categories != null && poi.categories!.contains('districts')
                  ? Positioned(
                      left: pos.dx - 10,
                      top: pos.dy - 12,
                      child: DistrictThumbnail(
                        poi: poi,
                        onSize: (size) => poiSizes[poi.id] = size,
                        allowLabel: allowLabels,
                        onTap: () => widget.onTapPoi(poi),
                      ),
                    )
                  // 🟩 Regular Thumbnail
                  : showThumbnails && poi.featuredImageUrl.isNotEmpty
                  ? Positioned(
                      left: poiSizes[poi.id] == null
                          ? pos.dx - 50
                          : pos.dx - poiSizes[poi.id]!.width / 2.5,
                      top: poiSizes[poi.id] == null
                          ? pos.dy - 24
                          : pos.dy - poiSizes[poi.id]!.height / 2,
                      child: PoiThumbnail(
                        poi: poi,
                        onTap: () => widget.onTapPoi(poi),
                        onSize: (size) => poiSizes[poi.id] = size,
                        allowLabel: allowLabels,
                      ),
                    )
                  // 🟥 Pin Marker
                  : Positioned(
                      left: pos.dx - 10,
                      top: pos.dy - 24,
                      child: PinMarker(
                        poi: poi,
                        onTap: () => widget.onTapPoi(poi),
                        allowLabel: allowLabels,
                      ),
                    ),
            ];
          }).toList(),
        );
      },
    );
  }
}
