import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:maplibre/maplibre.dart';
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

  const PoiSearch({
    super.key,
    required this.onClose,
    required this.onSelect,
  });

  @override
  ConsumerState<PoiSearch> createState() {
    return _PoiSearchState();
  }
}

class _PoiSearchState extends ConsumerState<PoiSearch> {
  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  final ExpansibleController expansionController =
      ExpansibleController();

  String _searchQuery = '';

  PoiSelectionMode? _lastMode;

  Timer? _searchDebounce;
  Timer? _radiusDebounce;

  double _searchRadiusKm = 5;
  double _appliedSearchRadiusKm = 5;

  PoiSearchMode _searchMode = PoiSearchMode.name;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _radiusDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    expansionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    final searchParams = (
      query: _searchQuery,
      searchActive: true,
      searchMode: _searchMode,
    );

    final searchResults = ref.watch(
      searchResultsProvider(searchParams),
    );

    final mode = ref
        .watch(visiblePoisMenuStateProvider)
        .poiSelectionMode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastMode == mode) {
        return;
      }

      if (mode == PoiSelectionMode.search) {
        expansionController.expand();
      } else {
        expansionController.collapse();
      }

      _lastMode = mode;
    });

    final isAdmin = ref
        .watch(supabaseUserStateProvider)
        .isAdmin;

    final correctedCamera = ref.watch(
      cameraPositionPanelCorrectedProvider,
    );

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
        minVerticalPadding: 0,
        child: ExpansionTile(
          key: const ValueKey<String>(
            'search_tile',
          ),
          tilePadding: const EdgeInsets.only(
            left: 0,
            right: 15,
          ),
          childrenPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          initiallyExpanded: false,
          controller: expansionController,
          collapsedShape: const Border(),
          shape: const Border(),
          expandedCrossAxisAlignment:
              CrossAxisAlignment.start,
          expandedAlignment: Alignment.topLeft,
          onExpansionChanged: (value) {
            ref
                .read(
                  visiblePoisMenuStateProvider.notifier,
                )
                .setTileExpanded(
                  'search',
                  value,
                );

            if (value) {
              ref
                  .read(
                    visiblePoisMenuStateProvider.notifier,
                  )
                  .setPoiSelectionMode(
                    PoiSelectionMode.search,
                  );
            }
          },
          title: Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  getText(
                    'search',
                    languageCode: languageCode,
                    countryCode: countryCode,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: showTagInfoModal,
                  icon: const Icon(
                    Icons.question_mark,
                  ),
                ),
            ],
          ),
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 300,
                    padding:
                        const EdgeInsets.fromLTRB(
                      6,
                      0,
                      4,
                      0,
                    ),
                    margin:
                        const EdgeInsets.only(
                      bottom: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: TextField(
                      key: const ValueKey<String>(
                        'poi_search_text_field',
                      ),
                      controller:
                          _searchController,
                      focusNode:
                          _searchFocusNode,
                      autofocus: false,
                      decoration:
                          InputDecoration(
                        hintText: _searchMode ==
                                PoiSearchMode.name
                            ? 'Suche nach Name'
                            : 'Suche nach Adresse',
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.fromLTRB(
                          0,
                          8,
                          0,
                          8,
                        ),
                        isDense: true,
                      ),
                      onChanged: _onSearchChanged,
                      onTap: () {
                        ref
                            .read(
                              searchSelectionProvider
                                  .notifier,
                            )
                            .clear();
                      },
                      onTapOutside: (_) {
                        _searchFocusNode.unfocus();
                      },
                    ),
                  ),
                  RadioGroup<PoiSearchMode>(
                    groupValue: _searchMode,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      _setSearchMode(value);
                    },
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      children: [
                        InkWell(
                          borderRadius:
                              BorderRadius.circular(8),
                          onTap: () {
                            _setSearchMode(
                              PoiSearchMode.name,
                            );
                          },
                          child: const Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Radio<PoiSearchMode>(
                                value:
                                    PoiSearchMode.name,
                                visualDensity:
                                    VisualDensity.compact,
                              ),
                              Text('Nach Name'),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius:
                              BorderRadius.circular(8),
                          onTap: () {
                            _setSearchMode(
                              PoiSearchMode.address,
                            );
                          },
                          child: const Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Radio<PoiSearchMode>(
                                value:
                                    PoiSearchMode.address,
                                visualDensity:
                                    VisualDensity.compact,
                              ),
                              Text('Nach Adresse'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  4,
                  8,
                  4,
                  4,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                            '${getText(
                              'searchRadius',
                              languageCode:
                                  languageCode,
                              countryCode:
                                  countryCode,
                            )}: ${_formatRadius(_searchRadiusKm)}',
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: 0.5,
                      max: 20,
                      divisions: null,
                      value: _searchRadiusKm,
                      label: _formatRadius(
                        _searchRadiusKm,
                      ),
                      onChanged: (value) {
                        _radiusDebounce?.cancel();

                        setState(() {
                          _searchRadiusKm = value;
                        });

                        _radiusDebounce = Timer(
                          const Duration(
                            milliseconds: 500,
                          ),
                          () {
                            if (!mounted) {
                              return;
                            }

                            setState(() {
                              _appliedSearchRadiusKm =
                                  _searchRadiusKm;
                            });
                          },
                        );
                      },
                      onChangeEnd: (value) {
                        _radiusDebounce?.cancel();

                        setState(() {
                          _searchRadiusKm = value;
                          _appliedSearchRadiusKm =
                              value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            if (_searchQuery.isNotEmpty)
              searchResults.when(
                data: (foundPois) {
                  final radiusMeters =
                      _appliedSearchRadiusKm *
                      1000;

                  final filteredPois =
                      foundPois.where((poi) {
                    final distanceMeters =
                        geoDistanceMeters(
                      Geographic(
                        lon: poi.location.lon,
                        lat: poi.location.lat,
                      ),
                      correctedCamera,
                    );

                    return distanceMeters <=
                        radiusMeters;
                  }).toList(growable: false);

                  if (filteredPois.isEmpty) {
                    return Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        5,
                        15,
                        0,
                        0,
                      ),
                      child: Text(
                        getText(
                          'noPoiFound',
                          languageCode:
                              languageCode,
                          countryCode:
                              countryCode,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          5,
                          15,
                          0,
                          0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                getText(
                                  'results',
                                  languageCode:
                                      languageCode,
                                  countryCode:
                                      countryCode,
                                ),
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              padding:
                                  EdgeInsets.zero,
                              visualDensity:
                                  VisualDensity
                                      .compact,
                              icon:
                                  const Iconify(
                                Mdi.check_all,
                                color:
                                    Colors.black87,
                                size: 24,
                              ),
                              onPressed: () {
                                ref
                                    .read(
                                      poiSelectionProvider
                                          .notifier,
                                    )
                                    .setAll(
                                      filteredPois,
                                    );
                              },
                            ),
                            IconButton(
                              padding:
                                  EdgeInsets.zero,
                              visualDensity:
                                  VisualDensity
                                      .compact,
                              icon:
                                  const Iconify(
                                Mdi
                                    .checkbox_blank_off_outline,
                                color:
                                    Colors.black87,
                                size: 20,
                              ),
                              onPressed: () {
                                ref
                                    .read(
                                      poiSelectionProvider
                                          .notifier,
                                    )
                                    .clear();
                              },
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount:
                            filteredPois.length,
                        itemBuilder:
                            (context, index) {
                          final poi =
                              filteredPois[index];

                          return PoiListItem(
                            selectEnabled: true,
                            poi: poi,
                            onTap: () {
                              _handlePoiSelection(
                                poi,
                              );

                              ref
                                  .read(
                                    selectedPoiProvider
                                        .notifier,
                                  )
                                  .setPoi(poi);

                              widget.onClose();
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
                loading: () {
                  return const Padding(
                    padding:
                        EdgeInsets.fromLTRB(
                      4,
                      12,
                      4,
                      4,
                    ),
                    child:
                        LinearProgressIndicator(
                      minHeight: 3,
                    ),
                  );
                },
                error: (error, stackTrace) {
                  return Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      5,
                      15,
                      0,
                      0,
                    ),
                    child: Text(
                      '${getText(
                        'error',
                        languageCode:
                            languageCode,
                        countryCode:
                            countryCode,
                      )}: $error',
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(
    String value,
  ) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 350,
      ),
      () {
        if (!mounted) {
          return;
        }

        final keepFocus =
            _searchFocusNode.hasFocus;

        setState(() {
          _searchQuery = value.trim();
        });

        if (keepFocus) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            _searchFocusNode.requestFocus();

            _searchController.selection =
                TextSelection.collapsed(
              offset:
                  _searchController.text.length,
            );
          });
        }
      },
    );
  }

  String _formatRadius(
    double radiusKm,
  ) {
    return '${radiusKm.toStringAsFixed(1)} km';
  }

  void _handlePoiSelection(
    PointOfInterest poi,
  ) {
    _searchFocusNode.unfocus();

    widget.onSelect(poi);

    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> showTagInfoModal() async {
    final osmKeysJson =
        await rootBundle.loadString(
      'assets/data/osm_keys.json',
    );

    if (!mounted) {
      return;
    }

    final message =
        'Suche nach benannten Objekten:\n'
        '"osmn" Suchbegriff\n\n'
        'Suche nach Gebäuden:\n'
        '"osmb" Suchbegriff\n\n'
        'Suche nach Tags:\n'
        'OSM tag key=value '
        '(value optional) Suchbegriff\n\n'
        'Verfügbare Keys und Values:\n\n'
        '$osmKeysJson';

    messageBox(
      context,
      message,
      'Hinweis für Admin Suchsyntax',
    );
  }

  void _setSearchMode(
    PoiSearchMode searchMode,
  ) {
    if (_searchMode == searchMode) {
      return;
    }

    _searchDebounce?.cancel();

    final keepFocus =
        _searchFocusNode.hasFocus;

    setState(() {
      _searchMode = searchMode;
      _searchQuery =
          _searchController.text.trim();
    });

    ref
        .read(
          searchSelectionProvider.notifier,
        )
        .clear();

    if (keepFocus) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _searchFocusNode.requestFocus();

        _searchController.selection =
            TextSelection.collapsed(
          offset:
              _searchController.text.length,
        );
      });
    }
  }
}