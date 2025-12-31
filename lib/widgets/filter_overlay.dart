import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../state/filter_state.dart';
import 'filter_panel.dart';

class FilterOverlayContent extends StatelessWidget {
  final List<CategoryNode> categories;
  final Animation<Offset> animation;
  final VoidCallback onClose;

  const FilterOverlayContent({
    super.key,
    required this.categories,
    required this.animation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final filterState = context.watch<FilterState>();

    return SlideTransition(
      position: animation,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: FilterPanel(
          categories: categories,
          filterState: filterState,
          onClose: onClose,
        ),
      ),
    );
  }
}
