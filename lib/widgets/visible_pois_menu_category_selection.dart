import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/category_repository_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/utils/dialog_utils.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/modal_rating_criteria_edit.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';

class PoiCategorySelection extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const PoiCategorySelection({super.key, required this.onClose});

  @override
  ConsumerState<PoiCategorySelection> createState() =>
      _PoiCategorySelectionState();
}

class _PoiCategorySelectionState extends ConsumerState<PoiCategorySelection> {
  String _categoryFilter = "";
  final TextEditingController _categoryFilterController =
      TextEditingController();
  bool isFilterActive = false;
  bool expandAll = false;
  bool isAdminViewEnabled = false;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).categories;
    final isAdmin = ref.read(supabaseUserStateProvider).isAdmin;

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
          childrenPadding: const EdgeInsets.fromLTRB(10, 4, 0, 0),
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          title: Row(
            children: [
              /*                 Icon(Icons.category, color: Colors.grey.shade600),
 */
              Icon(Icons.category, color: Colors.grey.shade600),
              SizedBox(width: 8),

              Expanded(
                child: const Text(
                  "Kategorien",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          children: [
            // ---------------- FILTER ----------------
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
                      decoration: const InputDecoration(
                        hintText: "Kategorien filtern",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _categoryFilter = value.trim().toLowerCase();
                            expandAll = _categoryFilter.isNotEmpty;
                          });
                        });
                      },
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (isFilterActive) {
                          _categoryFilter = "";
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

            // ---------------- CATEGORY TREE ----------------
            ..._filterCategoryTree(
              categories,
              _categoryFilter,
            ).map((node) => _buildCategoryNode(context, ref, node)),

            // ---------------- ADMIN SWITCH ----------------
            if (isAdmin)
              SwitchListTile(
                title: const Text(
                  'Bewertungskriterien bearbeiten',
                  style: TextStyle(fontSize: 16),
                ),
                contentPadding: const EdgeInsets.only(top: 10),
                value: isAdminViewEnabled,
                onChanged: (newValue) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      isAdminViewEnabled = newValue;
                    });
                  });
                },
              ),

            // ---------------- ADMIN CRITERIA LIST ----------------
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
                          itemBuilder: (entry) => Padding(
                            padding: const EdgeInsets.all(0),
                            child: Text(
                              entry.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          onDelete: (entry) async {
                            final confirmed = await openConfirmDialog(
                              context,
                              message:
                                  'Dies löscht das Kriterium ${entry.name} für alle Kategorien. Willst du das?',
                              optionTrue: 'Ja',
                              optionFalse: 'Nein',
                            );

                            if (confirmed == true) {
                              ref
                                  .read(categoriesRepositoryProvider)
                                  .deleteCriterion(entry);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ref.invalidate(globalCriteriaProvider);
                              });
                            }
                          },
                          onAdd: () async {
                            final emptyCriterion = RatingCriterionDTO(
                              id: const Uuid().v4(),
                              name: '',
                              description: '',
                              scoreDescriptions: {},
                            );

                            final emptyCriterionWithId = await ref
                                .read(categoriesRepositoryProvider)
                                .newCriterion(emptyCriterion);

                            if (!context.mounted) return;

                            final newCriterion =
                                await showDialog<RatingCriterionDTO>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => RatingCriteriaEditModal(
                                    criterionDTO: emptyCriterionWithId,
                                  ),
                                );

                            if (newCriterion == null) return;

                            await ref
                                .read(categoriesRepositoryProvider)
                                .updateCriterion(newCriterion);

                            ref.invalidate(globalCriteriaProvider);
                            return;
                          },

                          onEdit: (entry) async {
                            final edited = await showDialog<RatingCriterionDTO>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) =>
                                  RatingCriteriaEditModal(criterionDTO: entry),
                            );

                            if (edited == null) return;

                            await ref
                                .read(categoriesRepositoryProvider)
                                .updateCriterion(edited);
                            ref.invalidate(globalCriteriaProvider);
                            return;
                          },
                        );
                      },
                      loading: () =>
                          const CircularProgressIndicator(strokeWidth: 2),
                      error: (e, st) => Text("Fehler: $e"),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- category tree ----------
  List<CategoryNode> _filterCategoryTree(
    List<CategoryNode> nodes,
    String filter,
  ) {
    if (filter.isEmpty) return nodes;

    final result = <CategoryNode>[];

    for (final node in nodes) {
      final labelMatches = node.label.toLowerCase().contains(filter);

      if (node.isLeaf) {
        if (labelMatches) result.add(node);
      } else {
        final filteredChildren = _filterCategoryTree(node.children, filter);

        if (labelMatches || filteredChildren.isNotEmpty) {
          result.add(
            CategoryNode(
              id: node.id,
              label: node.label,
              value: node.value,
              children: filteredChildren,
            ),
          );
        }
      }
    }

    return result;
  }

  // ---------- build category node ----------
  Widget _buildCategoryNode(
    BuildContext context,
    WidgetRef ref,
    CategoryNode node,
  ) {
    final categoryCheckboxesState = ref.watch(categoriesSelectionProvider);

    if (!node.isLeaf) {
      final allDescendantLeaves = _collectLeafValues(node);
      final directLeafChildren = node.children
          .where((c) => c.isLeaf && c.value != null)
          .map((c) => c.value!)
          .toList();

      final checkedChildren = allDescendantLeaves
          .where((v) => categoryCheckboxesState.isSelected(v))
          .length;

      bool? parentChecked;
      if (checkedChildren == 0) {
        parentChecked = false;
      } else if (checkedChildren == allDescendantLeaves.length) {
        parentChecked = true;
      } else {
        parentChecked = null;
      }

      return ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 0, right: 15),
        childrenPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        initiallyExpanded: expandAll,
        leading: Checkbox(
          value: parentChecked,
          tristate: true,
          onChanged: (checked) {
            if (checked == true) {
              for (final value in directLeafChildren) {
                if (!categoryCheckboxesState.isSelected(value)) {
                  ref
                      .read(categoriesSelectionProvider.notifier)
                      .setSelected(value, true);
                }
              }
            } else {
              for (final value in directLeafChildren) {
                if (categoryCheckboxesState.isSelected(value)) {
                  ref
                      .read(categoriesSelectionProvider.notifier)
                      .setSelected(value, false);
                }
              }
            }
          },
        ),
        title: Row(
          children: [
            Expanded(child: Text(node.label, softWrap: true, maxLines: null)),
            getIcon(node.value ?? '', 24, null),
          ],
        ),
        children: node.children
            .map((child) => _buildCategoryNode(context, ref, child))
            .toList(),
      );
    }

    // Leaf node
    final isChecked =
        node.value != null && categoryCheckboxesState.isSelected(node.value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: const EdgeInsets.only(top: 0, left: 4, right: 15),
          value: isChecked,
          visualDensity: VisualDensity.compact,
          onChanged: (checked) {
            if (node.value == null) return;
            ref
                .read(categoriesSelectionProvider.notifier)
                .setSelected(node.value!, checked ?? false);
          },
          secondary: getIcon(node.value!, 24, null),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(node.label),
        ),
      ],
    );
  }

  List<String> _collectLeafValues(CategoryNode node) {
    final result = <String>[];

    void walk(CategoryNode n) {
      if (n.isLeaf && n.value != null) {
        result.add(n.value!);
      } else {
        for (final child in n.children) {
          walk(child);
        }
      }
    }

    walk(node);
    return result;
  }
}
