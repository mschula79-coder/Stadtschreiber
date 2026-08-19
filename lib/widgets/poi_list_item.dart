import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/provider/user_location_state_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';

class PoiListItem extends ConsumerWidget {
  final PointOfInterest poi;
  final VoidCallback onTap;
  final double? paddingLeft;
  final double? imageWidth;
  final double? imageHeight;

  const PoiListItem({
    super.key,
    required this.poi,
    required this.onTap,
    this.paddingLeft,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camera = ref.watch(cameraProvider);

    final distance = geoDistanceMeters(poi.location, camera.getLocation());

    final myLocation = ref.watch(userLocationStateProvider);

    double distanceMe;

    if (myLocation != null) {
      distanceMe = geoDistanceMeters(
        poi.location,
        Geographic(lon: myLocation.longitude, lat: myLocation.latitude),
      );
    } else {
      distanceMe = 0;
    }
    final String distanceKm = '${(distance / 1000).toStringAsFixed(3)}km';
    final String distanceMeKm = '${(distanceMe / 1000).toStringAsFixed(3)}km';

    final poiRatingsAsync = ref.watch(poiRatingsWithStatsProvider(poi.id));

    final labels = poi.categories!
        .map((slug) => ref.watch(categoryLabelBySlugProvider(slug)))
        .whereType<String>()
        .toList();

    return Column(
      children: [
        Divider(height: 16, thickness: 1, color: Colors.grey.shade300),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(
                    paddingLeft ?? 12,
                    0,
                    0,
                    0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: imageWidth ?? 120,
                      height: imageHeight ?? 120,
                      child:
                          (poi.featuredImageUrl != null &&
                              poi.featuredImageUrl!.isNotEmpty)
                          ? Image.network(
                              poi.featuredImageUrl!,
                              fit: BoxFit
                                  .cover, // ⭐ füllt das Rechteck vollständig
                              alignment:
                                  Alignment.center, // ⭐ zentriert den Crop
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Textbereich
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      SizedBox(height: 0),
                      Text(
                        poi.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
// Adresse
                      if (poi.address?.displayAddress() != null)
                        Text(
                          poi.address?.displayAddress() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),


                      // Distanz in km
                      Row(
                        children: [
                          getIcon("center", 16, Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            distanceKm,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          distanceMe > 0
                              ? Row(
                                  children: [
                                    const SizedBox(width: 10),

                                    getIcon(
                                      "airplane",
                                      16,
                                      Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      distanceMeKm,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      
                      SizedBox(height: 0),


                      poiRatingsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (e, st) => Text("Fehler: ${e.toString()}"),
                        data: (ratings) {
                          return Wrap(
                            spacing: 4, // Abstand zwischen Items
                            runSpacing: 0, // Abstand zwischen Zeilen
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

                                    // ⭐ Komma nur zwischen Items, nicht am Ende
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

                      
                      /* SizedBox(height: 4),


                      // Kategorien
                      if (poi.categories != null && poi.categories!.isNotEmpty)
                        Text(
                          'Kategorie(n): ${labels.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ), */
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
