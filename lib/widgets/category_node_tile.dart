import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/poi.dart';
import '../controllers/poi_controller.dart';

class CategoryNodeTile extends StatelessWidget {
  final CategoryNode node;
  final PointOfInterest poi;

  const CategoryNodeTile({
    super.key,
    required this.node,
    required this.poi,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = node.children.isNotEmpty;

    if (hasChildren) {
      return ExpansionTile(
        title: Text(node.label),
        children: node.children
            .map((child) => CategoryNodeTile(node: child, poi: poi))
            .toList(),
      );
    }

    // Leaf node → checkbox
    final slug = node.value!;
    final isSelected = poi.categories.contains(slug);

    return CheckboxListTile(
      title: Text(node.label),
      value: isSelected,
      onChanged: (checked) {
        if (checked == null) return;

        context.read<PoiController>().toggleCategory(
              poi: poi,
              categorySlug: slug,
              enabled: checked,
            );
      },
    );
  }
}
