import 'package:flutter/material.dart';
import '../models/poi.dart';

class PoiThumbnail extends StatelessWidget {
  final PointOfInterest poi;
  final VoidCallback? onTap;

  const PoiThumbnail({super.key, required this.poi, this.onTap});
  @override
  Widget build(BuildContext context) {
    final hasPhoto = poi.featuredImageUrl?.isNotEmpty ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: DecorationImage(
                image: hasPhoto
                    ? NetworkImage(poi.featuredImageUrl!)
                    : const AssetImage('assets/icons/placeholder.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              poi.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
