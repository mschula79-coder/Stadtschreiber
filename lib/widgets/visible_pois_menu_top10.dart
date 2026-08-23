import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/category.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_top10_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/utils/category_utils.dart';
import 'package:stadtschreiber/widgets/_icon_getter.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiTop10List extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(List<PointOfInterest>) onShowAll;
  final void Function(PointOfInterest) onSelect;

  const PoiTop10List({
    super.key,
    required this.onClose,
    required this.onShowAll,
    required this.onSelect,
  });

  @override
  ConsumerState<PoiTop10List> createState() => _PoiTop10ListState();
}

class _PoiTop10ListState extends ConsumerState<PoiTop10List> {
  double top10ListLength = 10;
  CategoryNode? top10Category;
  RatingCriterionDTO? top10Criterion;
  final ExpansibleController expansionController = ExpansibleController();
  PoiSelectionMode? _lastMode;

  @override
  Widget build(BuildContext context) {
    final top10ListAsync = ref.watch(top10PoisProvider);

    final mode = ref.watch(visiblePoisMenuStateProvider).poiSelectionMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastMode != mode) {
        if (mode == PoiSelectionMode.top10) {
          expansionController.expand();
        } else {
          expansionController.collapse();
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
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(left: 0, right: 15),
          childrenPadding: EdgeInsets.fromLTRB(0, 0, 0, 0),
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,
          controller: expansionController,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          onExpansionChanged: (value) {
            ref
                .read(visiblePoisMenuStateProvider.notifier)
                .setTileExpanded("top10", value);

            if (value) {
              ref
                  .read(visiblePoisMenuStateProvider.notifier)
                  .setPoiEditMode(PoiSelectionMode.top10);
            }
          },
          // Überschrift
          title: Row(
            children: [
              getIcon("ranking", 20, Colors.grey.shade600),
              /*                 Icon(Icons.play_circle_sharp, color: Colors.grey.shade600),
 */
              SizedBox(width: 8),

              Expanded(
                child: const Text(
                  "Top10",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          children: [
            // Kategorien Dropdown
            SizedBox(height: 5),

            buildCategoryDropdown(context, ref),

            SizedBox(height: 5),

            // Kriterium Dropdown
            buildCriteriaDropdown(context, ref),
            SizedBox(height: 5),

            // Listenlänge Dropdown
            buildListLengthDropdown(context, ref),
            SizedBox(height: 0),

            if (top10Category != null && top10Criterion != null)
              top10ListAsync.when(
                data: (top10pois) {
                  if (top10pois.isEmpty) {
                    return Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(5, 15, 0, 0),
                      child: const Text(
                        "Keine Orte mit diesen Kriterien vorhanden",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.fromLTRB(5, 15, 0, 0),
                          child: const Text(
                            "Resultate",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: top10pois.length,
                          itemBuilder: (context, index) {
                            return PoiListItem(
                              poi: top10pois[index],
                              onTap: () {
                                ref
                                    .read(selectedPoiProvider.notifier)
                                    .setPoi(top10pois[index]);
                                widget.onClose();
                              },
                            );
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Alle anzeigen"),
                          onPressed: () {
                            widget.onShowAll(top10pois);
                          },
                        ),
                      ],
                    );
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text("Fehler: $err"),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryDropdown(BuildContext context, WidgetRef ref) {
    final roots = ref.watch(categoriesProvider).categories;
    final allLeafs = CategoryUtils.collectAllLeafCategories(roots);

    return Stack(
      children: [
        Positioned(
          left: 16,
          top: 0,
          child: Text(
            "Kategorie", // oder AppLocalizations...
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            0,
          ), // ⭐ Platz für Label oben
          child: DropdownButton<CategoryNode>(
            value: top10Category,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(
              AppLocalizations.of(context)?.selectCategory ?? 'selectCategory',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            items: allLeafs.map((item) {
              return DropdownMenuItem(value: item, child: Text(item.label));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                top10Category = value;
              });
              ref.read(top10StateProvider.notifier).setCategory(value);
            },
          ),
        ),
      ],
    );
  }

  Widget buildCriteriaDropdown(BuildContext context, WidgetRef ref) {
    if (top10Category == null) return SizedBox.shrink();

    final criteriaAsync = ref.watch(
      criteriaForCategoryProvider(top10Category!.id),
    );

    return criteriaAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Fehler: $error'),
      data: (criteria) {
        return Stack(
          children: [
            // ⭐ Hintergrund-Label wie beim Category-Dropdown
            Positioned(
              left: 16,
              top: 0,
              child: Text(
                AppLocalizations.of(context)?.rating ?? "Kriterium",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),

            // ⭐ Dropdown selbst
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(50),
              ),

              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),

              child: DropdownButton<RatingCriterionDTO>(
                value: top10Criterion,
                isExpanded: true,
                underline: const SizedBox(),
                hint: Text(
                  AppLocalizations.of(context)?.selectRatingCriterion ??
                      "selectCriterion",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),

                items: criteria.map((item) {
                  return DropdownMenuItem(value: item, child: Text(item.name));
                }).toList(),

                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    top10Criterion = value;
                  });
                  ref.read(top10StateProvider.notifier).setCriterion(value);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildListLengthDropdown(BuildContext context, WidgetRef ref) {
    final items = [
      'Top5',
      'Top10',
      'Top20',
      'Top50',
      'Top100',
      AppLocalizations.of(context)?.allRated ?? 'All rated',
    ];

    return Stack(
      children: [
        Positioned(
          left: 16,
          top: 0,
          child: Text(
            AppLocalizations.of(context)?.selectLengthOfPoiList ??
                "Länge der Hitliste",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),

        // ⭐ Dropdown selbst
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(50),
          ),

          // ⭐ Platz für Label oben
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),

          child: DropdownButton<String>(
            value: top10ListLength == double.infinity
                ? (AppLocalizations.of(context)?.allRated ?? 'All rated')
                : "Top${top10ListLength.toInt()}",

            isExpanded: true,
            underline: const SizedBox(),

            hint: Text(
              AppLocalizations.of(context)?.selectLengthOfPoiList ??
                  "selectListLength",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),

            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),

            onChanged: (value) {
              if (value == null) return;
              setState(() {
                final lastItem =
                    AppLocalizations.of(context)?.allRated ?? 'All rated';

                if (value != lastItem) {
                  top10ListLength = double.parse(value.replaceFirst("Top", ""));
                } else {
                  top10ListLength = double.infinity;
                }
              });
              ref
                  .read(top10StateProvider.notifier)
                  .setListLength(top10ListLength);
            },
          ),
        ),
      ],
    );
  }
}
