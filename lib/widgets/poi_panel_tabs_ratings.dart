import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/widgets/category_ratings_section.dart';

class PoiPanelRatingsTab extends ConsumerWidget {
  const PoiPanelRatingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPoi = ref.watch(selectedPoiProvider);
    if (selectedPoi == null ||
        selectedPoi.categories!.isEmpty ||
        selectedPoi.categories![0].isEmpty) {
      return SizedBox.shrink();
    }

    final categories = selectedPoi.categories ?? const <String>[];

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.all(12),
      child: SingleChildScrollView(child: CategoryRatingsSection()),
    );
  }
}
