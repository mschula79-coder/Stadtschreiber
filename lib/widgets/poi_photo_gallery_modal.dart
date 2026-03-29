import 'package:flutter/material.dart';
import 'package:stadtschreiber/utils/image_utils.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class PhotoGalleryModal extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PhotoGalleryModal({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<PhotoGalleryModal> createState() => _PhotoGalleryModalState();

  static void open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Gallery",
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) {
        return PhotoGalleryModal(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        );
      },
    );
  }
}

class _PhotoGalleryModalState extends State<PhotoGalleryModal> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Hintergrund abdunkeln
        Container(color: const Color.fromRGBO(0, 0, 0, 0.7)),

        // Galerie-Container (80% Größe)
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: size.width * 0.9,
              maxHeight: size.height * 0.9,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Size>(
                future: getImageSize(widget.imageUrls[widget.initialIndex]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final imageSize = snapshot.data!;
                  final aspectRatio = imageSize.width / imageSize.height;

                  return AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: widget.imageUrls.length,
                          itemBuilder: (context, index) {
                            final url = widget.imageUrls[index];
                            return _ZoomableImage(url: url);
                          },
                        ),

                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            color: Colors.white,
                            iconSize: 28,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Pfeil links (außerhalb des Containers)
        Positioned(
          left: size.width * 0.05,
          child: IconButton(
            iconSize: 48,
            color: Colors.white,
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              if (_pageController.page! > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),

        // Pfeil rechts (außerhalb des Containers)
        Positioned(
          right: size.width * 0.05,
          child: IconButton(
            iconSize: 48,
            color: Colors.white,
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              if (_pageController.page! < widget.imageUrls.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String url;

  const _ZoomableImage({required this.url});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: () {
        if (_controller.value != Matrix4.identity()) {
          _controller.value = Matrix4.identity();
        } else {
          final position = _doubleTapDetails!.localPosition;

          _controller.value = Matrix4.identity()
            ..translateByVector3(vector.Vector3(-position.dx * 1.5, -position.dy * 1.5, 0.0))
            ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
        }
      },

      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        clipBehavior: Clip.none,
        child: Image.network(widget.url, fit: BoxFit.contain),
      ),
    );
  }
}
