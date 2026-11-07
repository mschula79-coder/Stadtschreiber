import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/category_node_localized.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_localized_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/poi_top10_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

// Fix no pois found

class PoiTop10List extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(PointOfInterest) onSelect;

  const PoiTop10List({
    super.key,
    required this.onClose,
    required this.onSelect,
  });

  @override
  ConsumerState<PoiTop10List> createState() => _PoiTop10ListState();
}

class _PoiTop10ListState extends ConsumerState<PoiTop10List> {
  final ExpansibleController expansionController = ExpansibleController();
  PoiSelectionMode? _lastMode;

  /// ⭐ Persistente Speicherung der Top10‑POIs
  List<PointOfInterest> persistentTop10Pois = [];
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;

    final top10ListAsync = ref.watch(top10PoisProvider);
    final mode = ref.watch(visiblePoisMenuStateProvider).poiSelectionMode;
    final top10State = ref.watch(top10StateProvider);

    // ⭐ Nur expanden, niemals automatisch collapse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastMode != mode) {
        if (mode == PoiSelectionMode.top10) {
          expansionController.expand();
        }
        _lastMode = mode;
      }
    });

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
          key: const ValueKey('top10_tile'),
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
                .setTileExpanded("top10", value);

            if (value) {
              ref
                  .read(visiblePoisMenuStateProvider.notifier)
                  .setPoiSelectionMode(PoiSelectionMode.top10);
            }
            setState(() {
              expanded = value;
            });
          },

          title: Row(
            children: [
              getIcon("ranking", 20, Colors.grey.shade600),
              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  "Top10",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          children: [
            const SizedBox(height: 5),
            buildCategoryDropdown(context, ref),
            const SizedBox(height: 5),
            buildCriteriaDropdown(context, ref),
            const SizedBox(height: 5),
            buildListLengthDropdown(context, ref),
            const SizedBox(height: 0),

            if (top10State.category != null && top10State.criterion != null)
              top10ListAsync.when(
                data: (top10pois) {
                  // ⭐ Persistente Speicherung
                  persistentTop10Pois = top10pois;

                  if (top10pois.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(5, 15, 0, 0),
                      child: Text(
                        getText(
                          'noPoiFoundWithTheseCriteria',
                          languageCode: languageCode,
                          countryCode: countryCode,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(5, 15, 0, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                getText(
                                  'results',
                                  languageCode: languageCode,
                                  countryCode: countryCode,
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: Iconify(
                                Mdi.checkbox_multiple_marked_outline,
                                color: Colors.black87,
                                size: 24,
                              ),
                              onPressed: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  ref
                                      .read(poiSelectionProvider.notifier)
                                      .setAll(persistentTop10Pois);
                                });
                              },
                            ),

                            /// ⭐ Alle demarkieren
                            IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: const Iconify(
                                Mdi.checkbox_multiple_blank_outline,
                                color: Colors.black87,
                                size: 24,
                              ),
                              onPressed: () {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  ref
                                      .read(poiSelectionProvider.notifier)
                                      .clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 0),

                      ListView.builder(
                        padding: EdgeInsets.zero,
                        primary: false,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: top10pois.length,
                        itemBuilder: (context, index) {
                          final poi = top10pois[index];

                          return PoiListItem(
                            selectEnabled: true,
                            poi: poi,
                            onTap: () {
                              ref
                                  .read(selectedPoiProvider.notifier)
                                  .setPoi(poi);
                              widget.onClose();
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text(
                  "${getText('error', languageCode: languageCode, countryCode: countryCode)}: $err",
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryDropdown(BuildContext context, WidgetRef ref) {
    final roots = ref.watch(localizedCategoriesProvider);

    final locale = ref.watch(localeProvider);

    final top10State = ref.watch(top10StateProvider);

    final selectedCategory = top10State.category;

    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: roots.isEmpty
            ? null
            : () async {
                final selected = await showDialog<LocalizedCategoryNode>(
                  context: context,
                  barrierDismissible: true,
                  builder: (dialogContext) {
                    return Top10CategoryTreeDialog(
                      categories: roots,
                      selectedCategorySlug: selectedCategory?.slug,
                      title: getText(
                        'selectCategory',
                        languageCode: locale.languageCode,
                        countryCode: locale.countryCode,
                      ),
                    );
                  },
                );

                if (selected == null) {
                  return;
                }

                ref.read(top10StateProvider.notifier).setCategory(selected);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedCategory?.label ??
                      getText(
                        'selectCategory',
                        languageCode: locale.languageCode,
                        countryCode: locale.countryCode,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedCategory == null
                        ? Theme.of(context).hintColor
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCriteriaDropdown(BuildContext context, WidgetRef ref) {
    final top10State = ref.watch(top10StateProvider);

    final selectedCategory = top10State.category;

    if (selectedCategory == null) {
      return const SizedBox.shrink();
    }

    final locale = ref.watch(localeProvider);

    final categoryRoots = ref.watch(localizedCategoriesProvider);

    final categoryPath = _findCategoryPath(categoryRoots, selectedCategory.id);

    if (categoryPath.isEmpty) {
      return const SizedBox.shrink();
    }

    final criteriaResults = categoryPath
        .map((category) => ref.watch(criteriaForCategoryProvider(category.id)))
        .toList(growable: false);

    final firstError = criteriaResults
        .map((result) => result.asError)
        .whereType<AsyncError<List<RatingCriterionDTO>>>()
        .firstOrNull;

    if (firstError != null) {
      return Text(
        '${getText('error', languageCode: locale.languageCode, countryCode: locale.countryCode)}: ${firstError.error}',
      );
    }

    final isLoading = criteriaResults.any((result) => result.isLoading);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final criteriaById = <String, RatingCriterionDTO>{};

    for (final result in criteriaResults) {
      final criteria = result.asData?.value ?? const <RatingCriterionDTO>[];

      for (final criterion in criteria) {
        criteriaById.putIfAbsent(criterion.id, () => criterion);
      }
    }

    final criteria = criteriaById.values.toList()
      ..sort((first, second) {
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      });

    final selectedCriterion = top10State.criterion == null
        ? null
        : criteria.cast<RatingCriterionDTO?>().firstWhere((criterion) {
            return criterion?.id == top10State.criterion?.id;
          }, orElse: () => null);

    return Stack(
      children: [
        Positioned(
          left: 16,
          top: 0,
          child: Text(
            getText(
              'criterion',
              languageCode: locale.languageCode,
              countryCode: locale.countryCode,
            ),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<RatingCriterionDTO>(
            value: selectedCriterion,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: Text(
              criteria.isEmpty
                  ? getText(
                      'noRatingCriteriaAvailable',
                      languageCode: locale.languageCode,
                      countryCode: locale.countryCode,
                    )
                  : getText(
                      'selectRatingCriterion',
                      languageCode: locale.languageCode,
                      countryCode: locale.countryCode,
                    ),
              style: const TextStyle(fontSize: 14),
            ),
            items: criteria
                .map((criterion) {
                  return DropdownMenuItem<RatingCriterionDTO>(
                    value: criterion,
                    child: Text(
                      criterion.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                })
                .toList(growable: false),
            onChanged: criteria.isEmpty
                ? null
                : (criterion) {
                    ref
                        .read(top10StateProvider.notifier)
                        .setCriterion(criterion);
                  },
          ),
        ),
      ],
    );
  }

  List<LocalizedCategoryNode> _findCategoryPath(
    List<LocalizedCategoryNode> nodes,
    String selectedCategoryId,
  ) {
    for (final node in nodes) {
      if (node.id == selectedCategoryId) {
        return <LocalizedCategoryNode>[node];
      }

      final childPath = _findCategoryPath(node.children, selectedCategoryId);

      if (childPath.isNotEmpty) {
        return <LocalizedCategoryNode>[node, ...childPath];
      }
    }

    return const <LocalizedCategoryNode>[];
  }
  // TODO Supabase photos migrieren

  Widget buildListLengthDropdown(BuildContext context, WidgetRef ref) {
    final allRated = AppLocalizations.of(context)?.allRated ?? 'All rated';

    final items = <String>[
      'Top5',
      'Top10',
      'Top20',
      'Top50',
      'Top100',
      allRated,
    ];

    final locale = ref.watch(localeProvider);

    final top10State = ref.watch(top10StateProvider);

    final selectedValue = top10State.listLength.isInfinite
        ? allRated
        : 'Top${top10State.listLength.toInt()}';

    return Stack(
      children: [
        Positioned(
          left: 16,
          top: 0,
          child: Text(
            getText(
              'lengthOfPoiList',
              languageCode: locale.languageCode,
              countryCode: locale.countryCode,
            ),
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: Text(
              getText(
                'selectLengthOfPoiList',
                languageCode: locale.languageCode,
                countryCode: locale.countryCode,
              ),
              style: const TextStyle(fontSize: 14),
            ),
            items: items
                .map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                })
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              final listLength = value == allRated
                  ? double.infinity
                  : double.parse(value.replaceFirst('Top', ''));

              ref.read(top10StateProvider.notifier).setListLength(listLength);
            },
          ),
        ),
      ],
    );
  }
}

class Top10CategoryTreeDialog extends StatefulWidget {
  final String title;
  final List<LocalizedCategoryNode> categories;
  final String? selectedCategorySlug;

  const Top10CategoryTreeDialog({
    super.key,
    required this.title,
    required this.categories,
    required this.selectedCategorySlug,
  });

  @override
  State<Top10CategoryTreeDialog> createState() {
    return _Top10CategoryTreeDialogState();
  }
}

class _Top10CategoryTreeDialogState extends State<Top10CategoryTreeDialog> {
  final Set<String> _expandedCategoryIds = <String>{};

  @override
  void initState() {
    super.initState();

    final selectedSlug = widget.selectedCategorySlug;

    if (selectedSlug != null) {
      _expandParentsOfSelectedCategory(widget.categories, selectedSlug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedRoots = List<LocalizedCategoryNode>.from(widget.categories)
      ..sort(_compareCategoryNodes);

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
                    const Icon(Icons.account_tree_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
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
                  ),
                  child: sortedRoots.isEmpty
                      ? const Center(child: Text('Keine Kategorien verfügbar.'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: sortedRoots
                              .map(
                                (category) =>
                                    _buildCategoryNode(category, depth: 0),
                              )
                              .toList(growable: false),
                        ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Abbrechen'),
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

  Widget _buildCategoryNode(
    LocalizedCategoryNode category, {
    required int depth,
  }) {
    final sortedChildren = List<LocalizedCategoryNode>.from(category.children)
      ..sort(_compareCategoryNodes);

    final hasChildren = sortedChildren.isNotEmpty;

    final isExpanded = _expandedCategoryIds.contains(category.id);

    final isSelected = widget.selectedCategorySlug == category.slug;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          child: Row(
            children: [
              SizedBox(width: depth * 10.0),
              SizedBox(
                width: 40,
                height: 44,
                child: hasChildren
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tooltip: isExpanded ? 'Einklappen' : 'Aufklappen',
                        onPressed: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCategoryIds.remove(category.id);
                            } else {
                              _expandedCategoryIds.add(category.id);
                            }
                          });
                        },
                        icon: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop(category);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        getIcon(category.slug, 24, null),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasChildren && isExpanded)
          ...sortedChildren.map(
            (child) => _buildCategoryNode(child, depth: depth + 1),
          ),
      ],
    );
  }

  bool _expandParentsOfSelectedCategory(
    List<LocalizedCategoryNode> nodes,
    String selectedSlug,
  ) {
    for (final node in nodes) {
      if (node.slug == selectedSlug) {
        return true;
      }

      final containsSelected = _expandParentsOfSelectedCategory(
        node.children,
        selectedSlug,
      );

      if (containsSelected) {
        _expandedCategoryIds.add(node.id);

        return true;
      }
    }

    return false;
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
        .replaceAll('ç', 'c')
        .replaceAll('è', 'e')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u');
  }
}
