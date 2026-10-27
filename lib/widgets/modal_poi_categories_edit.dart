import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/categories_localized_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
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
    pageBuilder: (
      dialogContext,
      animation,
      secondaryAnimation,
    ) {
      return PointerInterceptor(
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(
                color: Colors.transparent,
              ),
              Center(
                child: PoiCategoriesEditModal(
                  pois: pois,
                ),
              ),
            ],
          ),
        ),
      );
    },
    transitionBuilder: (
      context,
      animation,
      secondaryAnimation,
      child,
    ) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

class PoiCategoriesEditModal
    extends ConsumerStatefulWidget {
  final List<PointOfInterest> pois;

  const PoiCategoriesEditModal({
    super.key,
    required this.pois,
  });

  @override
  ConsumerState<PoiCategoriesEditModal>
  createState() {
    return _PoiCategoriesEditModalState();
  }
}

class _PoiCategoriesEditModalState
    extends ConsumerState<PoiCategoriesEditModal> {
  late List<PointOfInterest> _pois;

  final Set<String> _updatingCategories =
      <String>{};

  @override
  void initState() {
    super.initState();

    _pois = List<PointOfInterest>.from(
      widget.pois,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    final categories = ref.watch(
      localizedCategoriesProvider,
    );

    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          children: [
            Material(
              color: Theme.of(
                context,
              ).colorScheme.surface,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.category_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            getText(
                              'editCategories',
                              languageCode:
                                  locale.languageCode,
                              countryCode:
                                  locale.countryCode,
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge,
                          ),
                          Text(
                            _pois.length == 1
                                ? _pois.first.name
                                : '${_pois.length} Orte',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                      onPressed:
                          _updatingCategories.isEmpty
                          ? () {
                              Navigator.of(
                                context,
                              ).pop();
                            }
                          : null,
                      icon: const Icon(Icons.close),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(24),
                        child: Text(
                          getText(
                            'noCategoriesLoaded',
                            languageCode:
                                locale.languageCode,
                            countryCode:
                                locale.countryCode,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                      children: categories.map((root) {
                        return _PoiCategoryNodeTile(
                          node: root,
                          pois: _pois,
                          updatingCategories:
                              _updatingCategories,
                          onChanged:
                              _updateCategoryForAllPois,
                        );
                      }).toList(),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _updatingCategories.isEmpty
                        ? () {
                            Navigator.of(
                              context,
                            ).pop();
                          }
                        : null,
                    child: Text(
                      getText(
                        'close',
                        languageCode:
                            locale.languageCode,
                        countryCode:
                            locale.countryCode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateCategoryForAllPois(
    String categorySlug,
    bool enabled,
  ) async {
    if (_updatingCategories.contains(
      categorySlug,
    )) {
      return;
    }

    setState(() {
      _updatingCategories.add(categorySlug);
    });

    try {
      final repository = ref.read(
        poiRepositoryProvider,
      );

      final updateFutures =
          <Future<PointOfInterest>>[];

      for (final poi in _pois) {
        final currentCategories =
            poi.categories ?? const <String>[];

        final alreadyHasCategory =
            currentCategories.contains(
              categorySlug,
            );

        if (alreadyHasCategory == enabled) {
          updateFutures.add(
            Future<PointOfInterest>.value(poi),
          );

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

      final updatedPois = await Future.wait(
        updateFutures,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pois = updatedPois;
      });

      final selectedPoi = ref.read(
        selectedPoiProvider,
      );

      if (selectedPoi != null) {
        for (final updatedPoi in updatedPois) {
          if (updatedPoi.id == selectedPoi.id) {
            ref
                .read(
                  selectedPoiProvider.notifier,
                )
                .setPoi(updatedPoi);

            break;
          }
        }
      }

      if (updatedPois.length > 1) {
        ref
            .read(
              poiSelectionProvider.notifier,
            )
            .setAll(updatedPois);
      }

      ref.invalidate(
        poiCountForCategoryProvider(
          categorySlug,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingCategories.remove(
            categorySlug,
          );
        });
      }
    }
  }
}

class _PoiCategoryNodeTile
    extends StatelessWidget {
  final LocalizedCategoryNode node;
  final List<PointOfInterest> pois;
  final Set<String> updatingCategories;
  final Future<void> Function(
    String categorySlug,
    bool enabled,
  )
  onChanged;

  const _PoiCategoryNodeTile({
    required this.node,
    required this.pois,
    required this.updatingCategories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (node.children.isNotEmpty) {
      return ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(
          left: 12,
        ),
        visualDensity: VisualDensity.compact,
        leading: getIcon(
          node.slug,
          28,
          null,
        ),
        title: Text(
          node.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: node.children.map((child) {
          return _PoiCategoryNodeTile(
            node: child,
            pois: pois,
            updatingCategories:
                updatingCategories,
            onChanged: onChanged,
          );
        }).toList(),
      );
    }

    final categorySlug = node.slug;

    if (categorySlug.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedCount = pois.where((poi) {
      return poi.categories?.contains(
            categorySlug,
          ) ??
          false;
    }).length;

    final bool? checkboxValue;

    if (selectedCount == 0) {
      checkboxValue = false;
    } else if (selectedCount == pois.length) {
      checkboxValue = true;
    } else {
      checkboxValue = null;
    }

    final isUpdating =
        updatingCategories.contains(
          categorySlug,
        );

    return CheckboxListTile(
      value: checkboxValue,
      tristate: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      controlAffinity:
          ListTileControlAffinity.leading,
      secondary: isUpdating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : getIcon(
              categorySlug,
              24,
              null,
            ),
      title: Text(node.label),
      subtitle:
          pois.length > 1 &&
              checkboxValue == null
          ? Text(
              '$selectedCount von ${pois.length}',
            )
          : null,
      onChanged: isUpdating
          ? null
          : (_) async {
              await onChanged(
                categorySlug,
                checkboxValue != true,
              );
            },
    );
  }
}