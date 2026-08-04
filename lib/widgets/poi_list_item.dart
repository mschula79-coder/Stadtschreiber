import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';

class PoiListItem extends ConsumerWidget {
  final PointOfInterest poi;
  final VoidCallback onTap;

  const PoiListItem({super.key, required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String distanceKm = 'unbekannt';
    if (poi.distance != null) {
      distanceKm = '${(poi.distance! / 1000).toStringAsFixed(3)}km';
    }

    final poiRatingsAsync = ref.watch(poiRatingsWithStatsProvider(poi.id));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child:
                    (poi.featuredImageUrl != null &&
                        poi.featuredImageUrl!.isNotEmpty)
                    ? Image.network(poi.featuredImageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported),
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
                  Text(
                    poi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Kategorien
                  if (poi.categories != null && poi.categories!.isNotEmpty)
                    Text(
                      'Kategorie(n): ${poi.categories!.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
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
                  Text(
                    '${AppLocalizations.of(context)?.distanceFromCenter ?? 'distanceFromCenter'} $distanceKm',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                  poiRatingsAsync.when(
                    loading: () => CircularProgressIndicator(),
                    error: (e, _) => Text("Fehler: $e"),
                    data: (ratings) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...ratings.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r.criterionName}: ${r.avgRating} (${r.ratingCount})',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  Text(
                    'hallo',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
