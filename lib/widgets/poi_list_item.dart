import 'package:flutter/material.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/poi.dart';

class PoiListItem extends StatelessWidget {
  final PointOfInterest poi;
  final VoidCallback onTap;

  const PoiListItem({super.key, required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String distanceKm = 'unbekannt';
    if (poi.distance != null) {
      distanceKm = '${(poi.distance! / 1000).toStringAsFixed(3)}km' ;
}
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
