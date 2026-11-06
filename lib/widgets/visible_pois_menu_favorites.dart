import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorite_lists_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/modal_confirm_box.dart';
import 'package:stadtschreiber/widgets/modal_poi_list_categories_filter.dart';
import 'package:stadtschreiber/widgets/poi_list_action_row.dart';
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
  ConsumerState<PoiFavoritesList> createState() {
    return _PoiFavoritesListState();
  }
}

class _PoiFavoritesListState extends ConsumerState<PoiFavoritesList> {
  final Map<Object, List<PointOfInterest>> favPoisByList =
      <Object, List<PointOfInterest>>{};

  final Map<Object, Set<String>> selectedCategoriesByList =
      <Object, Set<String>>{};

  final Map<Object, GlobalKey> tileKeys = <Object, GlobalKey>{};

  final Map<Object, ExpansibleController> tileControllers =
      <Object, ExpansibleController>{};

  final Set<Object> expandedListIds = <Object>{};

  final Set<Object> deletingListIds = <Object>{};

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(supabaseUserStateProvider).userid;

    final locale = ref.watch(localeProvider);

    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    final favoriteListsAsync = ref.watch(
      userFavoriteListHeadersProvider(userId),
    );

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
                .setTileExpanded('favorites', expanded);

            if (expanded) {
              ref
                  .read(visiblePoisMenuStateProvider.notifier)
                  .setPoiSelectionMode(PoiSelectionMode.favorites);
            }
          },
          title: Row(
            children: [
              Iconify(Mdi.bookmark, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getText(
                    'favorites',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            favoriteListsAsync.when(
              data: (favoriteLists) {
                if (favoriteLists.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.zero,
                    child: Text(
                      getText(
                        'noFavoritesListsAvailable',
                        languageCode: languageCode,
                        countryCode: countryCode,
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
                  children: favoriteLists
                      .map((listDto) {
                        final Object listId = listDto.id;

                        final tileKey = _getTileKey(listId);

                        final tileController = _getTileController(listId);

                        final isExpanded = expandedListIds.contains(listId);

                        final isDeleting = deletingListIds.contains(listId);

                        return StatefulBuilder(
                          builder: (context, setTileState) {
                            final selectedCategories =
                                selectedCategoriesByList[listId] ?? <String>{};

                            final isFilterActive =
                                selectedCategories.isNotEmpty;

                            return Container(
                              key: tileKey,
                              child: ExpansionTile(
                                key: ValueKey<String>('favorites_$listId'),
                                controller: tileController,
                                enabled: !isDeleting,
                                maintainState: false,
                                leading: isDeleting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Iconify(
                                        Mdi.playlist_check,
                                        color: Colors.black87,
                                        size: 18,
                                      ),
                                tilePadding: const EdgeInsets.only(
                                  left: 5,
                                  right: 15,
                                ),
                                childrenPadding: const EdgeInsets.only(left: 6),
                                collapsedShape: const Border(),
                                shape: const Border(),
                                expandedCrossAxisAlignment:
                                    CrossAxisAlignment.start,
                                expandedAlignment: Alignment.topLeft,
                                title: Text(
                                  '  ${listDto.name}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                children: isExpanded
                                    ? <Widget>[
                                        _buildFavoriteListContent(
                                          context: context,
                                          listId: listId,
                                          listName: listDto.name,
                                          userId: userId,
                                          languageCode: languageCode,
                                          countryCode: countryCode,
                                          selectedCategories:
                                              selectedCategories,
                                          isFilterActive: isFilterActive,
                                          setTileState: setTileState,
                                        ),
                                      ]
                                    : const <Widget>[],
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    if (expanded) {
                                      expandedListIds.add(listId);
                                    } else {
                                      expandedListIds.remove(listId);
                                    }
                                  });

                                  if (expanded) {
                                    _scrollToTile(tileKey);
                                  }
                                },
                              ),
                            );
                          },
                        );
                      })
                      .toList(growable: false),
                );
              },
              loading: () {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              error: (error, stackTrace) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Fehler: $error'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteListContent({
    required BuildContext context,
    required Object listId,
    required String listName,
    required String userId,
    required String languageCode,
    required String? countryCode,
    required Set<String> selectedCategories,
    required bool isFilterActive,
    required StateSetter setTileState,
  }) {
    final poisAsync = ref.watch(favoritePoisForListProvider(listId.toString()));

    return poisAsync.when(
      loading: () {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      error: (error, stackTrace) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Fehler: $error'),
        );
      },
      data: (poisInThisList) {
        favPoisByList[listId] = poisInThisList;

        final filteredPois = poisInThisList
            .where(
              (poi) => _matchesCategoryFilter(
                poi: poi,
                selectedCategories: selectedCategories,
              ),
            )
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (filteredPois.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Keine passenden POIs vorhanden.'),
              )
            else
              PoiListActionRow(
                isFilterActive: isFilterActive,
                isDeleting: deletingListIds.contains(listId),
                showDelete: true,
                selectAllTooltip: 'Sichtbare POIs auswählen',
                clearSelectionTooltip: 'Auswahl aufheben',
                filterTooltip: 'Nach Kategorien filtern',
                deleteTooltip: getText(
                  'deleteList',
                  languageCode: languageCode,
                  countryCode: countryCode,
                ),
                onSelectAll: filteredPois.isEmpty
                    ? null
                    : () {
                        ref
                            .read(poiSelectionProvider.notifier)
                            .setAll(filteredPois);
                      },
                onClearSelection: () {
                  ref.read(poiSelectionProvider.notifier).clear();
                },
                onFilter: () async {
                  await _openCategoryFilter(
                    context: context,
                    listId: listId,
                    setTileState: setTileState,
                  );
                },
                onDelete: () async {
                  await _deleteFavoriteList(
                    context: context,
                    listId: listId,
                    listName: listName,
                    userId: userId,
                    languageCode: languageCode,
                    countryCode: countryCode,
                  );
                },
              ),
            ...filteredPois.map(
              (poi) => PoiListItem(
                selectEnabled: true,
                poi: poi,
                paddingLeft: 0,
                onTap: () {
                  widget.onSelect(poi);
                  widget.onClose();
                },
              ),
            ),
            PoiListActionRow(
              isFilterActive: isFilterActive,
              isDeleting: deletingListIds.contains(listId),
              showDelete: true,
              selectAllTooltip: 'Sichtbare POIs auswählen',
              clearSelectionTooltip: 'Auswahl aufheben',
              filterTooltip: 'Nach Kategorien filtern',
              deleteTooltip: getText(
                'deleteList',
                languageCode: languageCode,
                countryCode: countryCode,
              ),
              onSelectAll: filteredPois.isEmpty
                  ? null
                  : () {
                      ref
                          .read(poiSelectionProvider.notifier)
                          .setAll(filteredPois);
                    },
              onClearSelection: () {
                ref.read(poiSelectionProvider.notifier).clear();
              },
              onFilter: () async {
                await _openCategoryFilter(
                  context: context,
                  listId: listId,
                  setTileState: setTileState,
                );
              },
              onDelete: () async {
                await _deleteFavoriteList(
                  context: context,
                  listId: listId,
                  listName: listName,
                  userId: userId,
                  languageCode: languageCode,
                  countryCode: countryCode,
                );
              },
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Future<void> _deleteFavoriteList({
    required BuildContext context,
    required Object listId,
    required String listName,
    required String userId,
    required String languageCode,
    required String? countryCode,
  }) async {
    if (deletingListIds.contains(listId)) {
      return;
    }

    final confirmed = await confirmBox(
      context,
      '${getText('confirmDeletionOfList1', languageCode: languageCode, countryCode: countryCode)}, $listName ${getText('confirmDeletionOfList2', languageCode: languageCode, countryCode: countryCode)}',
      getText(
        'deleteList',
        languageCode: languageCode,
        countryCode: countryCode,
      ),
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      deletingListIds.add(listId);
    });

    try {
      await ref.read(deleteFavoriteListProvider)(
        listId: listId.toString(),
        userId: userId,
      );

      expandedListIds.remove(listId);
      favPoisByList.remove(listId);
      selectedCategoriesByList.remove(listId);

      ref.invalidate(favoritePoisForListProvider(listId.toString()));

      ref.invalidate(userFavoriteListHeadersProvider(userId));

      ref.read(poiSelectionProvider.notifier).clear();
    } catch (error) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Die Liste konnte nicht gelöscht werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          deletingListIds.remove(listId);
        });
      }
    }
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

  Set<String> _getAvailableCategories(Object listId) {
    final pois = favPoisByList[listId] ?? const <PointOfInterest>[];

    return pois
        .expand((poi) => poi.categories ?? const <String>[])
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toSet();
  }

  Future<void> _openCategoryFilter({
    required BuildContext context,
    required Object listId,
    required StateSetter setTileState,
  }) async {
    final availableCategories = _getAvailableCategories(listId);

    final currentSelection = Set<String>.from(
      selectedCategoriesByList[listId] ?? <String>{},
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

    if (!context.mounted || result == null) {
      return;
    }

    setTileState(() {
      if (result.isEmpty) {
        selectedCategoriesByList.remove(listId);
      } else {
        selectedCategoriesByList[listId] = Set<String>.from(result);
      }
    });
  }

  GlobalKey _getTileKey(Object listId) {
    return tileKeys.putIfAbsent(listId, GlobalKey.new);
  }

  ExpansibleController _getTileController(Object listId) {
    return tileControllers.putIfAbsent(listId, ExpansibleController.new);
  }
}
