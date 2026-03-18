import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';

import '../models/category.dart';

class PoiCategoryNodeTile extends ConsumerWidget {
  final CategoryNode node;

  const PoiCategoryNodeTile({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = ref.watch(selectedPoiProvider)!;

    final hasChildren = node.children.isNotEmpty;

    if (hasChildren) {
      return ExpansionTile(
        title: Text(node.label),
        children: node.children
            .map((child) => PoiCategoryNodeTile(node: child))
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

        final updatedPoi = await ref
            .read(poiRepositoryProvider)
            .updatePoiCategory(poi: poi, category: slug, enabled: checked);

        ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);
      },
    );
  }
}
