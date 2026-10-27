import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_localized_provider.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
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
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 0, right: 15),
          childrenPadding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,
          controller: expansionController,
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
            ...filteredCategories.map(
              (node) => _buildCategoryNode(context, ref, node),
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
    LocalizedCategoryNode node,
  ) {
    final categoryCheckboxesState = ref.watch(categoriesSelectionProvider);

    if (!node.isLeaf) {
      final leftPadding = node.hasParents ? 10.0 : 0.0;

      return ExpansionTile(
        key: PageStorageKey<String>(
          'category-${node.id}-${expandAll ? 'expanded' : 'collapsed'}',
        ),
        tilePadding: EdgeInsets.only(left: leftPadding, right: 15),
        childrenPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        initiallyExpanded: expandAll,
        leading: getIcon(node.slug, 28, null),
        title: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                node.label,
                softWrap: true,
                maxLines: null,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        children: node.children.map((child) {
          return _buildCategoryNode(context, ref, child);
        }).toList(),
      );
    }

    final categorySlug = node.slug.trim();

    if (categorySlug.isEmpty) {
      return const SizedBox.shrink();
    }

    final isChecked = categoryCheckboxesState.isSelected(categorySlug);

    final isAdmin = ref.watch(
      supabaseUserStateProvider.select((state) => state.isAdmin),
    );

    final poiCountAsync = ref.watch(poiCountForCategoryProvider(categorySlug));

    final poiCount = poiCountAsync.asData?.value;

    final isCheckboxEnabled = poiCount != null && poiCount > 0;

    final disabledColor = Theme.of(context).disabledColor;

    return CheckboxListTile(
      contentPadding: const EdgeInsets.only(top: 0, left: 4, right: 15),
      value: isChecked,
      tileColor: Colors.white,
      visualDensity: VisualDensity.compact,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: isCheckboxEnabled
          ? (checked) {
              ref
                  .read(categoriesSelectionProvider.notifier)
                  .setSelected(categorySlug, checked ?? false);
            }
          : null,
      secondary: Opacity(
        opacity: isCheckboxEnabled ? 1 : 0.38,
        child: getIcon(categorySlug, 24, null),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                node.label,
                style: TextStyle(
                  color: isCheckboxEnabled ? null : disabledColor,
                ),
              ),
            ),
            if (isAdmin)
              poiCountAsync.when(
                data: (count) {
                  return Text(
                    ' ($count)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: count > 0 ? null : disabledColor,
                    ),
                  );
                },
                loading: () {
                  return const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  );
                },
                error: (error, stackTrace) {
                  return Tooltip(
                    message: error.toString(),
                    child: Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
