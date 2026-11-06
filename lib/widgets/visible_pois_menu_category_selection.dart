import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/models/localized_feature_node.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_localized_provider.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_counts_by_category_provider.dart';
import 'package:stadtschreiber/provider/search_radius_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/utils/category_localization_utils.dart';
import 'package:stadtschreiber/utils/dialog_utils.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/modal_categories_list_edit.dart';
import 'package:stadtschreiber/widgets/modal_rating_criteria_edit.dart';
import 'package:uuid/uuid.dart';
import 'package:stadtschreiber/provider/feature_filter_provider.dart';
import 'package:stadtschreiber/provider/features_for_category_provider.dart';
import 'package:stadtschreiber/widgets/modal_feature_filter.dart';

class PoiCategorySelection extends ConsumerStatefulWidget {
  const PoiCategorySelection({super.key});

  @override
  ConsumerState<PoiCategorySelection> createState() {
    return _PoiCategorySelectionState();
  }
}

class _PoiCategorySelectionState extends ConsumerState<PoiCategorySelection> {
  final TextEditingController _categoryFilterController =
      TextEditingController();

  final ExpansibleController expansionController = ExpansibleController();

  String _categoryFilter = '';

  bool isFilterActive = false;
  bool expandAll = false;
  bool isAdminViewEnabled = false;

  PoiSelectionMode? _lastMode;

  @override
  void dispose() {
    _categoryFilterController.dispose();
    expansionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    final categories = ref.watch(localizedCategoriesProvider);

    final isAdmin = ref.watch(
      supabaseUserStateProvider.select((state) => state.isAdmin),
    );

    final mode = ref.watch(
      visiblePoisMenuStateProvider.select((state) => state.poiSelectionMode),
    );

    final searchRadiusKm = ref.watch(searchRadiusKmProvider);

    final poiCountsAsync = ref.watch(poiCountsByCategoryProvider);

    final poiCounts = poiCountsAsync.asData?.value ?? const <String, int>{};

    final poiCountsLoading = poiCountsAsync.isLoading;

    final poiCountsError = poiCountsAsync.asError?.error;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastMode == mode) {
        return;
      }

      if (mode == PoiSelectionMode.categories) {
        expansionController.expand();
      } else {
        expansionController.collapse();
      }

