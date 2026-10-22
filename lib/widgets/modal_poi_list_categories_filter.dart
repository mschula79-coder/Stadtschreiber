import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/utils/language_utils.dart';


class PoiListCategoryFilter extends ConsumerStatefulWidget {
  final Iterable<String> categories;
  final Set<String> initialCategories;

  const PoiListCategoryFilter({
    super.key,
    required this.categories,
    required this.initialCategories,
  });

  @override
  ConsumerState<PoiListCategoryFilter> createState() =>
      _PoiListCategoryFilterState();
}

class _PoiListCategoryFilterState extends ConsumerState<PoiListCategoryFilter> {
  late final List<String> categories;
  late Set<String> selectedCategories;

  @override
  void initState() {
    super.initState();

    categories =
        widget.categories
            .map((category) => category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort(
            (first, second) =>
                first.toLowerCase().compareTo(second.toLowerCase()),
          );

    selectedCategories = Set<String>.from(
      widget.initialCategories.where(categories.contains),
    );
  }

  bool get allCategoriesSelected =>
      categories.isNotEmpty && selectedCategories.length == categories.length;

  void toggleCategory(String category, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedCategories.add(category);
      } else {
        selectedCategories.remove(category);
      }
    });
  }

  void selectAll() {
    setState(() {
      selectedCategories = categories.toSet();
    });
  }

  void clearSelection() {
    setState(() {
      selectedCategories.clear();
    });
  }

  void applyFilter() {
    Navigator.of(
      context,
    ).pop<Set<String>>(Set<String>.from(selectedCategories));
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          Expanded(child: Text(getText("filterCategories", languageCode: languageCode))),
          IconButton(
            tooltip: getText("close", languageCode: languageCode),
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: categories.isEmpty
            ? Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  getText("noEntries", languageCode: languageCode),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: allCategoriesSelected,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      getText("selectAll", languageCode: languageCode),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onChanged: (isSelected) {
                      if (isSelected == true) {
                        selectAll();
                      } else {
                        clearSelection();
                      }
                    },
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategories.contains(
                          category,
                        );

                        final categoryLabel =
                            ref.watch(categoryLabelBySlugProvider(category)) ??
                            category;

                        return CheckboxListTile(
                          value: isSelected,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          title: Text(categoryLabel),
                          onChanged: (value) {
                            toggleCategory(category, value ?? false);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton(
                onPressed: applyFilter,
                child: Text(getText("apply", languageCode: languageCode)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.outline,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(getText("cancel", languageCode: languageCode)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
