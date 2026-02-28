import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';

import '../models/category.dart';
import '../models/poi.dart';
import '../controllers/poi_controller.dart';

class CategoryNodeTile extends StatelessWidget {
  final CategoryNode node;
  final PointOfInterest poi;
  final WidgetRef ref;

  const CategoryNodeTile({super.key, required this.node, required this.poi, required this.ref});

  @override
  Widget build(BuildContext context) {
    final hasChildren = node.children.isNotEmpty;

    if (hasChildren) {
      return ExpansionTile(
        title: Text(node.label),
        children: node.children
            .map((child) => CategoryNodeTile(node: child, poi: poi, ref: ref))
            .toList(),
      );
    }

    // Leaf node → checkbox
    final slug = node.value!;
    final isSelected = poi.categories?.contains(slug);

    return CheckboxListTile(
      title: Text(node.label),
      value: isSelected,
      onChanged: (checked) async {
        if (checked == null) return;

        final updatedPoi = await context.read<PoiController>().toggleCategory(
          selPoi: poi,
          categorySlug: slug,
          enabled: checked,
        );

        // WICHTIG: UI aktualisieren
        ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);
      },
    );
  }
}
