import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_category_selection.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_favorites.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_search.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_top10.dart';

class VisiblePoisMenu extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const VisiblePoisMenu({super.key, required this.onClose});

  @override
  ConsumerState<VisiblePoisMenu> createState() => _VisiblePoisMenuState();
}

class _VisiblePoisMenuState extends ConsumerState<VisiblePoisMenu> {
  final ScrollController menuScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final pois = ref.watch(visiblePoisProvider);

    final int selectedPoiCount = ref.watch(poiSelectionProvider).length;

    final menuExpanded = ref
        .watch(visiblePoisMenuStateProvider)
        .expandedTiles
        .values
        .any((v) => v);

    return Container(
      // Menucontainer
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.75 -
            MediaQuery.of(context).viewInsets.bottom,
      ),

      // Menuinhalt
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: menuScrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  PoiSearch(
                    onClose: () => widget.onClose(),
                    onSelect: (poi) {
                      ref.read(selectedPoiProvider.notifier).setPoi(poi);
                      ref.read(visiblePoisProvider.notifier).addPois([poi]);
                      widget.onClose();
                    },
                  ),

                  SizedBox(height: 0),

                  PoiCategorySelection(),

                  SizedBox(height: 8),

                  PoiTop10List(
                    onClose: () {
                      widget.onClose();
                    },

                    onSelect: (poi) {
                      ref.read(selectedPoiProvider.notifier).setPoi(poi);
                      ref.read(visiblePoisProvider.notifier).addPois([poi]);
                      widget.onClose();
                    },
                  ),

                  SizedBox(height: 8),
                  PoiFavoritesList(
                    scrollController: menuScrollController,
                    onClose: () => widget.onClose(),
                    onSelect: (poi) {
                      ref.read(selectedPoiProvider.notifier).setPoi(poi);
                      ref.read(visiblePoisProvider.notifier).addPois([poi]);
                      widget.onClose();
                    },
                  ),

                  // TOP10
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.black54, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "${pois.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),

                if (menuExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,

                        icon: const Iconify(
                          Mdi.visibility_off_outline,
                          color: Colors.black87,
                          size: 24,
                        ),
                        onPressed: () {
                          ref
                              .read(categoriesSelectionProvider.notifier)
                              .clear();
                          ref.read(visiblePoisProvider.notifier).clear();
                        },
                      ),
                      const SizedBox(width: 12),


                      IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Iconify(
                          Mdi.eye_add_outline,
                          color: Colors.black87,
                          size: 24,
                        ),
                        onPressed: () {
                          final selectedPois = ref.read(poiSelectionProvider);
                          ref
                              .read(visiblePoisProvider.notifier)
                              .addPois(selectedPois);
                        },
                      ),
                      SizedBox(width: 0),
                      Text(
                        "$selectedPoiCount",

                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 8,
                        ),
                      ),

                      const SizedBox(width: 12),


                      IconButton(
                        visualDensity: VisualDensity.compact,

                        icon: const Iconify(
                          Mdi.check,
                          color: Colors.black87,
                          size: 24,
                        ),
                        onPressed: () {
                          final selectedPois = ref.read(poiSelectionProvider);
                          ref
                              .read(visiblePoisProvider.notifier)
                              .addPois(selectedPois);

                          widget.onClose();
                        },
                      ),
                      const SizedBox(width: 12),

                      IconButton(
                        visualDensity: VisualDensity.compact,

                        icon: const Iconify(
                          Mdi.close,
                          color: Colors.black87,
                          size: 24,
                        ),
                        onPressed: () {
                          widget.onClose();
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
