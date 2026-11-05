import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/user_favorite_lists_provider.dart';
import 'package:stadtschreiber/provider/user_favorites_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/modal_name_edit.dart';

class PoiFavoriteEditModal extends ConsumerStatefulWidget {
  final List<PointOfInterest> pois;

  const PoiFavoriteEditModal({super.key, required this.pois});

  @override
  ConsumerState<PoiFavoriteEditModal> createState() {
    return _PoiFavoriteEditModalState();
  }
}

class _PoiFavoriteEditModalState extends ConsumerState<PoiFavoriteEditModal> {
  bool _creatingList = false;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(supabaseUserStateProvider).userid;

    final locale = ref.watch(localeProvider);

    final dialogSubtitle = widget.pois.length == 1
        ? widget.pois.first.name
        : '${widget.pois.length} POIs';

    return PointerInterceptor(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.playlist_add),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getText(
                              'editFavorite',
                              languageCode: locale.languageCode,
                              countryCode: locale.countryCode,
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dialogSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _creatingList
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    dividerTheme: const DividerThemeData(
                      color: Colors.transparent,
                      space: 0,
                      thickness: 0,
                    ),
                    listTileTheme: const ListTileThemeData(
                      horizontalTitleGap: 4,
                      minLeadingWidth: 24,
                    ),
                  ),
                  child: FavoriteListSelectionList(pois: widget.pois),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _creatingList
                          ? null
                          : () async {
                              await _createList(
                                context: context,
                                userId: userId,
                              );
                            },
                      icon: _creatingList
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(
                        getText(
                          'newList',
                          languageCode: locale.languageCode,
                          countryCode: locale.countryCode,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _creatingList
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createList({
    required BuildContext context,
    required String userId,
  }) async {
    final listName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const NameEditModal(initialName: '');
      },
    );

    final normalizedListName = listName?.trim() ?? '';

    if (normalizedListName.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _creatingList = true;
    });

    try {
      await ref.read(createFavoriteListProvider)(
        listName: normalizedListName,
        userId: userId,
      );

      ref.invalidate(userFavoriteListsProvider(userId));

      ref.invalidate(userFavoritesProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Die Liste konnte nicht erstellt werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingList = false;
        });
      }
    }
  }
}

class FavoriteListSelectionList extends ConsumerStatefulWidget {
  final List<PointOfInterest> pois;

  const FavoriteListSelectionList({super.key, required this.pois});

  @override
  ConsumerState<FavoriteListSelectionList> createState() {
    return _FavoriteListSelectionListState();
  }
}

class _FavoriteListSelectionListState
    extends ConsumerState<FavoriteListSelectionList> {
  final Set<String> _updatingListIds = <String>{};

  final Map<String, Set<String>> _optimisticPoiIdsByList =
      <String, Set<String>>{};

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(supabaseUserStateProvider).userid;

    final favoriteListsAsync = ref.watch(userFavoriteListsProvider(userId));

    final selectedPoiIds = widget.pois
        .map((poi) => poi.id.trim())
        .where((poiId) => poiId.isNotEmpty)
        .toSet();

    return favoriteListsAsync.when(
      data: (favoriteLists) {
        if (favoriteLists.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Noch keine Listen vorhanden.'),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: favoriteLists
              .map((favoriteList) {
                final listDto = favoriteList.list;

                final loadedFavoritePoiIds = favoriteList.pois
                    .map((poi) => poi.id.trim())
                    .where((poiId) => poiId.isNotEmpty)
                    .toSet();

                final favoritePoiIds =
                    _optimisticPoiIdsByList[listDto.id] ?? loadedFavoritePoiIds;

                final selectedCount = selectedPoiIds
                    .where(favoritePoiIds.contains)
                    .length;

                final bool? checkboxValue;

                if (selectedCount == 0) {
                  checkboxValue = false;
                } else if (selectedCount == selectedPoiIds.length) {
                  checkboxValue = true;
                } else {
                  checkboxValue = null;
                }

                final isUpdating = _updatingListIds.contains(listDto.id);

                return CheckboxListTile(
                  value: checkboxValue,
                  tristate: true,
                  checkboxScaleFactor: 0.8,
                  controlAffinity: ListTileControlAffinity.leading,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.only(left: 16, right: 12),
                  title: Text(listDto.name),
                  subtitle: widget.pois.length > 1 && checkboxValue == null
                      ? Text('$selectedCount von ${widget.pois.length}')
                      : null,
                  secondary: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          checkboxValue == true
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                        ),
                  onChanged: isUpdating
                      ? null
                      : (_) async {
                          await _setListMembership(
                            listId: listDto.id,
                            add: checkboxValue != true,
                            userId: userId,
                            currentFavoritePoiIds: favoritePoiIds,
                            selectedPoiIds: selectedPoiIds,
                          );
                        },
                );
              })
              .toList(growable: false),
        );
      },
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Future<void> _setListMembership({
    required String listId,
    required bool add,
    required String userId,
    required Set<String> currentFavoritePoiIds,
    required Set<String> selectedPoiIds,
  }) async {
    if (_updatingListIds.contains(listId)) {
      return;
    }

    final normalizedListId = listId.trim();

    if (normalizedListId.isEmpty || selectedPoiIds.isEmpty) {
      return;
    }

    final originalPoiIds = Set<String>.from(currentFavoritePoiIds);

    final optimisticPoiIds = Set<String>.from(currentFavoritePoiIds);

    if (add) {
      optimisticPoiIds.addAll(selectedPoiIds);
    } else {
      optimisticPoiIds.removeAll(selectedPoiIds);
    }

    setState(() {
      _updatingListIds.add(normalizedListId);

      _optimisticPoiIdsByList[normalizedListId] = optimisticPoiIds;
    });

    try {
      final toggleFavorite = ref.read(toggleFavoriteProvider);

      await Future.wait<void>(
        selectedPoiIds.map((poiId) async {
          final currentlyInList = originalPoiIds.contains(poiId);

          if (currentlyInList == add) {
            return;
          }

          await toggleFavorite(
            poiId: poiId,
            listId: normalizedListId,
            add: add,
          );
        }),
      );

      ref.invalidate(userFavoriteListsProvider(userId));

      ref.invalidate(userFavoritesProvider);
    } catch (error) {
      if (mounted) {
        setState(() {
          _optimisticPoiIdsByList[normalizedListId] = originalPoiIds;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Die Favoriten konnten nicht aktualisiert werden: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingListIds.remove(normalizedListId);
        });
      }
    }
  }
}
