import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

import '../models/poi.dart';

class DistrictThumbnail extends StatefulWidget {
  final PointOfInterest poi;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<Size>? onSize;
  final bool allowLabel;


  const DistrictThumbnail({
    required this.poi,
    this.onTap,
    this.onLongPress,
    this.onSize,
    required this.allowLabel,
    super.key,
  });

  @override
  State<DistrictThumbnail> createState() => _DistrictThumbnailState();
}

class _DistrictThumbnailState extends State<DistrictThumbnail> {
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
      onLongPress: widget.onLongPress,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Iconify(
            Mdi.city,
            color: const Color.fromRGBO(220, 113, 121, 1),
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

