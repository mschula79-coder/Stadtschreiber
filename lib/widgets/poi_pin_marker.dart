import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/grommet_icons.dart';
import '../models/poi.dart';

class PinMarker extends StatefulWidget {
  final PointOfInterest poi;
  final VoidCallback onTap;
  final ValueChanged<Size>? onSize;
  final bool allowLabel;

  const PinMarker({
    required this.poi,
    required this.onTap,
    this.onSize,
    required this.allowLabel,
    super.key,
  });

  @override
  State<PinMarker> createState() => _PinMarkerState();
}

class _PinMarkerState extends State<PinMarker> {
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    // Measure after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (size != null && size != _lastSize && widget.onSize != null) {
        _lastSize = size;
        widget.onSize!(size);
      }
    });

    return GestureDetector(
      onTap: widget.onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Iconify(
            GrommetIcons.location_pin,
            color: const Color.fromARGB(255, 16, 23, 79),
            size: 24,
          ),
          const SizedBox(width: 4),
          widget.allowLabel
          ? 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              widget.poi.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          : Container()
        ],
      ),
    );
  }
}
