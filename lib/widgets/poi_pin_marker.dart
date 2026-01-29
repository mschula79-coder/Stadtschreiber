import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/grommet_icons.dart';
import '../models/poi.dart';

class PinMarker extends StatelessWidget {
  final PointOfInterest poi;
  final VoidCallback onTap;

  const PinMarker({required this.poi, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Iconify(GrommetIcons.location_pin, color: const Color.fromARGB(255, 16, 23, 79), size: 24),
/*           Icon(Icons.location_pin, color: const Color.fromARGB(255, 16, 23, 79), size: 24),*/
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              poi.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
