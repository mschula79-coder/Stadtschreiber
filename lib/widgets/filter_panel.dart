import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/tabler.dart';
import '../state/filter_state.dart';

import '../models/category.dart';

class FilterPanel extends StatelessWidget {
  final List<CategoryNode> categories;
  final FilterState filterState;
  final VoidCallback onClose;

  const FilterPanel({
    super.key,
    required this.categories,
    required this.filterState,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final allLeafValues = _collectAllLeafValues(categories);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height * 0.75 -
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Karteninhalte",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              contentPadding: const EdgeInsets.only(top: 5, right: 15),
              value: filterState.selectedValues.isEmpty
                  ? false
                  : filterState.selectedValues.length == allLeafValues.length
                  ? true
                  : null,
              tristate: true,
              secondary: Image.network(
                'https://raw.githubusercontent.com/mschula79-coder/Stadtschreiber/refs/heads/main/map_search_black.png',
                height: 24,
                width: 24,
              ),
              title: const Text("Alles auswählen"),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (checked) {
                if (checked == true) {
                  for (final v in allLeafValues) {
                    if (!filterState.isSelected(v)) {
                      filterState.setSelected(v, true);
                    }
                  }
                } else {
                  for (final v in allLeafValues) {
                    if (filterState.isSelected(v)) {
                      filterState.setSelected(v, false);
                    }
                  }
                }
              },
            ),
            ...categories.map((node) => _buildCategoryNode(context, node)),
          ],
        ),
      ),
    );
  }

  // ---------- category tree ----------

  Widget _buildCategoryNode(BuildContext context, CategoryNode node) {
    if (node.isLeaf) {
      final isChecked = node.value != null && filterState.isSelected(node.value!);
      return CheckboxListTile(
        contentPadding: const EdgeInsets.only(right: 15),
        value: isChecked,
        onChanged: (checked) {
          if (node.value == null) return;
          filterState.setSelected(node.value!, checked ?? false);
        },
        secondary: _buildIcon(node),
        controlAffinity: ListTileControlAffinity.leading,
        title: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(node.label),
        ),
      );
    }

    final allDescendantLeaves = _collectLeafValues(node);
    final directLeafChildren = node.children
        .where((c) => c.isLeaf && c.value != null)
        .map((c) => c.value!)
        .toList();

    final checkedChildren = allDescendantLeaves
        .where((v) => filterState.isSelected(v))
        .length;

    bool? parentChecked;
    if (checkedChildren == 0) {
      parentChecked = false;
    } else if (checkedChildren == allDescendantLeaves.length) {
      parentChecked = true;
    } else {
      parentChecked = null;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.zero),
      ),
      child: ListTileTheme(
        contentPadding: EdgeInsets.zero,
        horizontalTitleGap: 0,
        minLeadingWidth: 0,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.only(right: 15),
          childrenPadding: EdgeInsets.zero,
          leading: Checkbox(
            value: parentChecked,
            tristate: true,
            onChanged: (checked) {
              if (checked == true) {
                for (final value in directLeafChildren) {
                  if (!filterState.isSelected(value)) {
                    filterState.setSelected(value, true);
                  }
                }
              } else {
                for (final value in directLeafChildren) {
                  if (filterState.isSelected(value)) {
                    filterState.setSelected(value, false);
                  }
                }
              }
            },
          ),
          title: Row(
            children: [
              const SizedBox(width: 15),
              Text(node.label),
              _buildIcon(node),
            ],
          ),
          children: node.children
              .map((child) => _buildCategoryNode(context, child))
              .toList(),
        ),
      ),
    );
  }

  // ---------- icon helpers ----------

  Widget _buildIcon(CategoryNode node) {
    final icon = node.icon;
    if (icon == null) return const SizedBox.shrink();

    switch (icon.type) {
      case "url":
        return Image.network(icon.value, height: 24, width: 24);
      case "flutter":
        final iconData = _flutterIconFromString(icon.value);
        return Icon(iconData, size: 24);
      case "iconify":
        return _iconifyIconFromString(icon.value);
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _flutterIconFromString(String name) {
    switch (name) {
      case "sports":
        return Icons.sports;
      case "sports_tennis":
        return Icons.sports_tennis;
      case "park":
        return Icons.park;
      default:
        return Icons.help_outline;
    }
  }

  Widget _iconifyIconFromString(String name) {
    switch (name) {
      case "mdi:tennis":
        return const Iconify(Mdi.tennis, size: 24);
      case "mdi:table-tennis":
        return const Iconify(Mdi.table_tennis, size: 24);
      case "tabler:ball-tennis":
        return const Iconify(Tabler.ball_tennis, size: 24);
      default:
        return const Iconify(Mdi.help_outline, size: 24);
    }
  }

  // ---------- tree helpers ----------

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

  List<String> _collectAllLeafValues(List<CategoryNode> roots) {
    final result = <String>[];
    for (final node in roots) {
      result.addAll(_collectLeafValues(node));
    }
    return result;
  }
}
