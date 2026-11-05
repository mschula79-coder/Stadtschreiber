import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/categories_localized_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_counts_by_category_provider.dart';
import 'package:stadtschreiber/provider/poi_features_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/pois_for_categories_provider.dart';
import 'package:stadtschreiber/provider/radius_filtered_pois_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';

Future<void> showPoiCategoriesEditModal(
  BuildContext context, {
  required List<PointOfInterest> pois,
}) {
  if (pois.isEmpty) {
    return Future<void>.value();
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'POI categories',
    barrierColor: Colors.black54,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.transparent),
            Center(child: PoiCategoriesEditModal(pois: pois)),
          ],
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class PoiCategoriesEditModal extends ConsumerStatefulWidget {
  final List<PointOfInterest> pois;

  const PoiCategoriesEditModal({super.key, required this.pois});

  @override
  ConsumerState<PoiCategoriesEditModal> createState() {
    return _PoiCategoriesEditModalState();
  }
}

class _PoiCategoriesEditModalState
    extends ConsumerState<PoiCategoriesEditModal> {
  late List<PointOfInterest> _pois;

  final Set<String> _updatingCategories = <String>{};

  @override
  void initState() {
    super.initState();

    _pois = List<PointOfInterest>.from(widget.pois);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    final categories = ref.watch(localizedCategoriesProvider);

    final sortedCategories = List<LocalizedCategoryNode>.from(categories)
      ..sort(_compareCategoryNodes);

    final dialogSubtitle = _pois.length == 1
        ? _pois.first.name
        : '${_pois.length} Orte';

    return PointerInterceptor(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getText(
                              'editCategories',
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
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: _updatingCategories.isEmpty
                          ? () {
                              Navigator.of(context).pop();
                            }
                          : null,
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
                  child: sortedCategories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              getText(
                                'noCategoriesLoaded',
                                languageCode: locale.languageCode,
                                countryCode: locale.countryCode,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: sortedCategories
                              .map(
                                (root) => _PoiCategoryNodeTile(
                                  node: root,
                                  pois: _pois,
                                  updatingCategories: _updatingCategories,
                                  onChanged: _updateCategoryForAllPois,
                                  depth: 0,
                                ),
                              )
                              .toList(growable: false),
                        ),
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
                    if (_updatingCategories.isNotEmpty)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    TextButton(
                      onPressed: _updatingCategories.isEmpty
                          ? () {
                              Navigator.of(context).pop();
                              ref.invalidate(localizedCategoriesProvider);
                        
                              ref.invalidate(poiFeaturesProvider);

                              ref.invalidate(radiusFilteredPoisProvider);

                              ref.invalidate(poisForCategoriesProvider);

                              ref.invalidate(poiCountsByCategoryProvider);
                            }
                          : null,
                      child: Text(
                        getText(
                          'done',
                          languageCode: locale.languageCode,
                          countryCode: locale.countryCode,
                        ),
                      ),
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

  int _compareCategoryNodes(
    LocalizedCategoryNode first,
    LocalizedCategoryNode second,
  ) {
    final labelComparison = _normalizeSortLabel(
      first.label,
    ).compareTo(_normalizeSortLabel(second.label));

    if (labelComparison != 0) {
      return labelComparison;
    }

    return first.slug.compareTo(second.slug);
  }

  String _normalizeSortLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('œ', 'oe')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ÿ', 'y');
  }

  Future<void> _updateCategoryForAllPois(
    String categorySlug,
    bool enabled,
  ) async {
    if (_updatingCategories.contains(categorySlug)) {
      return;
    }

    setState(() {
      _updatingCategories.add(categorySlug);
    });

    try {
      final repository = ref.read(poiRepositoryProvider);

      final updateFutures = <Future<PointOfInterest>>[];

      for (final poi in _pois) {
        final currentCategories = poi.categories ?? const <String>[];

        final alreadyHasCategory = currentCategories.contains(categorySlug);

        if (alreadyHasCategory == enabled) {
          updateFutures.add(Future<PointOfInterest>.value(poi));

          continue;
        }

        updateFutures.add(
          repository.updatePoiCategory(
            poi: poi,
            category: categorySlug,
            enabled: enabled,
          ),
        );
      }

      final updatedPois = await Future.wait(updateFutures);

      if (!mounted) {
        return;
      }

      setState(() {
        _pois = updatedPois;
      });

      final selectedPoi = ref.read(selectedPoiProvider);

      if (selectedPoi != null) {
        for (final updatedPoi in updatedPois) {
          if (updatedPoi.id == selectedPoi.id) {
            ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);

            break;
          }
        }
      }

      if (updatedPois.length > 1) {
        ref.read(poiSelectionProvider.notifier).setAll(updatedPois);
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingCategories.remove(categorySlug);
        });
      }
    }
  }
}

