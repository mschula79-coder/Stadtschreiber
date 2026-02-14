import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poi.dart';
import '../provider/search_provider.dart';
import '../provider/poi_repository_provider.dart';
import '../services/debug_service.dart';
import '../provider/camera_provider.dart';

class MapActions extends ConsumerStatefulWidget {
  final VoidCallback onChangeStyle;
  final VoidCallback onLocateMe;
  final VoidCallback onRemoveThumbnails;
  final VoidCallback onToggleAdminView;
  final bool isAdmin;
  final bool isAdminViewEnabled;

  final Future<void> Function(PointOfInterest) onTapSearchedPoi;

  const MapActions({
    super.key,
    required this.onChangeStyle,
    required this.onTapSearchedPoi,
    required this.onLocateMe,
    required this.onRemoveThumbnails,
    required this.onToggleAdminView,
    required this.isAdmin,
    required this.isAdminViewEnabled,
  });

  @override
  ConsumerState<MapActions> createState() => _MapActionsState();
}

class _MapActionsState extends ConsumerState<MapActions> {
  bool _searchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
      final controller = ref.read(poiControllerProvider);
      final repo = ref.read(poiRepositoryProvider);
      final camera = ref.read(cameraProvider);

    final searchResults = (_searchVisible && _searchQuery.isNotEmpty)
    ? ref.watch(searchResultsProvider((query: _searchQuery, searchActive: true, controller: controller, repo: repo, camera: camera)))
    : const AsyncValue.data([]);


    final poiController = ref.read(poiControllerProvider);
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          //toggle admin view
          widget.isAdmin
              ? Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "btn6",
                      onPressed: () {
                        widget.onToggleAdminView();
                      },
                      mini: true,
                      child: widget.isAdminViewEnabled
                          // print(Theme.of(context).colorScheme.onSecondaryContainer); //🎨 Hex: #101C2B
                          ? const Icon(
                              Icons.construction,
                              color: Color(0xFF101C2B),
                            )
                          : const Icon(
                              Icons.construction_outlined,
                              color: Colors.grey,
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : SizedBox.shrink(),
          FloatingActionButton(
            heroTag: "btn3",
            onPressed: () {
              widget.onLocateMe();
            },
            mini: true,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),

          //change style
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: widget.onChangeStyle,
            mini: true,
            child: const Icon(Icons.color_lens_outlined),
          ),
          const SizedBox(height: 8),
          //remove thumbnails
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: () {
              widget.onRemoveThumbnails();
            },
            mini: true,

            child: const Iconify(Mdi.pin_off_outline, size: 24),
          ),
          const SizedBox(height: 8),

          //search toggle
          Row(
            children: [
              // SEARCH RESULTS DROPDOWN
              Column(
                children: [
                  // SEARCH FIELD (only visible when toggled)
                  if (_searchVisible)
                    Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),

                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: "Search POIs…",
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                  // END OF SEARCH FIELD (only visible when toggled)
                  if (_searchVisible)
                    searchResults.when(
                      data: (poiresultslist) {
                        if (poiresultslist.isEmpty) return const SizedBox.shrink();

                        return Container(
                          width: 220,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6),
                            ],
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 5 * 56, // 5 ListTiles
                            ),
                            // SEARCH RESULTS LIST
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: poiresultslist.length,
                              itemBuilder: (context, index) {
                                final poi = poiresultslist[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(poi.name),
                                  subtitle: poi.displayAddress != null
                                      ? Text('${poi.city ?? ''}, ${poi.street ?? ''} ${poi.houseNumber ?? ''}')
                                      : null,
                                  onTap: () async {
                                    
                                    await poiController.loadAndSelectPoiById(
                                      poi,
                                    );
                                    final fresh = poiController.getSelectedPoi();
                                    widget.onTapSearchedPoi(fresh!);
                                    DebugService.log('Poi selected from search results');

                                    setState(() {
                                      _searchVisible = false;
                                      _searchController.clear();
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        width: 220,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (err, st) => Container(
                        width: 220,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: Text("Error: $err"),
                      ),
                    ),

                  // END OF SEARCH RESULTS DROPDOWN
                ],
              ),
              FloatingActionButton(
                heroTag: "btn4",
                onPressed: () {
                  setState(() {
                    _searchVisible = !_searchVisible;
                    _searchController.clear();
                  });
                },
                mini: true,
                child: Icon(_searchVisible ? Icons.close : Icons.search),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
