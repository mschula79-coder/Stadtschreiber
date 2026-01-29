import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../state/categories_menu_state.dart';
import 'categories_menu_panel.dart';

class CategoriesMenuOverlayContent extends StatelessWidget {
  final List<CategoryNode> categories;
  final Animation<Offset> animation;
  final VoidCallback onClose;

  const CategoriesMenuOverlayContent({
    super.key,
    required this.categories,
    required this.animation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final categoriesMenuState = context.watch<CategoriesMenuState>();

    return SlideTransition(
      position: animation,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: CategoriesMenuPanel(
          categories: categories,
          categoriesMenuState: categoriesMenuState,
          onClose: onClose,
        ),
      ),
    );
  }
}
