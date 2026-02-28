// Districts Thumbnail

import 'package:flutter/material.dart';
import '../models/poi.dart';

class PoiThumbnail extends StatefulWidget {
  final PointOfInterest poi;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;  
  final ValueChanged<Size>? onSize;
  final bool allowLabel;

  const PoiThumbnail({
    super.key, 
    required this.poi, 
    this.onTap, 
    this.onSize,
    required this.allowLabel,
    this.onLongPress,
  });

  @override
  State<PoiThumbnail> createState() => _PoiThumbnailState();
}

class _PoiThumbnailState extends State<PoiThumbnail> {

  @override
  void initState() {
    super.initState();
    final estimatedSize = const Size(120, 50 + 4 + 20);
    if (widget.onSize != null) {
      widget.onSize!(estimatedSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.poi.featuredImageUrl.isNotEmpty;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
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
                    ? NetworkImage(widget.poi.featuredImageUrl)
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
          widget.allowLabel
          ?
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.poi.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          )
          : Container()
        ],
      ),
    );
  }
}
