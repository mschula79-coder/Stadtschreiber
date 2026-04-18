import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/game_icons.dart';
import 'package:iconify_flutter/icons/maki.dart';
import 'package:stadtschreiber/models/history_entry.dart';
import 'package:stadtschreiber/models/image_entry.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_drag_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_stats_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/widgets/modal_history_edit.dart';
import 'package:stadtschreiber/widgets/modal_image_edit.dart';
import 'package:stadtschreiber/widgets/poi_photo_gallery_modal.dart';
import 'package:stadtschreiber/widgets/poi_rating_editor_dialog.dart';
import 'package:stadtschreiber/widgets/poi_rating_list.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article_entry.dart';
import '../models/poi.dart';

import '../utils/url_utils.dart';

import '../widgets/_editable_list.dart';
import 'modal_bool_features_editor.dart';
import 'modal_string_features_editor.dart';
import 'modal_article_edit.dart';
import '../widgets/category_node_tile.dart';

class PoiPanelTabs extends ConsumerStatefulWidget {
  const PoiPanelTabs({super.key});

  @override
  ConsumerState<PoiPanelTabs> createState() => _PoiPanelTabsState();
}

class _PoiPanelTabsState extends ConsumerState<PoiPanelTabs> {
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController featuredImageUrlController =
      TextEditingController();
  late final TextEditingController descriptionController =
      TextEditingController();

  bool _listenerRegistered = false;
  late final ProviderSubscription<PointOfInterest?> _sub;
  late final PoiDragNotifier dragPoiNotifier;

  @override
  void initState() {
    super.initState();
    dragPoiNotifier = ref.read(dragPoiProvider.notifier);
  }

  @override
  void dispose() {
    _sub.close();
    nameController.dispose();
    featuredImageUrlController.dispose();
    descriptionController.dispose();
    super.dispose();
    DebugService.log('Dispose PoiPanelTabs');
  }

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build PoiPanelTabs');
    final selectedPoi = ref.watch(selectedPoiProvider);
    if (selectedPoi == null) return const SizedBox.shrink();

    final bool isEditModeEnabled = ref.watch(appStateProvider).isPoiEditMode;

    if (!_listenerRegistered) {
      _listenerRegistered = true;

      // 1. Listener registrieren
      _sub = ref.listenManual<PointOfInterest?>(selectedPoiProvider, (
        prev,
        next,
      ) {
        if (next != null) {
          setState(() {
            nameController.text = next.name;
            featuredImageUrlController.text = next.featuredImageUrl ?? '';
            descriptionController.text = next.description ?? '';
          });
        }
      });

      // 2. Initialen Wert manuell setzen
      final current = ref.read(selectedPoiProvider);
      if (current != null) {
        nameController.text = current.name;
        featuredImageUrlController.text = current.featuredImageUrl ?? '';
        descriptionController.text = current.description ?? '';
        DebugService.log(
          'Initial values set in PoiPanelTabs Name: ${current.name}',
        );
      }
    }

    final tabs = [
      const Tab(
        icon: Tooltip(message: "Info", child: Icon(Icons.info_outline)),
      ),
      const Tab(
        icon: Tooltip(
          message: "Photo Gallery",
          child: Iconify(
            Mdi.image_multiple_outline,
            size: 24,
            color: Colors.black,
          ),
        ),
      ),
      const Tab(
        icon: Tooltip(message: "Ratings", child: Icon(Icons.star)),
      ),

      const Tab(
        icon: Tooltip(
          message: "History",
          child: Iconify(Mdi.historic, size: 24),
        ),
      ),
      const Tab(
        icon: Tooltip(
          message: "Stories and articles",
          child: Iconify(Mdi.book_open_blank_variant, size: 24),
        ),
      ),
    ];

