import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorite_lists_provider.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiFavoritesList extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onClose;
  final void Function(List<PointOfInterest>) onShowAll;
  final void Function(PointOfInterest) onSelect;

  const PoiFavoritesList({
    super.key,
    required this.scrollController,
    required this.onClose,
    required this.onShowAll,
    required this.onSelect,
  });

  @override
  ConsumerState<PoiFavoritesList> createState() => _PoiFavoritesListState();
}

class _PoiFavoritesListState extends ConsumerState<PoiFavoritesList> {
  void _scrollToTile(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) return;

      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final viewport = RenderAbstractViewport.of(box);

      final target = viewport.getOffsetToReveal(box, 0.0).offset;

      final adjusted = (target - 80).clamp(
        widget.scrollController.position.minScrollExtent,
        widget.scrollController.position.maxScrollExtent,
      );

      widget.scrollController.animateTo(
        adjusted,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userID = ref.watch(supabaseUserStateProvider).userid;
    final favoriteListsAsync = ref.watch(userFavoriteListsProvider(userID));

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.zero),
      ),
      child: ListTileTheme(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 0,
        minLeadingWidth: 0,
        minVerticalPadding: 0,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 0, right: 15),
          childrenPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,

          // ⭐ Fix 1: verhindert zusätzliches Padding + Animation
          collapsedShape: const Border(),
          shape: const Border(),

          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,

          title: Row(
            children: [
              Icon(Icons.star, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Favoriten",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          children: [
            const SizedBox(height: 0),

            favoriteListsAsync.when(
              data: (listOfFavoriteLists) {
                if (listOfFavoriteLists.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.zero,
                    child: Text(
                      "Keine Favoritenlisten vorhanden",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }

                List<PointOfInterest> favPois = [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(listOfFavoriteLists.length, (index) {
                    final tileKey = GlobalKey();
                    final (listDTO, favoritesInThisList) =
                        listOfFavoriteLists[index];

                    return ExpansionTile(
                      key: tileKey,
                      title: Text(listDTO.name),
                      tilePadding: const EdgeInsets.only(left: 0, right: 15),

                      // ⭐ Fix 1 auch für die inneren Tiles
                      collapsedShape: const Border(),
                      shape: const Border(),

                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...favoritesInThisList.map(
                              (fav) => Consumer(
                                builder: (context, ref, _) {
                                  final poiAsync = ref.watch(
                                    poiByIdProvider(fav.poiID),
                                  );

                                  return poiAsync.when(
                                    data: (poi) {
                                      if (poi == null) {
                                        return const Padding(
                                          padding: EdgeInsets.zero,
                                          child: Text("POI not found"),
                                        );
                                      }

                                      favPois.add(poi);

                                      return PoiListItem(
                                        poi: poi,
                                        onTap: () {
                                          widget.onSelect(poi);
                                          widget.onClose();
                                        },
                                        paddingLeft: 0,
                                      );
                                    },
                                    loading: () => const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (e, st) => Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text("Error: $e"),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: ElevatedButton(
                                child: const Text("Alle anzeigen"),
                                onPressed: () {
                                  widget.onShowAll(favPois);
                                },
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ],

                      onExpansionChanged: (expanded) {
                        if (expanded) {
                          _scrollToTile(tileKey);
                        }
                      },
                    );
                  }),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text("Error: $e"),
            ),
          ],
        ),
      ),
    );
  }
}
