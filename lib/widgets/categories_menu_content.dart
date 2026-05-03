import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/tabler.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/address_lookup_queue_provider.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/categories_menu_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_service_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/widgets/search_results_list.dart';

import '../models/category.dart';

class CategoriesMenu extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const CategoriesMenu({super.key, required this.onClose});

  @override
  ConsumerState<CategoriesMenu> createState() => _CategoriesMenuState();
}

class _CategoriesMenuState extends ConsumerState<CategoriesMenu> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).categories;
    final repo = ref.read(poiRepositoryProvider);
    final camera = ref.read(cameraProvider);
    final searchResults = (_searchVisible && _searchQuery.isNotEmpty)
        ? ref.watch(
            searchResultsProvider((
              query: _searchQuery,
              searchActive: true,
              repo: repo,
              camera: camera,
            )),
          )
        : const AsyncValue<List<PointOfInterest>>.data([]);

    return Container(
      // Menucontainer
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

      // Menuinhalt
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            SizedBox(height: 8),

            // Suche
            const Text(
              "Suche",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),

            // SEARCH FIELD
            Container(
              width: 250,
              padding: const EdgeInsets.fromLTRB(6, 0, 4, 0),
              margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),

              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: "Suche nach Orten",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(0, 8, 0, 8),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onTap: () {
                  ref.read(searchSelectionProvider.notifier).clear();
                  FocusScope.of(context).unfocus();

                  setState(() => _searchVisible = true);
                },
                onTapUpOutside: (event) {
                  setState(() => _searchVisible = false);
                },
              ),
            ),
            // END OF SEARCH FIELD

            // Search Results(only visible when toggled)
            if (_searchVisible)
              searchResults.when(
                data: (poiresultslist) {
                  if (poiresultslist.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SearchResultsList(
                    results: poiresultslist,
                    onSelect: (poi) async {
                      final poiService = ref.read(poiServiceProvider);
                      final checkedPoi = await poiService.checkForDuplicates(
                        poi,
                      );
                      ref
                          .read(addressLookupQueueProvider.notifier)
                          .enqueue(checkedPoi);

                      ref
                          .read(searchSelectionProvider.notifier)
                          .add(checkedPoi);
                      ref.read(selectedPoiProvider.notifier).setPoi(checkedPoi);

                      setState(() {
                        _searchVisible = false;
                        _searchController.clear();
                      });
                      widget.onClose();
                    },
                    onShowAll: () {},
                  );
                },
                loading: () => const SizedBox(
                  width: 220,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, st) => Text("Error: $err"),
              ),

            // END OF SEARCH RESULTS
            SizedBox(height: 12),

            // Überschrift Kategorien
            const Text(
              "Kategorien",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            // Kategorien-Baum
            ...categories.map((node) => _buildCategoryNode(context, ref, node)),
          ],
        ),
      ),
    );
  }

  // ---------- category tree ----------

  Widget _buildCategoryNode(
    BuildContext context,
    WidgetRef ref,
    CategoryNode node,
  ) {
    final categoryCheckboxesState = ref.watch(categoriesSelectionProvider);

    // 1st Level Nodes = not isLeaf
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

      return Theme(
        data: Theme.of(context).copyWith(
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.zero,
          ),
        ),
        child: ListTileTheme(
          contentPadding: EdgeInsets.zero,
          horizontalTitleGap: 0,
          minLeadingWidth: 0,
          // 1st Level Nodes
          child: ExpansionTile(
            tilePadding: const EdgeInsets.only(left: 0, right: 15),
            childrenPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 0),
                Expanded(
                  child: Text(node.label, softWrap: true, maxLines: null),
                ),
                _buildIcon(node),
              ],
            ),
            children: node.children
                .map((child) => _buildCategoryNode(context, ref, child))
                .toList(),
          ),
        ),
      );
    }
    // 2nd level
    else {
      final isChecked =
          node.value != null && categoryCheckboxesState.isSelected(node.value!);

      return CheckboxListTile(
        contentPadding: const EdgeInsets.only(top: 0, left: 4, right: 15),
        value: isChecked,
        visualDensity: VisualDensity.compact,
        onChanged: (checked) {
          if (node.value == null) return;
          ref
              .read(categoriesSelectionProvider.notifier)
              .setSelected(node.value!, checked ?? false);
        },
        secondary: _buildIcon(node),
        controlAffinity: ListTileControlAffinity.leading,
        title: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(node.label),
        ),
      );
    }
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
      case "parks":
        return Icons.park;
      case "playgrounds":
        return Icons.local_play;
      case "sports":
        return Icons.sports;
      case "sports_tennis":
        return Icons.sports_tennis;
      case "park":
        return Icons.park;
      case "playground":
        return Icons.play_lesson;
      case "food_court":
        return Icons.restaurant;
      case "market":
        return Icons.local_grocery_store;
      case "basketball_court":
        return Icons.sports_basketball;
      case "tennis_court":
        return Icons.sports_tennis;
      default:
        return Icons.help_outline;
    }
  }

  Widget _iconifyIconFromString(String name) {
    switch (name) {
      case "fa7-solid:walking":
        return const FaIcon(FontAwesomeIcons.personWalking, size: 24);
      case "mdi:tennis":
        return const Iconify(Mdi.tennis, size: 24);
      case "mdi:table-tennis":
        return const Iconify(Mdi.table_tennis, size: 24);
      case "tabler:ball-tennis":
        return const Iconify(Tabler.ball_tennis, size: 24);
      case "mdi:spray":
        return const Iconify(Mdi.spray, size: 24);
      default:
        return const Iconify(Mdi.help_outline, size: 24);
    }
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
