import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi_display_modes.dart';
import 'package:stadtschreiber/provider/manual_pois_provider.dart';
import 'package:stadtschreiber/provider/poi_display_mode_provider.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_category_selection.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_favourites.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_search.dart';
import 'package:stadtschreiber/widgets/visible_pois_menu_top10.dart';

class VisiblePoisMenu extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const VisiblePoisMenu({super.key, required this.onClose});

  @override
  ConsumerState<VisiblePoisMenu> createState() => _VisiblePoisMenuState();
}

class _VisiblePoisMenuState extends ConsumerState<VisiblePoisMenu> {
  bool isFilterActive = false;
  bool expandAll = false;
  bool isAdminViewEnabled = false;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PoiSearch(
              onClose: widget.onClose,
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
            PoiTop10List(onSelect: () {}),
            SizedBox(height: 8),
            PoiFavouritesList(
              onClose: widget.onClose,
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
