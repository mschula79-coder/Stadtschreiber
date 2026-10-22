import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorite_lists_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/modal_poi_list_categories_filter.dart';
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
  final Map<Object, List<PointOfInterest>> favPoisByList = {};
  final Map<Object, Set<String>> selectedCategoriesByList = {};
  final Map<Object, GlobalKey> tileKeys = {};
  final Map<Object, ExpansibleController> tileControllers = {};

  @override
  Widget build(BuildContext context) {
    final userID = ref.watch(supabaseUserStateProvider).userid;
    final languageCode = ref.watch(localeProvider).languageCode;
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
          collapsedShape: const Border(),
          shape: const Border(),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          onExpansionChanged: (expanded) {
            ref
                .read(visiblePoisMenuStateProvider.notifier)
                .setTileExpanded("favorites", expanded);

            if (expanded) {
              ref
                  .read(visiblePoisMenuStateProvider.notifier)
                  .setPoiSelectionMode(PoiSelectionMode.favorites);
            }
          },
          title: Row(
            children: [
              Icon(Icons.star, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getText('favorites', languageCode: languageCode),
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
                      getText(
                        'noFavoritesListsAvailable',
                        languageCode: languageCode,
                      ),
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
                    final (listDTO, favoritesInThisList) =
                        listOfFavoriteLists[index];

                    final Object listID = listDTO.id;
                    final tileKey = _getTileKey(listID);
                    final tileController = _getTileController(listID);

                    return StatefulBuilder(
                      builder: (context, setTileState) {
                        final selectedCategories =
                            selectedCategoriesByList[listID] ?? <String>{};

                        final isFilterActive = selectedCategories.isNotEmpty;

                        return Container(
                          key: tileKey,
                          child: ExpansionTile(
                            key: ValueKey("favorites_$listID"),
                            controller: tileController,
                            maintainState: true,
                            tilePadding: const EdgeInsets.only(
                              left: 0,
                              right: 15,
                            ),
                            childrenPadding: EdgeInsets.zero,
                            collapsedShape: const Border(),
                            shape: const Border(),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            expandedAlignment: Alignment.topLeft,
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
                                  ...favoritesInThisList.map((favorite) {
                                    return Consumer(
                                      builder: (context, ref, child) {
                                        final poiAsync = ref.watch(
                                          poiByIdProvider(favorite.poiID),
                                        );

                                        return poiAsync.when(
                                          data: (poi) {
                                            if (poi == null) {
                                              return Padding(
                                                padding: EdgeInsets.zero,
                                                child: Text(getText('poiNotFound', languageCode: languageCode)
                                                  ,
                                                ),
                                              );
                                            }

                                            _cachePoi(listID: listID, poi: poi);

                                            final matchesFilter =
                                                _matchesCategoryFilter(
                                                  poi: poi,
                                                  selectedCategories:
                                                      selectedCategories,
                                                );

                                            if (!matchesFilter) {
                                              return const SizedBox.shrink();
                                            }

                                            return PoiListItem(
                                              selectEnabled: true,
                                              poi: poi,
                                              paddingLeft: 0,
                                              onTap: () {
                                                widget.onSelect(poi);
                                                widget.onClose();
                                              },
                                            );
                                          },
                                          loading: () {
                                            return const Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                          error: (error, stackTrace) {
                                            return Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text("Fehler: $error"),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  }),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 0,
                                      right: 15,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          tooltip: "Sichtbare POIs auswählen",
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          icon: const Iconify(
                                            Mdi.check_all,
                                            color: Colors.black87,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            final filteredPois =
                                                _getFilteredCachedPois(listID);

                                            ref
                                                .read(
                                                  poiSelectionProvider.notifier,
                                                )
                                                .setAll(filteredPois);
                                          },
                                        ),
                                        IconButton(
                                          tooltip: "Auswahl aufheben",
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          icon: const Iconify(
                                            Mdi.selection_remove,
                                            color: Colors.black87,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(
                                                  poiSelectionProvider.notifier,
                                                )
                                                .clear();
                                          },
                                        ),
                                        IconButton(
                                          tooltip: "Nach Kategorien filtern",
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(
                                            isFilterActive
                                                ? Icons.filter_alt
                                                : Icons.filter_alt_outlined,
                                            color: Colors.black87,
                                            size: 24,
                                          ),
                                          onPressed: () async {
                                            await _openCategoryFilter(
                                              context: context,
                                              listID: listID,
                                              setTileState: setTileState,
                                            );
                                            ref.invalidate(
                                              poiSelectionProvider,
                                            );
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
                          ),
                        );
                      },
                    );
                  }),
                );
              },
              loading: () {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              error: (error, stackTrace) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text("Fehler: $error"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in tileControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void _scrollToTile(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.scrollController.hasClients) {
        return;
      }

      final tileContext = key.currentContext;

      if (tileContext == null) {
        return;
      }

      final renderObject = tileContext.findRenderObject();

      if (renderObject is! RenderBox) {
        return;
      }

      final viewport = RenderAbstractViewport.of(renderObject);

      final targetOffset = viewport.getOffsetToReveal(renderObject, 0.0).offset;

      final scrollPosition = widget.scrollController.position;

      final adjustedOffset = (targetOffset - 80.0).clamp(
        scrollPosition.minScrollExtent,
        scrollPosition.maxScrollExtent,
      );

      widget.scrollController.animateTo(
        adjustedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _matchesCategoryFilter({
    required PointOfInterest poi,
    required Set<String> selectedCategories,
  }) {
    if (selectedCategories.isEmpty) {
      return true;
    }

    final poiCategories = poi.categories;

    if (poiCategories == null || poiCategories.isEmpty) {
      return false;
    }

    return poiCategories.any(selectedCategories.contains);
  }

  void _cachePoi({required Object listID, required PointOfInterest poi}) {
    final currentPois = favPoisByList[listID] ?? [];

    if (currentPois.any((currentPoi) => currentPoi.id == poi.id)) {
      return;
    }

    favPoisByList[listID] = [...currentPois, poi];
  }

  Set<String> _getAvailableCategories(Object listID) {
    final pois = favPoisByList[listID] ?? [];

    return pois
        .expand((poi) => poi.categories ?? const <String>[])
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();
  }

  List<PointOfInterest> _getFilteredCachedPois(Object listID) {
    final pois = favPoisByList[listID] ?? [];

    final selectedCategories = selectedCategoriesByList[listID] ?? <String>{};

    return pois
        .where((poi) {
          return _matchesCategoryFilter(
            poi: poi,
            selectedCategories: selectedCategories,
          );
        })
        .toList(growable: false);
  }

  Future<void> _openCategoryFilter({
    required BuildContext context,
    required Object listID,
    required StateSetter setTileState,
  }) async {
    final availableCategories = _getAvailableCategories(listID);

    final currentSelection = Set<String>.from(
      selectedCategoriesByList[listID] ?? <String>{},
    );

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return PoiListCategoryFilter(
          categories: availableCategories,
          initialCategories: currentSelection,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setTileState(() {
      if (result.isEmpty) {
        selectedCategoriesByList.remove(listID);
      } else {
        selectedCategoriesByList[listID] = Set<String>.from(result);
      }
    });
  }

  GlobalKey _getTileKey(Object listID) {
    return tileKeys.putIfAbsent(listID, GlobalKey.new);
  }

  ExpansibleController _getTileController(Object listID) {
    return tileControllers.putIfAbsent(listID, ExpansibleController.new);
  }
}
