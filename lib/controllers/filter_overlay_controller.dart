import 'package:flutter/material.dart';

class FilterOverlayController {
  OverlayEntry? _entry;
  AnimationController? _animationController;
  Animation<Offset>? _animation;

  bool get isOpen => _entry != null;

  void initAnimation(TickerProvider vsync) {
    _animationController?.dispose();
    _animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 220),
    );

    _animation = Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
        );
  }

  Animation<Offset> get animation => _animation!;

  void show({
    required BuildContext context,
    required GlobalKey buttonKey,
    required Widget Function(Animation<Offset> anim) builder,
  }) 
  {
    if (_entry != null) return;

    final RenderBox button =
        buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlayBox =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox;

    final buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final buttonSize = button.size;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => hide(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              top: buttonPosition.dy + buttonSize.height + 8,
              right: 0,
              width: MediaQuery.of(context).size.width * 0.66,
              child: builder(animation),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    _animationController!.forward();
  }

  void hide() {
    if (_entry == null) return;

    final entry = _entry;
    _entry = null;

    if (_animationController == null) {
      entry?.remove();
      return;
    }

    _animationController!.reverse().then((_) {
      entry?.remove();
      _animationController?.dispose();
      _animationController = null;
      _animation = null;
    });
  }

  void toggle({
    required BuildContext context,
    required GlobalKey buttonKey,
    required Widget Function(Animation<Offset> anim) builder,
  }) {
    if (isOpen) {
      hide();
    } else {
      show(context: context, buttonKey: buttonKey, builder: builder);
    }
  }

  void dispose() {
    _animationController?.dispose();
    _animationController = null;
    _animation = null;
    _entry = null;
  }
}