    final pages = [
      _buildInfoTab(selectedPoi, isEditModeEnabled),
      _buildGalleryTab(selectedPoi, isEditModeEnabled),
      _buildRatingsTab(selectedPoi),
      _buildHistoryTab(selectedPoi, isEditModeEnabled),
      _buildArticlesTab(selectedPoi, isEditModeEnabled),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        DebugService.log("PoiPanelTabs constraints: $constraints");

        return DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: tabs,
                tabAlignment: TabAlignment.start,
              ),
              Expanded(child: TabBarView(children: pages)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(PointOfInterest selectedPoi, bool isEditModeEnabled) {
    final location = selectedPoi.location;
    final pts = selectedPoi.getPoints();
    final pointsList = pts == null
        ? <String>[]
        : pts
              .map(
                (p) =>
                    "${p.lat.toStringAsFixed(6)}, ${p.lon.toStringAsFixed(6)}",
              )
              .toList();

    final appState = ref.watch(appStateProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Edit Button
          Stack(
            children: [
              TextField(
                controller: nameController,
                readOnly: true,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: "Name",
                  alignLabelWithHint: true,
                  contentPadding: EdgeInsets.fromLTRB(0, 0, 35, 5),
                ),
              ),
              isEditModeEnabled
                  ? Positioned(
                      right: 0,
                      top: 5,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final newValue = await _openEditModal(
                            context,
                            "Name",
                            nameController.text,
                            1,
                          );
                          if (newValue != null) {
                            nameController.text = newValue;
                            ref
                                .read(poiRepositoryProvider)
                                .updatePoiDataInSupabase(
                                  id: selectedPoi.id,
                                  name: newValue,
                                );
                            ref
                                .read(selectedPoiProvider.notifier)
                                .setPoi(
                                  selectedPoi.copyWith(
                                    name: newValue,
                                  ),
                                );
                            //ref.invalidate(visiblePoisProvider);

                            setState(() {});
                          }
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),

          // Stack Beschreibung mit Bearbeitung
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelText: "Beschreibung",
                  alignLabelWithHint: true,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 0, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 10, 0, 5),
                ),
                child: SizedBox(
                  height: 80,
                  child: SingleChildScrollView(
                    child: Text(descriptionController.text, softWrap: true),
                  ),
                ),
              ),
              // Edit button
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newValue = await _openEditModal(
                        context,
                        "Beschreibung",
                        descriptionController.text,
                        10,
                      );
                      if (newValue != null) {
                        descriptionController.text = newValue;
                        ref
                            .read(poiRepositoryProvider)
                            .updatePoiDataInSupabase(
                              id: selectedPoi.id,
                              description: newValue,
                            );
                        ref
                            .read(selectedPoiProvider.notifier)
                            .setPoi(
                              selectedPoi.copyWith(
                                description: newValue,
                              ),
                            );
                      }
                    },
                  ),
                ),
            ],
          ),

          // Textfeld Adresse read only
          InputDecorator(
            decoration: InputDecoration(
              labelText: "Adresse",
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
            ),
            child: selectedPoi.displayAddress == null
                ? Text('')
                : Text(
                    '${selectedPoi.city ?? ''}, ${selectedPoi.street ?? ''} ${selectedPoi.houseNumber ?? ''}',
                  ),
          ),

          // Stack links editable
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Links",
                  alignLabelWithHint: true,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 10, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 10, 0, 5),
                ),
                child: Row(
                  children: [
                    SizedBox(height: 20, width: 0),
                    selectedPoi.metadata.getWebsiteLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getWebsiteLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.internet, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),

                    selectedPoi.metadata.getGoogleMapsLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getGoogleMapsLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.google_maps, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.getOSMLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getOSMLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.map, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.getAppleMapsLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getAppleMapsLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.apple, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.getWikipediaLink().isNotEmpty
                        ? InkWell(
                            onTap: () => openLink(
                              context,
                              selectedPoi.metadata.getWikipediaLink(),
                            ),
                            child: Row(
                              children: [
                                Iconify(Mdi.wikipedia, size: 24),
                                const SizedBox(width: 10),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              //Edit links
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newLinks = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (_) => StringFeaturesEditorDialog(
                          dialogTitle: "Links bearbeiten",
                          initialValues: selectedPoi.metadata.getLinks(),
                        ),
                      );
                      final updatedPoi = selectedPoi.copyWith();
                      if (newLinks != null) {
                        updatedPoi.metadata.setLinks(newLinks);
                      }
                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            metadata: updatedPoi.metadata,
                          );

                      ref.read(selectedPoiProvider.notifier).setPoi(updatedPoi);
                      //ref.invalidate(visiblePoisProvider);
                    },
                  ),
                ),
            ],
          ),

          // Feature icons editable
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Features",
                  alignLabelWithHint: true,
                  contentPadding: isEditModeEnabled
                      ? const EdgeInsets.fromLTRB(0, 10, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 10, 0, 5),
                ),
                child: Row(
                  children: [
                    SizedBox(height: 20, width: 0),
                    selectedPoi.metadata.notBBQAllowed()
                        ? Row(
                            children: [
                              Iconify(Mdi.fire_off, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.isWheelchairAccessible()
                        ? Row(
                            children: [
                              Iconify(Mdi.wheelchair_accessibility, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.hasBenches()
                        ? Row(
                            children: [
                              Iconify(GameIcons.park_bench, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    selectedPoi.metadata.hasPicnicTables()
                        ? Row(
                            children: [
                              Iconify(Maki.picnic_site, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              // Edit features
              if (isEditModeEnabled)
                Positioned(
                  right: 0,
                  top: 5,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newFeatures = await showDialog<Map<String, bool>>(
                        context: context,
                        builder: (_) => BoolFeaturesEditorDialog(
                          dialogTitle: "Features bearbeiten",
                          initialFeatures: selectedPoi.metadata.getFeatures(),
                        ),
                      );
                      final newPoi = selectedPoi.copyWith();
                      newPoi.metadata.setFeatures(newFeatures!);
                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            metadata: newPoi.metadata,
                          );
                      ref.read(selectedPoiProvider.notifier).setPoi(newPoi);
                      //ref.invalidate(visiblePoisProvider);
                    },
                  ),
                ),
            ],
          ),

          // Kategorien bearbeiten
          if (isEditModeEnabled) ...[
            const SizedBox(height: 20),
            Text(
              'Kategorien bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // Kategorien Liste
            Consumer(
              builder: (context, ref, _) {
                final categories = ref.watch(categoriesProvider).categories;

                if (categories.isEmpty) {
                  return const Text("Keine Kategorien geladen");
                }

                return ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: categories
                      .map((root) => PoiCategoryNodeTile(node: root))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          if (isEditModeEnabled) ...[
            // Standort und Geometrie
            Text(
              'Standort und Geometrie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 15),
            Padding(
              padding: EdgeInsetsGeometry.only(right: 25),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Label Standort: Lat: ${location.lat} Lon: ${location.lon}',
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      ref
                          .read(dragPoiProvider.notifier)
                          .startDraggingPoiMode(selectedPoi);
                    },
                    child: Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            // Geometriepunkte bearbeiten
            const SizedBox(height: 5),
            SwitchListTile(
              title: const Text('Geometriepunkte bearbeiten'),
              contentPadding: const EdgeInsets.only(left: 0, right: 0),
              value: appState.isPoiGeomEditMode,
              onChanged: (newValue) {
                ref
                    .read(appStateProvider.notifier)
                    .setPoiGeomEditMode(newValue);
                if (newValue) {
                  ref.read(dragPoiProvider.notifier).setDragPoi(selectedPoi);
                }
              },
            ),
            const SizedBox(height: 5),
            buildGeometryTypeSelector(context, selectedPoi),
            const SizedBox(height: 5),

            const Text(
              'Punkte von 2D Geometrien (tippe lange auf die Karte, um weitere Punkte hinzuzufügen):',
            ),
            EditableList<String>(
              items: pointsList,
              isEditModeEnabled: true,
              itemBuilder: (entry) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 15),
                  child: Text(entry, style: const TextStyle(fontSize: 16)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(PointOfInterest selectedPoi, bool isEditModeEnabled) {
    final historyEntries = selectedPoi.historyEntries;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 16),
                EditableList<HistoryEntry>(
                  items: historyEntries,
                  isEditModeEnabled: isEditModeEnabled,
                  onAdd: () async {
                    final newEntry = await showDialog<HistoryEntry>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const HistoryEditModal(
                        initialStart: "",
                        initialEnd: "",
                        initialDescription: "",
                      ),
                    );

                    if (newEntry != null) {
                      final updated = [...historyEntries, newEntry];
                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            historyEntries: updated,
                          );
                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(
                            selectedPoi.copyWith(
                              historyEntries: updated,
                            ),
                          );
                      //ref.invalidate(visiblePoisProvider);
                    }

                    return newEntry;
                  },
                  onEdit: (entry) async {
                    final updatedEntry = await showDialog<HistoryEntry>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => HistoryEditModal(
                        initialStart: entry.rawStart,
                        initialEnd: entry.rawEnd,
                        initialDescription: entry.description,
                      ),
                    );

                    if (updatedEntry != null) {
                      final updated = [...historyEntries];
                      final index = updated.indexOf(entry);
                      updated[index] = updatedEntry;

                      ref
                          .read(poiRepositoryProvider)
                          .updatePoiDataInSupabase(
                            id: selectedPoi.id,
                            historyEntries: updated,
                          );
                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(
                            selectedPoi.copyWith(
                              historyEntries: updated,
                            ),
                          );
                      //ref.invalidate(visiblePoisProvider);
                    }

                    return updatedEntry;
                  },
                  onDelete: (entry) async {
                    final updated = [...historyEntries]..remove(entry);
                    ref
                        .read(poiRepositoryProvider)
                        .updatePoiDataInSupabase(
                          id: selectedPoi.id,
                          historyEntries: updated,
                        );
                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(
                          selectedPoi.copyWith(
                            historyEntries: updated,
                          ),
                        );
                  },
                  itemBuilder: (entry) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: entry.getLabel(),
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.fromLTRB(0, 0, 20, 10),
                          border:
                              UnderlineInputBorder(), // oder OutlineInputBorder()
                        ),
                        child: Text(
                          entry.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesTab(
    PointOfInterest selectedPoi,
    bool isEditModeEnabled,
  ) {
    final articles = selectedPoi.articles;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(height: 16),
            EditableList<ArticleEntry>(
              items: articles,
              isEditModeEnabled: isEditModeEnabled,
              onAdd: () async {
                final newEntry = await showDialog<ArticleEntry>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const ArticleEditModal(
                    initialTitle: "",
                    initialUrl: "",
                    initialSource: '',
                  ),
                );

                if (newEntry != null) {
                  final updated = [...articles, newEntry];
                  ref
                      .read(poiRepositoryProvider)
                      .updatePoiDataInSupabase(
                        id: selectedPoi.id,
                        articles: updated,
                      );
                  ref
                      .read(selectedPoiProvider.notifier)
                      .setPoi(
                        selectedPoi.copyWith(articles: updated),
                      );
                  //ref.invalidate(visiblePoisProvider);
                }

                return newEntry;
              },
              onEdit: (entry) async {
                final updatedEntry = await showDialog<ArticleEntry>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ArticleEditModal(
                    initialTitle: entry.title,
                    initialUrl: entry.url,
                    initialSource: entry.source,
                  ),
                );

                if (updatedEntry != null) {
                  final updated = [...articles];
                  final index = updated.indexOf(entry);
                  updated[index] = updatedEntry;

                  ref
                      .read(poiRepositoryProvider)
                      .updatePoiDataInSupabase(
                        id: selectedPoi.id,
                        articles: updated,
                      );
                  ref
                      .read(selectedPoiProvider.notifier)
                      .setPoi(
                        selectedPoi.copyWith(articles: updated),
                      );
                  //ref.invalidate(visiblePoisProvider);
                  //ref.invalidate(visiblePoisProvider);
                }

                return updatedEntry;
              },
              onDelete: (entry) async {
                final updated = [...articles]..remove(entry);
                ref
                    .read(poiRepositoryProvider)
                    .updatePoiDataInSupabase(
                      id: selectedPoi.id,
                      articles: updated,
                    );
                ref
                    .read(selectedPoiProvider.notifier)
                    .setPoi(selectedPoi.copyWith(articles: updated));
              },
              itemBuilder: (entry) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(entry.url)),
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryTab(PointOfInterest poi, bool isEditModeEnabled) {
    final selectedPoi = ref.watch(selectedPoiProvider);
    final user = ref.watch(supabaseUserStateProvider);
    final username = user.username;
    final imageUrls = poi.images.map((img) => img.url).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          isEditModeEnabled ? SizedBox(height: 15) : SizedBox.shrink(),
          // Featured Image-URL
          isEditModeEnabled
              ? Stack(
                  children: [
                    TextField(
                      controller: featuredImageUrlController,
                      readOnly: true,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        labelText: "Featured Image-URL",
                        alignLabelWithHint: true,
                        contentPadding: EdgeInsets.fromLTRB(0, 0, 35, 0),
                      ),
                    ),

                    Positioned(
                      right: 0,
                      top: 10,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final newValue = await _openEditModal(
                            context,
                            "Featured Image-URL",
                            featuredImageUrlController.text,
                            1,
                          );
                          if (newValue != null) {
                            featuredImageUrlController.text = newValue;
                            ref
                                .read(poiRepositoryProvider)
                                .updatePoiDataInSupabase(
                                  id: selectedPoi!.id,
                                  featuredImageUrl: newValue,
                                );
                            ref
                                .read(selectedPoiProvider.notifier)
                                .setPoi(
                                  selectedPoi.copyWith(
                                    featuredImageUrl: newValue,
                                  ),
                                );
                            //ref.invalidate(visiblePoisProvider);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                )
              : SizedBox.shrink(),
          isEditModeEnabled ? SizedBox(height: 15) : SizedBox.shrink(),

          // Featured image
          (selectedPoi!.featuredImageUrl == null)
              ? const Icon(
                  Icons.image_not_supported,
                  size: 80,
                  color: Colors.grey,
                )
              : Stack(
                  children: [
                    Image.network(
                      selectedPoi.featuredImageUrl!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          size: 80,
                          color: Colors.grey,
                        );
                      },
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon: const Icon(Icons.open_in_new_sharp),
                        onPressed: () => PhotoGalleryModal.open(
                          context,
                          imageUrls: imageUrls,
                        ),
                      ),
                    ),
                  ],
                ),

          // Liste mit ImageUrls
          if (isEditModeEnabled)
            EditableList<ImageEntry>(
              items: selectedPoi.images,
              isEditModeEnabled: isEditModeEnabled,
              onAdd: () async {
                final newEntry = await showDialog<ImageEntry>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ImageEditModal(
                    image: ImageEntry(
                      title: '',
                      url: '',
                      enteredBy: username,
                      creditsName: '',
                      creditsUrl: '',
                    ),
                  ),
                );

                if (newEntry != null) {
                  final currentPoi = ref.read(selectedPoiProvider)!;

                  final updatedImages = [...currentPoi.images, newEntry];

                  ref
                      .read(poiRepositoryProvider)
                      .updatePoiDataInSupabase(
                        id: currentPoi.id,
                        images: updatedImages,
                      );

                  ref
                      .read(selectedPoiProvider.notifier)
                      .setPoi(
                        currentPoi.copyWith(images: updatedImages),
                      );
                }

                return newEntry;
              },
              onEdit: (entry) async {
                final updatedEntry = await showDialog<ImageEntry>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ImageEditModal(
                    image: ImageEntry(
                      title: entry.title,
                      url: entry.url,
                      enteredBy: entry.enteredBy,
                      creditsName: entry.creditsName ?? '',
                      creditsUrl: entry.creditsUrl ?? '',
                    ),
                  ),
                );

                if (updatedEntry != null) {
                  final currentPoi = ref.read(selectedPoiProvider)!;

                  final updatedImages = currentPoi.images.map((img) {
                    return img.url == entry.url ? updatedEntry : img;
                  }).toList();

                  ref
                      .read(poiRepositoryProvider)
                      .updatePoiDataInSupabase(
                        id: currentPoi.id,
                        images: updatedImages,
                      );

                  ref
                      .read(selectedPoiProvider.notifier)
                      .setPoi(
                        currentPoi.copyWith(images: updatedImages),
                      );
                }

                return updatedEntry;
              },

              onDelete: (entry) async {
                final updated = [...selectedPoi.images]..remove(entry);
                ref
                    .read(poiRepositoryProvider)
                    .updatePoiDataInSupabase(
                      id: selectedPoi.id,
                      images: updated,
                    );
                ref
                    .read(selectedPoiProvider.notifier)
                    .setPoi(selectedPoi.copyWith(images: updated));
              },
              itemBuilder: (entry) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(entry.url)),
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 0),
          if (imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...imageUrls.map(
                        (url) => ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: Image.network(url, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),

                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      icon: const Icon(Icons.open_in_new_sharp),
                      onPressed: () =>
                          PhotoGalleryModal.open(context, imageUrls: imageUrls),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // TODO implement multiple categories / category
  Widget _buildRatingsTab(PointOfInterest poi) {
    if (poi.categories != null &&
        poi.categories!.isNotEmpty &&
        poi.categories![0].isNotEmpty) {
      final categoryId = ref.watch(
        categoryIdBySlugProvider(poi.categories![0]),
      );
      if (categoryId != null) {
        final criteria = ref.watch(criteriaForCategoryProvider(categoryId));
        // Überschrift mit PoiRatingList
        return criteria.when(
          data: (list) => Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bewertung',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _openRatingEditor(poi, list),
                      child: Icon(
                        Icons.rate_review,
                        color: Color.fromARGB(255, 42, 23, 86),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PoiRatingList(criteria: list, poi: poi),
                ),
              ],
            ),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text("Fehler: $e"),
        );
      }
    }

    return const Padding(
      padding: EdgeInsets.all(12),
      child: Text('Keine Kategorie gefunden'),
    );
  }

  void _openRatingEditor(
    PointOfInterest poi,
    List<RatingCriterionDTO> criteria,
  ) {
    showDialog(
      context: context,
      builder: (_) => PoiRatingEditorDialog(
        poi: poi,
        criteria: criteria,
        onRatingChanged: (scores, comments) async {
          await ref
              .read(poiRatingRepositoryProvider)
              .saveRatings(poiId: poi.id, scores: scores, comments: comments);

          // UI aktualisieren
          ref.invalidate(poiRatingsProvider(poi.id));
          ref.invalidate(poiUserRatingsProvider(poi.id));
          ref.invalidate(poiRatingStatsProvider(poi.id));
        },
      ),
    );
  }

  Future<String?> _openEditModal(
    BuildContext context,
    String fieldName,
    String initialValue,
    int maxLines,
  ) {
    final tempController = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $fieldName"),
          content: TextField(
            controller: tempController,
            autofocus: false,
            decoration: InputDecoration(labelText: fieldName),
            maxLines: maxLines,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, tempController.text);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Toggle for edit mode
  // Location Point / Label Position
  // List of Points with delete button

  Widget buildGeometryTypeSelector(
    BuildContext context,
    PointOfInterest selectedPoi,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Geometrietyp", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),

        RadioGroup<String>(
          groupValue: selectedPoi.geometryType,
          onChanged: (value) {
            final newPoi = selectedPoi.copyWith(geometryType: value!);

            if (newPoi.isGeometryValid()) {
              final poiRepository = ref.read(poiRepositoryProvider);
              poiRepository.updatePoiGeomInSupabase(newPoi);
            }
            ref.read(appStateProvider.notifier).setPoiGeomEditMode(false);
            ref.read(selectedPoiProvider.notifier).setPoi(newPoi);
            //ref.invalidate(visiblePoisProvider);
          },
          child: Column(
            children: <Widget>[
              const ListTile(
                title: Text('Punkt'),
                leading: Radio<String>(toggleable: true, value: 'point'),
              ),
              const ListTile(
                title: Text('Linie'),
                leading: Radio<String>(toggleable: true, value: 'linestring'),
              ),
              const ListTile(
                title: Text('Polygon'),
                leading: Radio<String>(toggleable: true, value: 'polygon'),
              ),
              const ListTile(
                title: Text('MultiPolygon'),
                leading: Radio<String>(toggleable: true, value: 'multipolygon'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
