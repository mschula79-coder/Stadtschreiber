import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiSearch extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(List<PointOfInterest>) onShowAll;
  final void Function(PointOfInterest) onSelect;

  const PoiSearch({
    super.key,
    required this.onClose,
    required this.onShowAll,
    required this.onSelect,
  });

  @override
  ConsumerState<PoiSearch> createState() => _PoiSearchState();
}

class _PoiSearchState extends ConsumerState<PoiSearch> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(poiRepositoryProvider);

    final camera = ref.read(cameraProvider);

    final searchResults = ref.watch(
      searchResultsProvider((
        query: _searchQuery,
        searchActive: true,
        repo: repo,
        camera: camera,
      )),
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
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          title: const Text(
            "Suche",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          children: [
            SizedBox(height: 3),

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
                },
              ),
            ),

            if (_searchQuery.isNotEmpty)
              searchResults.when(
                data: (foundPois) {
                  if (foundPois.isEmpty) {
                    return Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(5, 15, 0, 0),
                      child: const Text(
                        "Keine Orte gefunden",
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
                          itemCount: foundPois.length,
                          itemBuilder: (context, index) {
                            return PoiListItem(
                              poi: foundPois[index],
                              onTap: () async {
                                final poi = foundPois[index];
                                
                                _handlePoiSelection(poi);

                                ref
                                    .read(selectedPoiProvider.notifier)
                                    .setPoi(poi);
                                widget.onClose();
                              },
                            );
                          },
                        ),
                        ElevatedButton(
                          child: const Text("Alle anzeigen"),
                          onPressed: () {
                            widget.onShowAll(foundPois);
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

            // SEARCH FIELD

            // END OF SEARCH FIELD

            // Search Results(only visible when toggled)
          ],
        ),
      ),
    );
  }

  void _handlePoiSelection(PointOfInterest poi) {
    // hier ist alles wieder synchron, kein async, kein await

    FocusScope.of(context).unfocus(); // Tastatur weg
    widget.onSelect(poi); // POI-Panel öffnen

    setState(() {
      _searchController.clear();
    });
  }
}
