import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/user_location_state_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';

class PoiListItem extends ConsumerWidget {
  final PointOfInterest poi;
  final VoidCallback onTap;
  final double? paddingLeft;
  final double? imageWidth;
  final double? imageHeight;
  final bool? selectEnabled;

  const PoiListItem({
    super.key,
    required this.poi,
    required this.onTap,
    this.paddingLeft,
    this.imageWidth,
    this.imageHeight,
    this.selectEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraPosition = ref.watch(cameraPositionPanelCorrectedProvider);
    final distance = geoDistanceMeters(poi.location, cameraPosition);

    final myLocation = ref.watch(userLocationStateProvider);
    final distanceMe = myLocation != null
        ? geoDistanceMeters(
            poi.location,
            Geographic(lon: myLocation.longitude, lat: myLocation.latitude),
          )
        : 0;

    final poiRatingsAsync = ref.watch(poiRatingsWithStatsProvider(poi.id));

    // ⭐ Auswahlstatus
    final selection = ref.watch(poiSelectionProvider);
    final isSelected = selection.contains(poi);
    final selectionMode = selection.isNotEmpty;

    return Column(
      children: [
        Divider(height: 16, thickness: 1, color: Colors.grey.shade300),

        InkWell(
          onTap: () {
            if (selectEnabled == true && selectionMode) {
              // ⭐ Im Selection‑Mode toggelt ein einfacher Tap
              ref.read(poiSelectionProvider.notifier).toggle(poi);
            } else {
              // ⭐ Normaler Tap
              onTap();
            }
          },
          onLongPress: () {
            if (selectEnabled == true) {
              ref.read(poiSelectionProvider.notifier).toggle(poi);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ⭐ Thumbnail + Checkmark Overlay
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(
                    paddingLeft ?? 12,
                    0,
                    0,
                    0,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: imageWidth ?? 120,
                          height: imageHeight ?? 120,
                          child:
                              (poi.featuredImageUrl != null &&
                                  poi.featuredImageUrl!.isNotEmpty)
                              ? Image.network(
                                  poi.featuredImageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                      ),

                      // ⭐ Checkmark Overlay (zentriert)
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ⭐ Textbereich
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        maxLines: 99,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (poi.address?.displayAddress() != null)
                        Text(
                          poi.address!.displayAddress() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),

                      Row(
                        children: [
                          getIcon("center", 16, Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            '${(distance / 1000).toStringAsFixed(3)}km',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          if (distanceMe > 0)
                            Row(
                              children: [
                                const SizedBox(width: 10),
                                getIcon("airplane", 16, Colors.grey.shade600),
                                const SizedBox(width: 2),
                                Text(
                                  '${(distanceMe / 1000).toStringAsFixed(3)}km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      poiRatingsAsync.when(
                        loading: () =>
                            const CircularProgressIndicator(strokeWidth: 1),
                        error: (e, st) => Text("Fehler: ${e.toString()}"),
                        data: (ratings) {
                          return Wrap(
                            spacing: 4,
                            children: [
                              for (int i = 0; i < ratings.length; i++)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    getIcon(
                                      ratings[i].criterionName,
                                      16,
                                      Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${ratings[i].criterionName}: '
                                      '${ratings[i].avgRating} (${ratings[i].ratingCount})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (i < ratings.length - 1)
                                      const Text(
                                        ',',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
