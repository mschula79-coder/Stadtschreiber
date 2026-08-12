import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_display_modes.dart';
import 'package:stadtschreiber/provider/manual_pois_provider.dart';
import 'package:stadtschreiber/provider/poi_display_mode_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
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
      child: SingleChildScrollView(
        controller: menuScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            PoiSearch(
              onClose: widget.onClose,
              onSelect: (poi) {
                ref.read(selectedPoiProvider.notifier).setPoi(poi);
                ref.read(manualPoisProvider.notifier).clear();
                ref.read(manualPoisProvider.notifier).setPois([poi]);

                ref
                    .read(poiDisplayModeProvider.notifier)
                    .setMode(PoiDisplayMode.manual);
                widget.onClose();
              },
              onShowAll: (searchResultPois) {
                ref.read(manualPoisProvider.notifier).setPois(searchResultPois);
                ref
                    .read(poiDisplayModeProvider.notifier)
                    .setMode(PoiDisplayMode.manual);
                widget.onClose();
              },
            ),

            SizedBox(height: 8),
            PoiCategorySelection(onClose: widget.onClose),

            SizedBox(height: 8),

            PoiTop10List(
              onClose: () {
                widget.onClose();
              },
              onSelect: (poi) {
                ref.read(selectedPoiProvider.notifier).setPoi(poi);
                ref.read(manualPoisProvider.notifier).clear();
                ref.read(manualPoisProvider.notifier).setPois([poi]);

                ref
                    .read(poiDisplayModeProvider.notifier)
                    .setMode(PoiDisplayMode.manual);
                widget.onClose();
              },
              onShowAll: (top10Pois) {
                ref.read(manualPoisProvider.notifier).setPois(top10Pois);
                ref
                    .read(poiDisplayModeProvider.notifier)
                    .setMode(PoiDisplayMode.manual);
                widget.onClose();
              },
            ),

            SizedBox(height: 8),

            PoiFavoritesList(
              scrollController: menuScrollController,
              onClose: widget.onClose,
              onSelect: (poi) {
                ref.read(selectedPoiProvider.notifier).setPoi(poi);
                ref.read(manualPoisProvider.notifier).clear();
                ref.read(manualPoisProvider.notifier).setPois([poi]);
                ref
                    .read(poiDisplayModeProvider.notifier)
                    .setMode(PoiDisplayMode.manual);
                widget.onClose();
              },
              onShowAll: (favPois) {
                ref.read(manualPoisProvider.notifier).setPois(favPois);
                ref
                    .read(poiDisplayModeProvider.notifier)
                    .setMode(PoiDisplayMode.manual);
                widget.onClose();
              },
            ),

            // TOP10
          ],
        ),
      ),
    );
  }
}
