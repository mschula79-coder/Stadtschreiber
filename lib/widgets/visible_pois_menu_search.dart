import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/address_lookup_queue_provider.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/poi_service_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/widgets/search_results_list.dart';

class PoiSearch extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(List<PointOfInterest>) onShowAll;

  const PoiSearch({super.key, required this.onClose, required this.onShowAll});

  @override
  ConsumerState<PoiSearch> createState() => _PoiSearchState();
}

class _PoiSearchState extends ConsumerState<PoiSearch> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        SizedBox(height: 8),

        // Suche
        const Text(
          "Suche",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),

        // SEARCH FIELD
        Container(
          width: 250,
          padding: const EdgeInsets.fromLTRB(6, 0, 4, 0),
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
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
                  final checkedPoi = await poiService.checkForDuplicates(poi);
                  ref
                      .read(addressLookupQueueProvider.notifier)
                      .enqueue(checkedPoi);

                  ref.read(searchSelectionProvider.notifier).add(checkedPoi);
                  ref.read(selectedPoiProvider.notifier).setPoi(checkedPoi);

                  setState(() {
                    _searchVisible = false;
                    _searchController.clear();
                  });
                  widget.onClose();
                },
                onShowAll: () => widget.onShowAll(poiresultslist),
              );
            },
            loading: () => const SizedBox(
              width: 220,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, st) => Text("Error: $err"),
          ),
      ],
    );
  }
}
