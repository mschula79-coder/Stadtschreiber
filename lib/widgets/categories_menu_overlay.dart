import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'categories_menu_content.dart';

class CategoriesMenuOverlay extends ConsumerWidget {
  final Animation<Offset> animation;
  final VoidCallback onClose;

  const CategoriesMenuOverlay({
    super.key,
    required this.animation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SlideTransition(
      position: animation,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: CategoriesMenuContent(
          onClose: onClose,
        ),
      ),
    );
  }
}