class _PoiCategoryNodeTile extends StatelessWidget {
  final LocalizedCategoryNode node;
  final List<PointOfInterest> pois;
  final Set<String> updatingCategories;
  final Future<void> Function(String categorySlug, bool enabled) onChanged;
  final int depth;

  const _PoiCategoryNodeTile({
    required this.node,
    required this.pois,
    required this.updatingCategories,
    required this.onChanged,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final categorySlug = node.slug.trim();

    if (categorySlug.isEmpty) {
      return const SizedBox.shrink();
    }

    final leftPadding = depth * 10.0;

    if (node.children.isNotEmpty) {
      final sortedChildren = List<LocalizedCategoryNode>.from(node.children)
        ..sort(_compareCategoryNodes);

      return ExpansionTile(
        key: PageStorageKey<String>('poi-category-${node.id}'),
        controlAffinity: ListTileControlAffinity.leading,
        shape: const Border(),
        collapsedShape: const Border(),
        maintainState: true,
        visualDensity: VisualDensity.compact,
        tilePadding: EdgeInsets.only(left: leftPadding + 24, right: 12),
        childrenPadding: EdgeInsets.zero,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  node.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              getIcon(categorySlug, 24, null),
            ],
          ),
        ),
        children: sortedChildren
            .map(
              (child) => _PoiCategoryNodeTile(
                node: child,
                pois: pois,
                updatingCategories: updatingCategories,
                onChanged: onChanged,
                depth: depth + 1,
              ),
            )
            .toList(growable: false),
      );
    }

    final selectedCount = pois.where((poi) {
      return poi.categories?.contains(categorySlug) ?? false;
    }).length;

    final bool? checkboxValue;

    if (selectedCount == 0) {
      checkboxValue = false;
    } else if (selectedCount == pois.length) {
      checkboxValue = true;
    } else {
      checkboxValue = null;
    }

    final isUpdating = updatingCategories.contains(categorySlug);

    return CheckboxListTile(
      value: checkboxValue,
      tristate: true,
      checkboxScaleFactor: 0.7,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.only(left: leftPadding + 16, right: 12),
      title: Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(node.label)),
            const SizedBox(width: 6),
            if (isUpdating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              getIcon(categorySlug, 22, null),
          ],
        ),
      ),
      subtitle: pois.length > 1 && checkboxValue == null
          ? Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text('$selectedCount von ${pois.length}'),
            )
          : null,
      onChanged: isUpdating
          ? null
          : (_) async {
              await onChanged(categorySlug, checkboxValue != true);
            },
    );
  }

  int _compareCategoryNodes(
    LocalizedCategoryNode first,
    LocalizedCategoryNode second,
  ) {
    final labelComparison = _normalizeSortLabel(
      first.label,
    ).compareTo(_normalizeSortLabel(second.label));

    if (labelComparison != 0) {
      return labelComparison;
    }

    return first.slug.compareTo(second.slug);
  }

  String _normalizeSortLabel(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('æ', 'ae')
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ì', 'i')
        .replaceAll('í', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('œ', 'oe')
        .replaceAll('ù', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ÿ', 'y');
  }
}
