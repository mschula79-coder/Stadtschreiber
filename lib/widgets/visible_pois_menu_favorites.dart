import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorite_lists_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiFavoritesList extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onClose;
  final void Function(PointOfInterest) onSelect;

  const PoiFavoritesList({
    super.key,
    required this.scrollController,
    required this.onClose,
    required this.onSelect,
  });

  @override
  ConsumerState<PoiFavoritesList> createState() => _PoiFavoritesListState();
}

class _PoiFavoritesListState extends ConsumerState<PoiFavoritesList> {
  /// Persistente POI-Speicherung pro Favoritenliste
  final Map<String, List<PointOfInterest>> favPoisByList = {};

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
          onExpansionChanged: (value) {
            ref
                .read(visiblePoisMenuStateProvider.notifier)
                .setTileExpanded("favorites", value);

            if (value) {
              ref
                  .read(visiblePoisMenuStateProvider.notifier)
                  .setPoiSelectionMode(PoiSelectionMode.favorites);
            }
          },
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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(listOfFavoriteLists.length, (index) {
                    final tileKey = GlobalKey();
                    final (listDTO, favoritesInThisList) =
                        listOfFavoriteLists[index];

                    final favPois = favPoisByList[listDTO.id] ?? [];

                    return StatefulBuilder(
                      builder: (context, setTileState) {
                        return ExpansionTile(
                          key: ValueKey("favorites_${listDTO.id}"),
                          tilePadding: const EdgeInsets.only(
                            left: 0,
                            right: 15,
                          ),
                          collapsedShape: const Border(),
                          shape: const Border(),
                          title: Text(
                            listDTO.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

                                          final current =
                                              favPoisByList[listDTO.id] ?? [];
                                          if (!current.any(
                                            (p) => p.id == poi.id,
                                          )) {
                                            favPoisByList[listDTO.id] = [
                                              ...current,
                                              poi,
                                            ];
                                          }

                                          return PoiListItem(
                                            selectEnabled: true,
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
                              padding: const EdgeInsets.only(
                                left: 0,
                                right: 15,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    icon: Iconify(
                                      Mdi.checkbox_multiple_marked_outline,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            ref
                                                .read(
                                                  poiSelectionProvider.notifier,
                                                )
                                                .setAll(favPois);
                                          });
                                    },
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    icon: const Iconify(
                                      Mdi.checkbox_multiple_blank_outline,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            ref
                                                .read(
                                                  poiSelectionProvider.notifier,
                                                )
                                                .clear();
                                          });
                                    },
                                  ),
                                ],
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
