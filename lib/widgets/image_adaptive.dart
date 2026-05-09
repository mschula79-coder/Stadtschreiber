import 'package:flutter/material.dart';
import 'package:stadtschreiber/utils/image_utils.dart';

class AdaptiveFeaturedImage extends StatelessWidget {
  final String url;
  final double maxPortraitHeight;

  const AdaptiveFeaturedImage({
    super.key,
    required this.url,
    required this.maxPortraitHeight,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: getImageSize(url),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final size = snapshot.data!;
        final isPortrait = size.height > size.width;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isPortrait ? maxPortraitHeight : double.infinity,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        );
      },
    );
  }
}
