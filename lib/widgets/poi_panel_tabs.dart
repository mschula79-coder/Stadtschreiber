import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/game_icons.dart';
import 'package:iconify_flutter/icons/maki.dart';
import 'package:provider/provider.dart' as provider;
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/state/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article_entry.dart';
import '../models/poi.dart';

import '../repositories/category_repository.dart';
import '../repositories/poi_repository.dart';

import '../utils/url_utils.dart';
import '../utils/message_utils.dart';

import '../widgets/_editable_list.dart';
import '../widgets/_bool_features_editor_dialog.dart';
import '../widgets/_string_features_editor_dialog.dart';
import '../widgets/article_edit_modal.dart';
import '../widgets/category_node_tile.dart';

class PoiPanelTabs extends ConsumerStatefulWidget {
  const PoiPanelTabs({super.key});

  @override
  ConsumerState<PoiPanelTabs> createState() => _PoiPanelTabsState();
}

class _PoiPanelTabsState extends ConsumerState<PoiPanelTabs> {
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController historyController = TextEditingController();
  late final TextEditingController featuredImageUrlController =
      TextEditingController();
  late final TextEditingController descriptionController =
      TextEditingController();

  bool _listenerRegistered = false;
  late final ProviderSubscription<PointOfInterest?> _sub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _sub.close();
    nameController.dispose();
    historyController.dispose();
    featuredImageUrlController.dispose();
    descriptionController.dispose();
    context.read<AppState>().setPoiEditMode(false);
    super.dispose();
    DebugService.log('Dispose PoiPanelTabs');
  }

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build PoiPanelTabs');

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
            historyController.text = next.history ?? '';
            featuredImageUrlController.text = next.featuredImageUrl;
            descriptionController.text = next.description ?? '';
          });
        }
      });

      // 2. Initialen Wert manuell setzen
      final current = ref.read(selectedPoiProvider);
      if (current != null) {
        nameController.text = current.name;
        historyController.text = current.history ?? '';
        featuredImageUrlController.text = current.featuredImageUrl;
        descriptionController.text = current.description ?? '';
        DebugService.log(
          'Initial values set in PoiPanelTabs Name: ${current.name}',
        );
      }
    }

    final bool isAdminViewEnabled = context
        .watch<AppState>()
        .isAdminViewEnabled;

    final selectedPoi = ref.watch(selectedPoiProvider);

    if (selectedPoi == null) {
      return const SizedBox.shrink();
    }

    final tabs = [
      const Tab(
        icon: Tooltip(
          message: "Featured Image",
          child: Icon(Icons.photo_outlined),
        ),
      ),
      const Tab(
        icon: Tooltip(message: "Info", child: Icon(Icons.info_outline)),
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
    ];
    if (isAdminViewEnabled) {
      tabs.add(
        const Tab(
          icon: Tooltip(message: "Edit entries", child: Icon(Icons.edit)),
        ),
      );
    }
    if (isAdminViewEnabled) {
      tabs.add(
        const Tab(
          icon: Tooltip(
            message: "Edit point of interest",
            child: Icon(Icons.my_location),
          ),
        ),
      );
    }
    final pages = [
      _buildFeaturedImageTab(selectedPoi),
      _buildInfoTab(selectedPoi, isAdminViewEnabled),
      _buildHistoryTab(selectedPoi, isAdminViewEnabled),
      _buildArticlesTab(selectedPoi, isAdminViewEnabled),
      _buildGalleryTab(selectedPoi),
      _buildRatingsTab(selectedPoi),
    ];

    if (isAdminViewEnabled) {
      pages.add(_buildEditTab(selectedPoi, isAdminViewEnabled));
    }
    if (isAdminViewEnabled) {
      pages.add(_buildPoiEditTab(selectedPoi));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(isScrollable: true, tabs: tabs),
          Expanded(child: TabBarView(children: pages)),
        ],
      ),
    );
  }

  Widget _buildFeaturedImageTab(PointOfInterest poi) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: (poi.featuredImageUrl.isEmpty)
          ? const Icon(Icons.image_not_supported, size: 80, color: Colors.grey)
          : Image.network(
              poi.featuredImageUrl,
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
    );
  }

  Widget _buildInfoTab(PointOfInterest selectedPoi, bool isAdminViewEnabled) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack Beschreibung mit Bearbeitung
          Stack(
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelText: "Beschreibung",
                  alignLabelWithHint: true,
                  contentPadding: isAdminViewEnabled
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
              if (isAdminViewEnabled)
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
                        await PoiRepository.updatePoiDataInSupabase(
                          selectedPoi.id!,
                          selectedPoi.name,
                          selectedPoi.history,
                          selectedPoi.featuredImageUrl,
                          selectedPoi.articles,
                          selectedPoi.metadata,
                          descriptionController.text,
                        );
                        ref
                            .read(selectedPoiProvider.notifier)
                            .setPoi(
                              selectedPoi.cloneWithNewValues(
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
                  contentPadding: isAdminViewEnabled
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
              if (isAdminViewEnabled)
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
                      // TODO use clone to setLinks and articles and features
                      if (newLinks != null) {
                        selectedPoi.metadata.setLinks(newLinks);
                      }
                      await PoiRepository.updatePoiDataInSupabase(
                        selectedPoi.id!,
                        selectedPoi.name,
                        selectedPoi.history,
                        selectedPoi.featuredImageUrl,
                        selectedPoi.articles,
                        selectedPoi.metadata,
                        selectedPoi.description,
                      );

                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(selectedPoi.cloneWithNewValues());
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
                  contentPadding: isAdminViewEnabled
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
              if (isAdminViewEnabled)
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
                      selectedPoi.metadata.setFeatures(newFeatures!);
                      await PoiRepository.updatePoiDataInSupabase(
                        selectedPoi.id!,
                        selectedPoi.name,
                        selectedPoi.history,
                        selectedPoi.featuredImageUrl,
                        selectedPoi.articles,
                        selectedPoi.metadata,
                        selectedPoi.description,
                      );
                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(selectedPoi.cloneWithNewValues());
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
    PointOfInterest selectedPoi,
    bool isAdminViewEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          TextField(
            controller: historyController,
            readOnly: true,
            maxLines: 20,
            decoration: InputDecoration(
              labelText: "Geschichte",
              alignLabelWithHint: true,
              contentPadding: isAdminViewEnabled
                  ? const EdgeInsets.fromLTRB(0, 0, 35, 0)
                  : const EdgeInsets.fromLTRB(0, 0, 0, 0),
            ),
          ),
          if (isAdminViewEnabled)
            Positioned(
              right: 0,
              top: 20,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final newValue = await _openEditModal(
                    context,
                    "Geschichte",
                    historyController.text,
                    10,
                  );
                  if (newValue != null) {
                    historyController.text = newValue;
                    await PoiRepository.updatePoiDataInSupabase(
                      selectedPoi.id!,
                      selectedPoi.name,
                      newValue,
                      selectedPoi.featuredImageUrl,
                      selectedPoi.articles,
                      selectedPoi.metadata,
                      selectedPoi.description,
                    );
                    ref
                        .read(selectedPoiProvider.notifier)
                        .setPoi(
                          selectedPoi.cloneWithNewValues(history: newValue),
                        );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArticlesTab(
    PointOfInterest selectedPoi,
    bool isAdminViewEnabled,
  ) {
    final articles = selectedPoi.articles;

    return EditableList<ArticleEntry>(
      items: articles,
      isAdminViewEnabled: isAdminViewEnabled,
      onAdd: () async {
        final newEntry = await showDialog<ArticleEntry>(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const ArticleEditModal(initialTitle: "", initialUrl: ""),
        );

        if (newEntry != null) {
          final updated = [...articles, newEntry];
          await PoiRepository.updatePoiDataInSupabase(
            selectedPoi.id!,
            selectedPoi.name,
            selectedPoi.history,
            selectedPoi.featuredImageUrl,
            updated,
            selectedPoi.metadata,
            selectedPoi.description,
          );
          ref
              .read(selectedPoiProvider.notifier)
              .setPoi(selectedPoi.cloneWithNewValues(articles: updated));
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
          ),
        );

        if (updatedEntry != null) {
          final updated = [...articles];
          final index = updated.indexOf(entry);
          updated[index] = updatedEntry;

          await PoiRepository.updatePoiDataInSupabase(
            selectedPoi.id!,
            selectedPoi.name,
            selectedPoi.history,
            selectedPoi.featuredImageUrl,
            updated,
            selectedPoi.metadata,
            selectedPoi.description,
          );
          ref
              .read(selectedPoiProvider.notifier)
              .setPoi(selectedPoi.cloneWithNewValues(articles: updated));
        }

        return updatedEntry;
      },
      onDelete: (entry) async {
        final updated = [...articles]..remove(entry);
        await PoiRepository.updatePoiDataInSupabase(
          selectedPoi.id!,
          selectedPoi.name,
          selectedPoi.history,
          selectedPoi.featuredImageUrl,
          updated,
          selectedPoi.metadata,
          selectedPoi.description,
        );
        ref
            .read(selectedPoiProvider.notifier)
            .setPoi(selectedPoi.cloneWithNewValues(articles: updated));
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
    );
  }

  Widget _buildGalleryTab(PointOfInterest poi) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: (poi.featuredImageUrl.isEmpty)
          ? const Icon(Icons.image_not_supported, size: 80, color: Colors.grey)
          : Image.network(
              poi.featuredImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  size: 80,
                  color: Colors.grey,
                );
              },
            ),
    );
  }

  Widget _buildRatingsTab(PointOfInterest poi) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('Bewertung:'), Text('-')],
      ),
    );
  }

  bool _saved = false;
  bool _saving = false;

  Widget _buildEditTab(PointOfInterest selectedPoi, bool isAdminViewEnabled) {
    // ignore: unused_local_variable
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: featuredImageUrlController,
            decoration: const InputDecoration(labelText: "Featured Image-URL"),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Kategorien",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // List of categories with checkboxes
          provider.Consumer<CategoryState>(
            builder: (context, catState, _) {
              final categories = catState.categories;

              if (categories.isEmpty) {
                return const Text("Keine Kategorien geladen");
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: categories
                    .map(
                      (root) => CategoryNodeTile(
                        node: root,
                        poi: selectedPoi,
                        ref: ref,
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final con = context;
                    setState(() {
                      _saving = true;
                    });

                    final url = featuredImageUrlController.text.trim();

                    if (!isValidUrl(url)) {
                      showMessage(
                        context,
                        "The URL you entered is not valid. Please try again.",
                      );
                      setState(() => _saving = false);
                      return;
                    }

                    final exists = await urlExists(url);
                    if (!exists && con.mounted) {
                      showMessage(
                        con,
                        "The URL you entered is not reachable. Please try again.",
                      );
                      setState(() => _saving = false);
                      return;
                    }

                    await PoiRepository.updatePoiDataInSupabase(
                      selectedPoi.id!,
                      selectedPoi.name,
                      selectedPoi.history,
                      featuredImageUrlController.text,
                      selectedPoi.articles,
                      selectedPoi.metadata,
                      selectedPoi.description,
                    );
                    if (mounted) {
                      ref
                          .read(selectedPoiProvider.notifier)
                          .setPoi(
                            selectedPoi.cloneWithNewValues(
                              featuredImageUrl: featuredImageUrlController.text,
                            ),
                          );
                    }
                    // Show checkmark
                    setState(() {
                      _saving = false;
                      _saved = true;
                    });

                    // Hide checkmark after 1 second
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          _saved = false;
                        });
                      }
                    });
                  },
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _saved
                ? const Icon(Icons.control_point, color: Colors.green)
                : const Text("Speichern"),
          ),
        ],
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
            autofocus: true,
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

  // TODO move name field to adminTab or infotab

  // Name with edit button
  // Toggle for edit mode
  // Location Point / Label Position
  // List of Points with delete button

  Widget _buildPoiEditTab(PointOfInterest selectedPoi) {
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

    final appState = context.watch<AppState>();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Name
              Stack(
                children: [
                  TextField(
                    controller: nameController,
                    readOnly: true,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      labelText: "Name",
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
                          "Name",
                          nameController.text,
                          1,
                        );
                        if (newValue != null) {
                          nameController.text = newValue;
                          await PoiRepository.updatePoiDataInSupabase(
                            selectedPoi.id!,
                            newValue,
                            selectedPoi.history,
                            selectedPoi.featuredImageUrl,
                            selectedPoi.articles,
                            selectedPoi.metadata,
                            selectedPoi.description,
                          );
                          ref
                              .read(selectedPoiProvider.notifier)
                              .setPoi(
                                selectedPoi.cloneWithNewValues(name: newValue),
                              );
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Poi = Label Standort: Lat: ${location.lat} Lon: ${location.lon}',
              ),

              buildGeometryTypeSelector(context),

              const SizedBox(height: 16),

              const Text(
                'Punkte von 2D Geometrien (tippe lange auf die Karte, um weitere Punkte hinzuzufügen):',
              ),

              SwitchListTile(
                title: const Text('Geometrie bearbeiten'),
                value: appState.isPoiEditMode,
                onChanged: (newValue) => appState.setPoiEditMode(newValue),
              ),

              // Punkte-Liste
              SizedBox(
                height: 300, // feste Höhe für die EditableList
                child: EditableList<String>(
                  items: pointsList,
                  isAdminViewEnabled: true,
                  itemBuilder: (entry) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 15),
                      child: Text(entry, style: const TextStyle(fontSize: 16)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildGeometryTypeSelector(BuildContext context) {
    final selectedPoi = ref.watch(selectedPoiProvider);

    if (selectedPoi == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Geometrietyp",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        RadioGroup<String>(
          groupValue: selectedPoi.geometryType,
          onChanged: (value) {
            final newPoi = selectedPoi.cloneWithNewValues(geometryType: value!);
            
            if (newPoi.isGeometryValid()) {
              final poiRepository = context.read<PoiRepository>();
              poiRepository.updatePoiGeomInSupabase(newPoi);
            }
            context.read<AppState>().setPoiEditMode(false);
            ref.read(selectedPoiProvider.notifier).setPoi(newPoi);
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
