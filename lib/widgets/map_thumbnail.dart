import 'package:flutter/material.dart';
import '../models/park.dart';

class MapThumbnail extends StatelessWidget {
  final Park park;
  final VoidCallback? onTap;

  const MapThumbnail({super.key, required this.park, this.onTap});

  @override
  Widget build(BuildContext context) {
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
                // ignore: unnecessary_null_comparison
                image: (park.photoUrl != null && park.photoUrl.isNotEmpty)
                    ? NetworkImage(park.photoUrl)
                    : const AssetImage('assets/icons/placeholder.png')
                          as ImageProvider,
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
              park.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
