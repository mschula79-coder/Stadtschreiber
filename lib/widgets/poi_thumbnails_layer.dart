import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/map_controller_provider.dart';
import 'package:stadtschreiber/provider/poi_drag_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';

import '../models/poi.dart';
import '../widgets/poi_thumbnail.dart';
import '../widgets/district_thumbnail.dart';
import '../widgets/poi_pin_marker.dart';

class PoiThumbnailsLayer extends ConsumerWidget {
  final void Function(PointOfInterest poi) onTapPoi;

   // ignore: prefer_const_constructors_in_immutables
   PoiThumbnailsLayer({super.key, required this.onTapPoi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /*     final cameraPosition = ref.watch(cameraProvider).getLocation();
 */
    final mapController = ref.watch(mapControllerProvider);

    if (mapController == null) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;

    // Thumbnails erst ab Zoom >= 14

    // Overlap-Avoidance
    final List<Offset> usedPositions = [];
    final List<Widget> widgets = [];

    final dragState = ref.watch(dragPoiProvider);
    final dragMode = dragState.dragPoi != null;

    if (dragMode) {
      final dragPoi = ref.watch(dragPoiProvider).dragPoi;

      final pos = mapController.toScreenLocation(dragPoi!.location);
      return Positioned(
        top: pos.dy - 2,
        left: pos.dx - 2,
        child: Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      final visiblePois = ref
          .watch(visiblePoisProvider)
          .maybeWhen(
            data: (list) => list,
            orElse: () => const <PointOfInterest>[],
          );

      final zoom = ref.watch(cameraProvider).zoom;
      final isThumbnailZoom = zoom >= 14.0;
      const minDistance = 50.0;

      // Thumbnail Widgets / District Marker Widgets / Pin Marker Widgets für alle Visible Pois erzeugen
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

        // Zoom-basierte Skalierung
        final scale = (zoom / 13.0).clamp(0.7, 1.6);

        // Widget auswählen
        Widget markerWidget;

        double markerPosLeft;
        double markerPosTop;

        // District Markers
        final isDistrict = poi.categories?.contains('districts') == true;
        if (isDistrict) {
          markerWidget = DistrictThumbnail(
            poi: poi,
            allowLabel: true,
            onTap: () => onTapPoi(poi),
          );
          markerPosLeft = pos.dx - 5;
          markerPosTop = pos.dy - 21;
        }
        // Normaler Poi
        else {
          // Overlap-Avoidance
          bool tooClose = usedPositions.any(
            (other) => (other - pos).distance < minDistance,
          );

          final noThumbnail =
              (poi.featuredImageUrl == null || poi.featuredImageUrl!.isEmpty);

          // Pinmarker
          if (!tooClose && isThumbnailZoom && !noThumbnail) {
            markerPosLeft = pos.dx - 45;
            markerPosTop = pos.dy - 21;

            markerWidget = PoiThumbnail(
              poi: poi,
              allowLabel: false,
              onTap: () => onTapPoi(poi),
            );
          } 
          else {
            markerWidget = PinMarker(
              poi: poi,
              allowLabel: !tooClose,
              onTap: () => onTapPoi(poi),
            );
            markerPosLeft = pos.dx - 5;
            markerPosTop = pos.dy - 21;
          }
          
          usedPositions.add(pos);
        }
        // Animation + Highlighting
        final animated = AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 150),
            child: markerWidget,
          ),
        );

        widgets.add(
          Positioned(left: markerPosLeft, top: markerPosTop, child: animated),
        );

        // Roter Punkt (Debug)
        widgets.add(
          Positioned(
            left: pos.dx - 4,
            top: pos.dy - 4,
            child: Container(
              width: 0,
              height: 0,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }

      return IgnorePointer(
        ignoring: false,
        child: Stack(clipBehavior: Clip.none, children: widgets),
      );
    }
  }
}
