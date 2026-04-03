import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/map_controller_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';

import '../models/poi.dart';
import '../widgets/poi_thumbnail.dart';
import '../widgets/district_thumbnail.dart';
import '../widgets/poi_pin_marker.dart';

class PoiThumbnailsLayer extends ConsumerWidget {
  final void Function(PointOfInterest poi) onTapPoi;

  const PoiThumbnailsLayer({super.key, required this.onTapPoi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visiblePois = ref
        .watch(visiblePoisProvider)
        .maybeWhen(
          data: (list) => list,
          orElse: () => const <PointOfInterest>[],
        );

    final selectedPoi = ref.watch(selectedPoiProvider);
    final zoom = ref.watch(cameraProvider).zoom;
    final mapController = ref.watch(mapControllerProvider);

    if (mapController == null) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;

    // Thumbnails erst ab Zoom >= 14
    final showThumbnails = zoom >= 14.0;

    // Overlap-Avoidance
    final List<Offset> usedPositions = [];
    final List<Widget> widgets = [];

    for (final poi in visiblePois) {
      // Live-Berechnung der Position
      final screen = mapController.toScreenLocation(poi.location);
      final pos = Offset(screen.dx, screen.dy);

      // Nur Marker im sichtbaren Bereich
      final isOnScreen =
          pos.dx >= 0 &&
          pos.dx <= screenSize.width &&
          pos.dy >= 0 &&
          pos.dy <= screenSize.height;

      if (!isOnScreen) continue;

      DebugService.log(
        'PoiThumbnailsLayer: ${poi.name}: posx: ${pos.dx}, posy: ${pos.dy}',
      );

      // Overlap-Avoidance
      const minDistance = 50.0;
      final tooClose = usedPositions.any(
        (other) => (other - pos).distance < minDistance,
      );
      if (tooClose) continue;

      usedPositions.add(pos);

      // Highlighting
      final isSelected = selectedPoi?.id == poi.id;

      // Zoom-basierte Skalierung
      final scale = (zoom / 13.0).clamp(0.7, 1.6);

      // Widget auswählen
      Widget markerWidget;

      final isDistrict = poi.categories?.contains('districts') == true;
      final hasThumbnail = poi.featuredImageUrl != null;

      if (isDistrict) {
        markerWidget = DistrictThumbnail(
          poi: poi,
          allowLabel: true,
          onTap: () => onTapPoi(poi),
        );
      } else if (showThumbnails && hasThumbnail) {
        markerWidget = PoiThumbnail(
          poi: poi,
          allowLabel: true,
          onTap: () => onTapPoi(poi),
        );
      } else {
        markerWidget = PinMarker(
          poi: poi,
          allowLabel: true,
          onTap: () => onTapPoi(poi),
        );
      }

      // Animation + Highlighting
      final animated = AnimatedScale(
        scale: isSelected ? scale * 1.2 : scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 150),
          child: markerWidget,
        ),
      );

      // Roter Punkt (Debug)
      widgets.add(
        Positioned(
          left: pos.dx - 4,
          top: pos.dy - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

      // Thumbnail / Pin positionieren
      if (isDistrict) {
        widgets.add(
          Positioned(left: pos.dx - 5, top: pos.dy - 21, child: animated),
        );
      } else if (showThumbnails && hasThumbnail) {
        widgets.add(
          Positioned(left: pos.dx - 45, top: pos.dy - 21, child: animated),
        );
      } else {
        widgets.add(
          Positioned(left: pos.dx - 5, top: pos.dy - 21, child: animated),
        );
      }
    }

    return IgnorePointer(
      ignoring: false,
      child: Stack(clipBehavior: Clip.none, children: widgets),
    );
  }
}
