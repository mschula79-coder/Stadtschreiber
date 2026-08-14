import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_mode_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_provider.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiListPanel extends ConsumerStatefulWidget {
  const PoiListPanel({super.key});

  @override
  ConsumerState<PoiListPanel> createState() => _PoiListState();
}

class _PoiListState extends ConsumerState<PoiListPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /*     final width = MediaQuery.of(context).size.width; */
    /*     final horizontalPadding = width < 600 ? 24.0 : width * 0.3;*/

    final visiblePoisAsync = ref.watch(visiblePoisProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      height: ref.read(appStateProvider).panelHeight - 45,
      child: Column(
        children: [
          PoiListHeader(
            onClose: () {
              ref.read(appStateProvider.notifier).setPoiListVisible(false);
            },
          ),
          SizedBox(height: 16),

          Expanded(
            child: visiblePoisAsync.when(
              data: (visiblePois) {
                return ListView.builder(
                  itemCount: visiblePois.length,
                  itemBuilder: (context, index) {
                    return PoiListItem(
                      poi: visiblePois[index],
                      onTap: () {
                        ref
                            .read(selectedPoiProvider.notifier)
                            .setPoi(visiblePois[index]);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text("Fehler: $err"),
            ),
          ),
        ],
      ),
    );
  }
}

class PoiListHeader extends ConsumerWidget {
  final VoidCallback onClose;

  const PoiListHeader({super.key, required this.onClose});
// TODO DistancefromMapcenter um poi list panel korrigieren
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String headline;
    final poiSelectionMode = ref.read(poiSelectionModeProvider);
    switch (poiSelectionMode) {
      case PoiSelectionMode.top10:
        headline = 'Top 10';
      case PoiSelectionMode.categories:
        final slug =ref.read(selectedCategoriesProvider)[0] ;
        final cat = ref.read(categoryLabelBySlugProvider(slug)); 
        headline = 'Liste der $cat';
      case PoiSelectionMode.search:
        headline = 'Suchergebnis';
      case PoiSelectionMode.favorites:
        headline = 'Deine Favoriten';
      default:
        headline = AppLocalizations.of(context)!.poiList;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 0, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