      _lastMode = mode;
    });

    final sortedRootCategories = CategoryLocalizationUtils.sortLocalizedNodes(
      categories,
      useSortOrder: true,
    );

    final filteredCategories = _filterCategoryTree(
      sortedRootCategories,
      _categoryFilter,
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
          key: const ValueKey('categories_tile'),
          tilePadding: const EdgeInsets.only(left: 0, right: 15),
          childrenPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,
          controller: expansionController,
          collapsedShape: const Border(),
          shape: const Border(),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          onExpansionChanged: (value) {
            ref
                .read(visiblePoisMenuStateProvider.notifier)
                .setTileExpanded('categories', value);

            if (value) {
              ref
                  .read(visiblePoisMenuStateProvider.notifier)
                  .setPoiSelectionMode(PoiSelectionMode.categories);
            }
          },
          title: Row(
            children: [
              Icon(Icons.category, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getText(
                    'categories',
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
            Container(
              padding: const EdgeInsets.fromLTRB(6, 0, 4, 0),
              margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryFilterController,
                      decoration: InputDecoration(
                        hintText: getText(
                          'filterCategories',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _categoryFilter =
                              CategoryLocalizationUtils.normalizeLabel(value);

                          expandAll = _categoryFilter.isNotEmpty;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (isFilterActive) {
                          _categoryFilter = '';
                          _categoryFilterController.clear();
                          expandAll = false;
                        }

                        isFilterActive = !isFilterActive;
                      });
                    },
                    icon: Icon(
                      isFilterActive ? Icons.filter_alt_off : Icons.filter_alt,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.radar, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      getText(
                        'searchRadius',
                        languageCode: languageCode,
                        countryCode: countryCode,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<double>(
                      initialValue: searchRadiusKm,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: _searchRadiusOptions.map((radiusKm) {
                        final label = radiusKm < 1
                            ? '${(radiusKm * 1000).round()} m'
                            : '${radiusKm.toInt()} km';

                        return DropdownMenuItem<double>(
                          value: radiusKm,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (radiusKm) {
                        if (radiusKm == null) {
                          return;
                        }

                        ref
                            .read(searchRadiusKmProvider.notifier)
                            .setRadius(radiusKm);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            if (poiCountsError != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        poiCountsError.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ...filteredCategories.map(
              (node) => _buildCategoryNode(
                context,
                ref,
                node,
                depth: 0,
                languageCode: languageCode,
                countryCode: countryCode,
                poiCounts: poiCounts,
                poiCountsLoading: poiCountsLoading,
              ),
            ),

            if (isAdmin)
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(
                  getText(
                    'editCategories',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                ),
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return const Dialog(
                        child: SizedBox(width: 600, child: CategoryEditor()),
                      );
                    },
                  );
                },
              ),
            if (isAdmin)
              SwitchListTile(
                title: const Text(
                  'Bewertungskriterien bearbeiten',
                  style: TextStyle(fontSize: 16),
                ),
                tileColor: Colors.white,
                contentPadding: const EdgeInsets.only(top: 10),
                value: isAdminViewEnabled,
                onChanged: (newValue) {
                  setState(() {
                    isAdminViewEnabled = newValue;
                  });
                },
              ),
            if (isAdminViewEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: ref
                    .watch(globalCriteriaProvider)
                    .when(
                      data: (ratingCriteria) {
                        return EditableList<RatingCriterionDTO>(
                          items: ratingCriteria,
                          isEditModeEnabled: true,
                          itemBuilder: (entry) {
                            return Padding(
                              padding: EdgeInsets.zero,
                              child: Text(
                                entry.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          },
                          onDelete: (entry) async {
                            final confirmed = await openConfirmDialog(
                              context,
                              message:
                                  'Dies löscht das Kriterium ${entry.name} für alle Kategorien. Willst du das?',
                              optionTrue: 'Ja',
                              optionFalse: 'Nein',
                            );

                            if (confirmed != true) {
                              return;
                            }

                            await ref
                                .read(categoriesRepositoryProvider)
                                .deleteCriterion(entry);

                            ref.invalidate(globalCriteriaProvider);
                          },
                          onAdd: () async {
                            final emptyCriterion = RatingCriterionDTO(
                              id: const Uuid().v4(),
                              name: '',
                              description: '',
                            );

                            final emptyCriterionWithId = await ref
                                .read(categoriesRepositoryProvider)
                                .newCriterion(emptyCriterion);

                            if (!context.mounted) {
                              return null;
                            }

                            final newCriterion =
                                await showDialog<RatingCriterionDTO>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) {
                                    return RatingCriteriaEditModal(
                                      criterionDTO: emptyCriterionWithId,
                                    );
                                  },
                                );

                            if (newCriterion == null) {
                              return null;
                            }

                            await ref
                                .read(categoriesRepositoryProvider)
                                .updateCriterion(newCriterion);

                            ref.invalidate(globalCriteriaProvider);

                            return newCriterion;
                          },
                          onEdit: (entry) async {
                            final edited = await showDialog<RatingCriterionDTO>(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) {
                                return RatingCriteriaEditModal(
                                  criterionDTO: entry,
                                );
                              },
                            );

                            if (edited == null) {
                              return null;
                            }

                            await ref
                                .read(categoriesRepositoryProvider)
                                .updateCriterion(edited);

                            ref.invalidate(globalCriteriaProvider);

                            return edited;
                          },
                        );
                      },
                      loading: () {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      error: (error, stackTrace) {
                        return Text(
                          '${getText('error', languageCode: languageCode, countryCode: countryCode)}: $error',
                        );
                      },
                    ),
              ),
          ],
        ),
      ),
    );
  }

  List<LocalizedCategoryNode> _filterCategoryTree(
    List<LocalizedCategoryNode> nodes,
    String filter,
  ) {
    if (filter.isEmpty) {
      return nodes;
    }

    final result = <LocalizedCategoryNode>[];

    for (final node in nodes) {
      final normalizedLabel = CategoryLocalizationUtils.normalizeLabel(
        node.label,
      );

      final labelMatches = normalizedLabel.contains(filter);

      if (node.isLeaf) {
        if (labelMatches) {
          result.add(node);
        }

        continue;
      }

      final filteredChildren = _filterCategoryTree(node.children, filter);

      if (labelMatches || filteredChildren.isNotEmpty) {
        result.add(
          LocalizedCategoryNode(
            id: node.id,
            slug: node.slug,
            label: node.label,
            sortOrder: node.sortOrder,
            labels: node.labels,
            children: filteredChildren,
            hasParents: node.hasParents,
          ),
        );
      }
    }

    return result;
  }

  Widget _buildCategoryNode(
    BuildContext context,
    WidgetRef ref,
    LocalizedCategoryNode node, {
    required int depth,
    required String languageCode,
    required String? countryCode,
    required Map<String, int> poiCounts,
    required bool poiCountsLoading,
  }) {
    final categorySlug = node.slug.trim();

    if (categorySlug.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSelected = ref.watch(
      categoriesSelectionProvider.select(
        (state) => state.isSelected(categorySlug),
      ),
    );

    final isAdmin = ref.watch(
      supabaseUserStateProvider.select((state) => state.isAdmin),
    );

    final poiCount = poiCounts[categorySlug];

    final hasLoadedCount = poiCount != null;

    final isSelectable = isSelected || !hasLoadedCount || poiCount > 0;

    final disabledColor = Theme.of(context).disabledColor;

    final leftPadding = depth * 10.0;

    void setSelected(bool selected) {
      ref
          .read(categoriesSelectionProvider.notifier)
          .setSelected(categorySlug, selected);
    }

    Widget buildCount() {
      if (!isAdmin) {
        return const SizedBox.shrink();
      }

      if (poiCount == null) {
        return const SizedBox.shrink();
      }

      return Text(
        '($poiCount)',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: poiCount > 0 ? null : disabledColor,
        ),
      );
    }

    Widget buildTitle({required double iconSize}) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            node.label,
            style: TextStyle(
              fontSize: 16,
              color: isSelectable ? null : disabledColor,
            ),
          ),
          Opacity(
            opacity: isSelectable ? 1 : 0.38,
            child: getIcon(categorySlug, iconSize, null),
          ),
          buildCount(),
        ],
      );
    }

    Widget buildFeatureButton() {
      final featuresAsync = ref.watch(
        featuresForCategoryProvider(categorySlug),
      );

      return featuresAsync.when(
        data: (features) {
          if (features.isEmpty) {
            return const SizedBox.shrink();
          }

          final selectedFeatureSlugs = ref.watch(featureFilterProvider);

          final selectedCount = selectedFeatureSlugs.length;

          return Padding(
            padding: EdgeInsets.only(
              left: leftPadding + 48,
              right: 15,
              bottom: 6,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.tune, size: 18),
                label: Text(
                  selectedCount == 0
                      ? getText(
                          'filterFeatures',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        )
                      : '${getText('filterFeatures', languageCode: languageCode, countryCode: countryCode)} ($selectedCount)',
                ),
                onPressed: () {
                  _openFeatureFilterDialog(
                    context: context,
                    categorySlug: categorySlug,
                    categoryLabel: node.label,
                    features: features,
                  );
                },
              ),
            ),
          );
        },
        loading: () {
          return const SizedBox.shrink();
        },
        error: (error, stackTrace) {
          return const SizedBox.shrink();
        },
      );
    }

    if (node.children.isNotEmpty) {
      return ExpansionTile(
        key: PageStorageKey<String>(
          'category-${node.id}-${expandAll ? 'expanded' : 'collapsed'}',
        ),
        tilePadding: EdgeInsets.only(left: leftPadding, right: 15),
        childrenPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        initiallyExpanded: expandAll,
        controlAffinity: ListTileControlAffinity.trailing,
        leading: Checkbox(
          value: isSelected,
          onChanged: isSelectable
              ? (value) {
                  setSelected(value ?? false);
                }
              : null,
        ),
        title: buildTitle(iconSize: 28),
        children: [
          buildFeatureButton(),
          ...node.children.map((child) {
            return _buildCategoryNode(
              context,
              ref,
              child,
              depth: depth + 1,
              languageCode: languageCode,
              countryCode: countryCode,
              poiCounts: poiCounts,
              poiCountsLoading: poiCountsLoading,
            );
          }),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.only(left: leftPadding, right: 15),
          value: isSelected,
          tileColor: Colors.white,
          visualDensity: VisualDensity.compact,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: isSelectable
              ? (value) {
                  setSelected(value ?? false);
                }
              : null,
          title: buildTitle(iconSize: 24),
        ),
        buildFeatureButton(),
      ],
    );
  }

  static const List<double> _searchRadiusOptions = [
    0.5,
    1,
    2,
    3,
    5,
    10,
    20,
    30,
  ];

  Future<void> _openFeatureFilterDialog({
    required BuildContext context,
    required String categorySlug,
    required String categoryLabel,
    required List<LocalizedFeatureNode> features,
  }) async {
    final selectedFeatureSlugs = ref.read(featureFilterProvider);

    final availableLeafSlugs = <String>{};

    void collectLeafSlugs(List<LocalizedFeatureNode> nodes) {
      for (final node in nodes) {
        if (node.children.isEmpty) {
          availableLeafSlugs.add(node.slug);
        } else {
          collectLeafSlugs(node.children);
        }
      }
    }

    collectLeafSlugs(features);

    final applicableSelection = selectedFeatureSlugs
        .where(availableLeafSlugs.contains)
        .toSet();

    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    final result = await showDialog<Set<String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return FeatureFilterDialog(
          dialogTitle: getText(
            'filterFeatures',
            languageCode: languageCode,
            countryCode: countryCode,
          ),
          categoryLabel: categoryLabel,
          features: features,
          initiallySelectedSlugs: applicableSelection,
        );
      },
    );

    if (result == null) {
      return;
    }

    ref.read(featureFilterProvider.notifier).replaceAll(result);
  }
}
