import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/models/category.dart';
import 'package:stadtschreiber/models/poi_display_modes.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_display_mode_provider.dart';
import 'package:stadtschreiber/utils/category_utils.dart';
import 'package:stadtschreiber/widgets/modal_message_box.dart';

class PoiTop10List extends ConsumerStatefulWidget {
  final VoidCallback onSelect;

  const PoiTop10List({super.key, required this.onSelect});

  @override
  ConsumerState<PoiTop10List> createState() => _PoiTop10ListState();
}

class _PoiTop10ListState extends ConsumerState<PoiTop10List> {
  double top10ListLength = 10;
  CategoryNode? top10Category;
  RatingCriterionDTO? top10Criterion;

  @override
  Widget build(BuildContext context) {
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
          childrenPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,
          // Überschrift
          title: const Text(
            "Top10",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          children: [
            Text(
              AppLocalizations.of(context)?.selectCategory ?? 'selectCategory',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            buildCategoryDropdown(context, ref),

            Text(
              AppLocalizations.of(context)?.selectRatingCriterion ??
                  'selectCriteria',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),

            buildCriteriaDropdown(context, ref),

            Text(
              AppLocalizations.of(context)?.selectLengthOfPoiList ??
                  'selectPoiCount',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),

            buildListLengthDropdown(context, ref),

            TextButton(
              onPressed: () {
                setState(() {
                  if (top10Category == null || top10Criterion == null) {
                    // TODO switch mode, when category is selected, searchfield is activated and here
                    ref.read(poiDisplayModeProvider.notifier).setMode(PoiDisplayMode.top10);
                  } else {
                    messageBox(
                      context,
                      AppLocalizations.of(context)?.selectionIncomplete ??
                          'selectionIncomplete',
                      'Top 10 Auswahl',
                    );
                  }
                });
              },
              child: Text(AppLocalizations.of(context)!.showTop10),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryDropdown(BuildContext context, WidgetRef ref) {
    final roots = ref.watch(categoriesProvider).categories;
    final allLeafs = CategoryUtils.collectAllLeafCategories(roots);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Hintergrund
        borderRadius: BorderRadius.circular(50), // ⭐ abgerundete Ecken
      ),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),

      child: DropdownButton<CategoryNode>(
        value: null,
        items: allLeafs.map((item) {
          return DropdownMenuItem(value: item, child: Text(item.label));
        }).toList(),
        onChanged: (value) {
          setState(() {
            if (value == null) return;
            top10Category = value;
          });
        },
      ),
    );
  }

  Widget buildCriteriaDropdown(BuildContext context, WidgetRef ref) {
    if (top10Category == null) return SizedBox.shrink();

    final criteriaAsync = ref.watch(
      criteriaForCategoryProvider(top10Category!.id),
    );

    return criteriaAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Fehler: $error'),
      data: (criteria) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200, // Hintergrund
            borderRadius: BorderRadius.circular(50), // ⭐ abgerundete Ecken
          ),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),

          child: DropdownButton<RatingCriterionDTO>(
            value: null,
            underline: const SizedBox(),
            items: criteria.map((item) {
              return DropdownMenuItem(value: item, child: Text(item.name));
            }).toList(),
            onChanged: (value) {
              setState(() {
                if (value == null) return;
                top10Criterion = value;
              });
            },
          ),
        );
      },
    );
  }

  Widget buildListLengthDropdown(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Hintergrund
        borderRadius: BorderRadius.circular(50), // ⭐ abgerundete Ecken
      ),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),

      child: DropdownButton<String>(
        value: 'Top10',
        underline: const SizedBox(),
        onChanged: (value) {
          setState(() {
            if (value == null) return;
            final lastItem =
                AppLocalizations.of(context)?.allRated ?? 'All rated';

            if (value != lastItem) {
              top10ListLength = double.parse(value.replaceFirst("Top", ""));
            } else {
              top10ListLength = double.infinity;
            }
          });
        },
        items:
            [
              'Top5',
              'Top10',
              'Top20',
              'Top50',
              'Top100',
              AppLocalizations.of(context)?.allRated ?? 'All rated',
            ].map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
      ),
    );
  }
}
