import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:maplibre/maplibre.dart';
import 'dart:async';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/poi_selection_modes.dart';
import 'package:stadtschreiber/provider/camera_provider.dart';
import 'package:stadtschreiber/provider/locale_provider.dart';
import 'package:stadtschreiber/provider/poi_selection_provider.dart';
import 'package:stadtschreiber/provider/search_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/provider/visible_pois_menu_state_provider.dart';
import 'package:stadtschreiber/services/geo_service.dart';
import 'package:stadtschreiber/utils/language_utils.dart';
import 'package:stadtschreiber/widgets/modal_message_box.dart';
import 'package:stadtschreiber/widgets/poi_list_item.dart';

class PoiSearch extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(PointOfInterest) onSelect;

  const PoiSearch({super.key, required this.onClose, required this.onSelect});

  @override
  ConsumerState<PoiSearch> createState() => _PoiSearchState();
}

class _PoiSearchState extends ConsumerState<PoiSearch> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final ExpansibleController expansionController = ExpansibleController();

  PoiSelectionMode? _lastMode;

  Timer? _searchDebounce;

  Timer? _radiusDebounce;

  double _searchRadiusKm = 5;
  double _appliedSearchRadiusKm = 5;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    expansionController.dispose();
    _searchDebounce?.cancel();
    _radiusDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    final countryCode = ref.watch(localeProvider).countryCode;


    final searchParams = (query: _searchQuery, searchActive: true);

    final searchResults = ref.watch(searchResultsProvider(searchParams));

    final mode = ref.watch(visiblePoisMenuStateProvider).poiSelectionMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lastMode != mode) {
        if (mode == PoiSelectionMode.search) {
          expansionController.expand();
        } else {
          expansionController.collapse();
        }
        _lastMode = mode;
      }
    });

    final isAdmin = ref.watch(supabaseUserStateProvider).isAdmin;

    final correctedCamera = ref.watch(cameraPositionPanelCorrectedProvider);

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
          controller: expansionController,

          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          onExpansionChanged: (value) {
            ref
                .read(visiblePoisMenuStateProvider.notifier)
                .setTileExpanded("search", value);

            if (value) {
              ref
                  .read(visiblePoisMenuStateProvider.notifier)
                  .setPoiSelectionMode(PoiSelectionMode.search);
            } else {
              expansionController.collapse();
            }
          },

          title: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade600),
              SizedBox(width: 8),

              Expanded(
                child: Text(
                  getText('search', languageCode: languageCode, countryCode: countryCode),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              isAdmin
                  ? IconButton(
                      onPressed: () {
                        showTagInfoModal();
                      },
                      icon: Icon(Icons.question_mark),
                    )
                  : SizedBox.shrink(),
            ],
          ),

          children: [
            SizedBox(height: 3),

            Container(
              width: 300,
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
                  _searchDebounce?.cancel();

                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () {
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  );
                },
                onTap: () {
                  ref.read(searchSelectionProvider.notifier).clear();
                },
                onTapOutside: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),

            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.radar,
                          size: 20,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${getText('searchRadius', languageCode: languageCode, countryCode: countryCode)}: ${_formatRadius(_searchRadiusKm)}',

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // categories slider
                    Slider(
                      min: 0.5,
                      max: 20,
                      divisions: null,
                      value: _searchRadiusKm,
                      label: _formatRadius(_searchRadiusKm),
                      onChanged: (value) {
                        _radiusDebounce?.cancel();

                        setState(() {
                          _searchRadiusKm = value;
                        });

                        _radiusDebounce = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            if (!mounted) {
                              return;
                            }

                            setState(() {
                              _appliedSearchRadiusKm = _searchRadiusKm;
                            });
                          },
                        );
                      },
                      onChangeEnd: (value) {
                        _radiusDebounce?.cancel();

                        setState(() {
                          _searchRadiusKm = value;
                          _appliedSearchRadiusKm = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

            if (_searchQuery.isNotEmpty)
              searchResults.when(
                data: (foundPois) {
                  final radiusMeters = _appliedSearchRadiusKm * 1000;
                  final filteredPois = foundPois.where((poi) {
                    final distanceMeters = geoDistanceMeters(
                      Geographic(lon: poi.location.lon, lat: poi.location.lat),
                      correctedCamera,
                    );

                    return distanceMeters <= radiusMeters;
                  }).toList();

                  // TODO Check ob benötigt
                  /* WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ref
                          .read(searchSelectionProvider.notifier)
                          .setAll(foundPois);
                    }
                  }); */
                  if (filteredPois.isEmpty) {
                    return Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(5, 15, 0, 0),
                      child: Text(
                        getText('noPoiFound', languageCode: languageCode, countryCode: countryCode),
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  getText(
                                    'results',
                                    languageCode: languageCode, countryCode: countryCode,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
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
                                  ref
                                      .read(poiSelectionProvider.notifier)
                                      .setAll(filteredPois);
                                },
                              ),
                              // Alle de-markieren
                              IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                icon: const Iconify(
                                  Mdi.checkbox_multiple_blank_outline,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                                onPressed: () {
                                  ref
                                      .read(poiSelectionProvider.notifier)
                                      .clear();
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredPois.length,
                          itemBuilder: (context, index) {
                            return PoiListItem(
                              selectEnabled: true,
                              poi: filteredPois[index],
                              onTap: () async {
                                final poi = filteredPois[index];

                                _handlePoiSelection(poi);

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
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text(
                  "${getText('error', languageCode: languageCode, countryCode: countryCode)}: $err",
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatRadius(double radiusKm) {
    return '${radiusKm.toStringAsFixed(1).replaceAll('.', '.')} km';
  }

  void _handlePoiSelection(PointOfInterest poi) {
    // hier ist alles wieder synchron, kein async, kein await

    FocusScope.of(context).unfocus(); // Tastatur weg
    widget.onSelect(poi); // POI-Panel öffnen

    setState(() {
      _searchController.clear();
    });
  }

  Future<void> showTagInfoModal() async {
    final osmKeysJson = await rootBundle.loadString(
      'assets/data/osm_keys.json',
    );

    if (!mounted) return;

    final message =
        'Suche nach benannten Objekten:\n'
        '"osmn" Suchbegriff\n\n'
        '\n\n'
        'Suche nach Gebäuden (buildings):\n'
        '"osmb" Suchbegriff\n\n'
        '\n\n'
        'Suche nach tags:\n'
        'OSM tag key=value (value optional) Suchbegriff\n\n'
        'Verfügbare Keys & Values:\n\n'
        '$osmKeysJson';

    messageBox(context, message, 'Hinweis für Admin Suchsyntax');
  }
}
