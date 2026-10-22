import 'package:flutter/material.dart';
import 'package:stadtschreiber/utils/image_utils.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class PhotoGalleryModal extends StatefulWidget {
  final List<String> imageUrls;
  final String initialUrl;

  const PhotoGalleryModal({
    super.key,
    required this.imageUrls,
    required this.initialUrl,
  });

  static Future<void> open(
    BuildContext context, {
    required List<String> imageUrls,
    required String initialUrl,
  }) async {
    if (imageUrls.isEmpty) {
      return;
    }

    final validInitialUrl = imageUrls.contains(initialUrl)
        ? initialUrl
        : imageUrls.first;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gallery',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return PhotoGalleryModal(
          imageUrls: List<String>.unmodifiable(imageUrls),
          initialUrl: validInitialUrl,
        );
      },
      transitionBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  State<PhotoGalleryModal> createState() => _PhotoGalleryModalState();
}

class _PhotoGalleryModalState extends State<PhotoGalleryModal> {
  late final PageController _pageController;
  late int _currentIndex;

  final Map<String, Size> _imageSizes = {};
  final Set<String> _loadingImageSizes = {};
  final Set<String> _failedImageSizes = {};

  bool _pageAnimationRunning = false;

  @override
  void initState() {
    super.initState();

    final initialIndex = widget.imageUrls.indexOf(
      widget.initialUrl,
    );

    _currentIndex = initialIndex >= 0 ? initialIndex : 0;

    _pageController = PageController(
      initialPage: _currentIndex,
    );

    _loadImageSize(_currentIndex);
    _preloadNeighbourSizes(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canGoBack {
    return _currentIndex > 0 && !_pageAnimationRunning;
  }

  bool get _canGoForward {
    return _currentIndex < widget.imageUrls.length - 1 &&
        !_pageAnimationRunning;
  }

  Future<void> _loadImageSize(int index) async {
    if (index < 0 || index >= widget.imageUrls.length) {
      return;
    }

    final imageUrl = widget.imageUrls[index];

    if (_imageSizes.containsKey(imageUrl) ||
        _loadingImageSizes.contains(imageUrl) ||
        _failedImageSizes.contains(imageUrl)) {
      return;
    }

    _loadingImageSizes.add(imageUrl);

    try {
      final imageSize = await getImageSize(imageUrl);

      if (!mounted) {
        return;
      }

      setState(() {
        _imageSizes[imageUrl] = imageSize;
        _loadingImageSizes.remove(imageUrl);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingImageSizes.remove(imageUrl);
        _failedImageSizes.add(imageUrl);
      });
    }
  }

  void _preloadNeighbourSizes(int index) {
    if (index > 0) {
      _loadImageSize(index - 1);
    }

    if (index < widget.imageUrls.length - 1) {
      _loadImageSize(index + 1);
    }
  }

  Future<void> _goToPage(int index) async {
    if (_pageAnimationRunning) {
      return;
    }

    if (index < 0 || index >= widget.imageUrls.length) {
      return;
    }

    if (!_pageController.hasClients) {
      return;
    }

    setState(() {
      _pageAnimationRunning = true;
    });

    try {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } finally {
      if (mounted) {
        setState(() {
          _pageAnimationRunning = false;
        });
      }
    }
  }

  Future<void> _previousImage() async {
    if (!_canGoBack) {
      return;
    }

    await _goToPage(_currentIndex - 1);
  }

  Future<void> _nextImage() async {
    if (!_canGoForward) {
      return;
    }

    await _goToPage(_currentIndex + 1);
  }

  void _close() {
    Navigator.of(context).pop();
  }

  Size _calculateGallerySize(
    Size screenSize,
    Size? imageSize,
  ) {
    final maximumWidth = screenSize.width * 0.9;
    final maximumHeight = screenSize.height * 0.9;

    if (imageSize == null ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return Size(
        maximumWidth.clamp(280.0, 600.0),
        maximumHeight.clamp(280.0, 600.0),
      );
    }

    final widthScale = maximumWidth / imageSize.width;
    final heightScale = maximumHeight / imageSize.height;
    final scale = widthScale < heightScale
        ? widthScale
        : heightScale;

    final calculatedWidth = imageSize.width * scale;
    final calculatedHeight = imageSize.height * scale;

    return Size(
      calculatedWidth,
      calculatedHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final currentUrl = widget.imageUrls[_currentIndex];
    final currentImageSize = _imageSizes[currentUrl];

    final gallerySize = _calculateGallerySize(
      screenSize,
      currentImageSize,
    );

    final arrowInset = screenSize.width < 600 ? 0.0 : 8.0;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const ColoredBox(
                color: Color.fromRGBO(0, 0, 0, 0.85),
              ),
            ),
          ),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: gallerySize.width,
              height: gallerySize.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: widget.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });

                            _loadImageSize(index);
                            _preloadNeighbourSizes(index);
                          },
                          itemBuilder: (context, index) {
                            final imageUrl = widget.imageUrls[index];

                            return _ZoomableImage(
                              key: ValueKey(imageUrl),
                              url: imageUrl,
                            );
                          },
                        ),
                      ),
                      if (currentImageSize == null &&
                          !_failedImageSizes.contains(currentUrl))
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (_failedImageSizes.contains(currentUrl))
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black,
                            child: _GalleryImageError(),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          onPressed: _close,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.close,
                            size: 28,
                          ),
                        ),
                      ),
                      if (widget.imageUrls.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              left: arrowInset,
              child: IconButton(
                tooltip: 'Vorheriges Bild',
                iconSize: 48,
                color: _canGoBack
                    ? Colors.white
                    : Colors.white30,
                onPressed: _canGoBack ? _previousImage : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                ),
                icon: const Icon(
                  Icons.chevron_left,
                ),
              ),
            ),
          if (widget.imageUrls.length > 1)
            Positioned(
              right: arrowInset,
              child: IconButton(
                tooltip: 'Nächstes Bild',
                iconSize: 48,
                color: _canGoForward
                    ? Colors.white
                    : Colors.white30,
                onPressed: _canGoForward ? _nextImage : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                ),
                icon: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String url;

  const _ZoomableImage({
    super.key,
    required this.url,
  });

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller =
      TransformationController();

  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final details = _doubleTapDetails;

    if (details == null) {
      return;
    }

    if (!_controller.value.isIdentity()) {
      _controller.value = Matrix4.identity();
      return;
    }

    final position = details.localPosition;

    _controller.value = Matrix4.identity()
      ..translateByVector3(
        vector.Vector3(
          -position.dx * 1.5,
          -position.dy * 1.5,
          0,
        ),
      )
      ..scaleByDouble(
        2,
        2,
        1,
        1,
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) {
        _doubleTapDetails = details;
      },
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 4,
        clipBehavior: Clip.hardEdge,
        child: SizedBox.expand(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            loadingBuilder: (
              context,
              child,
              loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }

              final expectedBytes =
                  loadingProgress.expectedTotalBytes;

              final progress = expectedBytes == null
                  ? null
                  : loadingProgress.cumulativeBytesLoaded /
                      expectedBytes;

              return Center(
                child: CircularProgressIndicator(
                  value: progress,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const _GalleryImageError();
            },
          ),
        ),
      ),
    );
  }
}

class _GalleryImageError extends StatelessWidget {
  const _GalleryImageError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'Das Bild konnte nicht geladen werden.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}