import 'package:flutter/material.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:provider/provider.dart';

import '../controllers/poi_controller.dart';
import '../models/poi.dart';

class MapActions extends StatefulWidget {
  final VoidCallback onChangeStyle;
  final VoidCallback onLocateMe;
  final VoidCallback onRemoveThumbnails;
  final VoidCallback onToggleAdminView;
  final bool isAdmin =false;
  final bool isAdminViewEnabled =false;


  final Future<void> Function(PointOfInterest) onSelectPoi;

  const MapActions({
    super.key,
    required this.onChangeStyle,
    required this.onSelectPoi,
    required this.onLocateMe,
    required this.onRemoveThumbnails,
    required this.onToggleAdminView,
    required bool isAdmin,
    required bool isAdminViewEnabled,
  });

  @override
  State<MapActions> createState() => _MapActionsState();
}

class _MapActionsState extends State<MapActions> {
  bool _searchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  List<PointOfInterest> _results = [];

  @override
  Widget build(BuildContext context) {
    final poiController = context.read<PoiController>();
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          //toggle admin view
          if (widget.isAdmin)
            FloatingActionButton(
              heroTag: "btn6",
              onPressed: () {
                widget.onToggleAdminView();
              },
              mini: true,
              child: widget.isAdminViewEnabled
                  // print(Theme.of(context).colorScheme.onSecondaryContainer); //🎨 Hex: #101C2B
                  ? const Icon(Icons.construction, color:  Color(0xFF101C2B))
                  : const Icon(Icons.construction_outlined, color:Colors.grey),
            ),
          
          FloatingActionButton(
            heroTag: "btn3",
            onPressed: () {
              widget.onLocateMe();
            },
            mini: true,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),

          //change style
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: widget.onChangeStyle,
            mini: true,
            child: const Icon(Icons.color_lens_outlined),
          ),
          const SizedBox(height: 12),
          //remove thumbnails
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: () {
              widget.onRemoveThumbnails();
            },
            mini: true,

            child: const Iconify(Mdi.pin_off_outline, size: 24),
          ),
          const SizedBox(height: 12),

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
                          poiController.searchRemote(value).then((list) {
                            if (!mounted) return;
                            setState(() => _results = list);
                          });
                        },
                      ),
                    ),
                  // END OF SEARCH FIELD (only visible when toggled)
                  if (_searchVisible && _results.isNotEmpty)
                    Container(
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
                          maxHeight: 5 * 56, // 5 ListTiles, each ~56px high
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final poi = _results[index];
                            return ListTile(
                              dense: true,
                              title: Text(poi.name),
                              subtitle: poi.categories.isNotEmpty
                                  ? Text(poi.categories.join(", "))
                                  : null,
                              onTap: () async {
                                await poiController.loadPoiById(poi, poi.categories);
                                widget.onSelectPoi(poi);
                                setState(() {
                                  _searchVisible = false;
                                  _searchController.clear();
                                  _results = [];
                                });
                              },
                            );
                          },
                        ),
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
                    _results = [];
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
