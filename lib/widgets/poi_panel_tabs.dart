import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/game_icons.dart';
import 'package:iconify_flutter/icons/maki.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article_entry.dart';
import '../models/poi.dart';

import '../controllers/poi_controller.dart';
import '../repositories/poi_repository.dart';
import '../widgets/_bool_features_editor_dialog.dart';
import '../widgets/_string_features_editor_dialog.dart';
import '../widgets/article_edit_modal.dart';
import '../widgets/category_node_tile.dart';
import '../repositories/category_repository.dart';
import '_editable_list.dart';
import '../utils/url_utils.dart';
import '../utils/message_utils.dart';

class PoiPanelTabs extends StatefulWidget {
  final bool isAdminViewEnabled;
  const PoiPanelTabs({super.key, required this.isAdminViewEnabled});

  @override
  State<PoiPanelTabs> createState() => _PoiPanelTabsState();
}

class _PoiPanelTabsState extends State<PoiPanelTabs> {
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController historyController = TextEditingController();
  late final TextEditingController featuredImageUrlController =
      TextEditingController();
  late final PoiController poiController;

  @override
  void initState() {
    super.initState();

    poiController = context.read<PoiController>();
    poiController.addListener(_updateControllers);
    _updateControllers();
  }

  void _updateControllers() {
    final poi = poiController.selectedPoi;
    if (poi == null) return;

    nameController.text = poi.name;
    historyController.text = poi.history ?? '';
    featuredImageUrlController.text = poi.featuredImageUrl ?? '';
  }

  @override
  void dispose() {
    poiController.removeListener(_updateControllers);
    nameController.dispose();
    historyController.dispose();
    featuredImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poi = context.watch<PoiController>().selectedPoi;
    if (poi == null) {
      return const SizedBox.shrink();
    }
    final bool isAdminViewEnabled = widget.isAdminViewEnabled;

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
    final pages = [
      _buildFeaturedImageTab(poi),
      _buildInfoTab(poi, isAdminViewEnabled),
      _buildHistoryTab(poi, isAdminViewEnabled),
      _buildArticlesTab(poi, isAdminViewEnabled),
      _buildGalleryTab(poi),
      _buildRatingsTab(poi),
    ];

    if (isAdminViewEnabled) {
      pages.add(_buildEditTab(poi, isAdminViewEnabled));
    }

    return DefaultTabController(
      length: isAdminViewEnabled ? 7 : 6,
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
      child: (poi.featuredImageUrl == null || poi.featuredImageUrl!.isEmpty)
          ? const Icon(Icons.image_not_supported, size: 80, color: Colors.grey)
          : Image.network(
              poi.featuredImageUrl!,
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

  Widget _buildInfoTab(PointOfInterest poi, bool isAdminViewEnabled) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              // TODO Add info controller and textfield analog to history
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Beschreibung",
                  alignLabelWithHint: true,
                  contentPadding: isAdminViewEnabled
                      ? const EdgeInsets.fromLTRB(0, 10, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 10, 0, 5),
                ),
              ),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Adresse",
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                ),
                child: poi.displayAddress == null
                    ? Text('')
                    : Text(
                        '${poi.city ?? ''}, ${poi.street ?? ''} ${poi.houseNumber ?? ''}',
                      ),
              ),
              // List of links icons
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
                        SizedBox(height: 30, width: 0),
                        poi.metadata.getWebsiteLink().isNotEmpty
                            ? InkWell(
                                onTap: () =>
                                    openLink(context, poi.metadata.getWebsiteLink()),
                                child: Row(
                                  children: [
                                    Iconify(Mdi.internet, size: 24),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),

                        poi.metadata.getGoogleMapsLink().isNotEmpty
                            ? InkWell(
                                onTap: () =>
                                    openLink(context, poi.metadata.getGoogleMapsLink()),
                                child: Row(
                                  children: [
                                    Iconify(Mdi.google_maps, size: 24),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        poi.metadata.getOSMLink().isNotEmpty
                            ? InkWell(
                                onTap: () =>
                                    openLink(context, poi.metadata.getOSMLink()),
                                child: Row(
                                  children: [
                                    Iconify(Mdi.map, size: 24),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        poi.metadata.getAppleMapsLink().isNotEmpty
                            ? InkWell(
                                onTap: () =>
                                    openLink(context, poi.metadata.getAppleMapsLink()),
                                child: Row(
                                  children: [
                                    Iconify(Mdi.apple, size: 24),
                                    const SizedBox(width: 10),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        poi.metadata.getWikipediaLink().isNotEmpty
                            ? InkWell(
                                onTap: () =>
                                    openLink(context, poi.metadata.getWikipediaLink()),
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
                  // Edit links
                  if (isAdminViewEnabled)
                    Positioned(
                      right: 0,
                      top: 10,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final newLinks =
                              await showDialog<Map<String, String>>(
                                context: context,
                                builder: (_) => StringFeaturesEditorDialog(
                                  dialogTitle: "Links bearbeiten",
                                  initialValues: poi.metadata.getLinks(),
                                ),
                              );
                          if (newLinks != null) poi.metadata.setLinks(newLinks);
                          await PoiRepository.updatePoiDataInSupabase(
                            poi.id,
                            poi.history,
                            poi.featuredImageUrl,
                            poi.articles,
                            poi.metadata,
                          );
                          await poiController.reloadSelectedPoi();
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              // List of features icons
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Features",
                  alignLabelWithHint: true,
                  contentPadding: isAdminViewEnabled
                      ? const EdgeInsets.fromLTRB(0, 5, 35, 5)
                      : const EdgeInsets.fromLTRB(0, 5, 0, 5),
                ),
                child: Row(
                  children: [
                    SizedBox(height: 30, width: 0),
                    poi.metadata.notBBQAllowed()
                        ? Row(
                            children: [
                              Iconify(Mdi.fire_off, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    poi.metadata.isWheelchairAccessible()
                        ? Row(
                            children: [
                              Iconify(Mdi.wheelchair_accessibility, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    poi.metadata.hasBenches()
                        ? Row(
                            children: [
                              Iconify(GameIcons.park_bench, size: 24),
                              const SizedBox(width: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                    poi.metadata.hasPicnicTables()
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
                  top: 10,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final newFeatures = await showDialog<Map<String, bool>>(
                        context: context,
                        builder: (_) => BoolFeaturesEditorDialog(
                          dialogTitle: "Features bearbeiten",
                          initialFeatures: poi.metadata.getFeatures(),
                        ),
                      );
                      poi.metadata.setFeatures(newFeatures!);
                      await PoiRepository.updatePoiDataInSupabase(
                        poi.id,
                        poi.history,
                        poi.featuredImageUrl,
                        poi.articles,
                        poi.metadata,
                      );
                      await poiController.reloadSelectedPoi();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(PointOfInterest poi, bool isAdminViewEnabled) {
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
                      poi.id,
                      newValue,
                      poi.featuredImageUrl,
                      poi.articles,
                      poi.metadata,
                    );
                    await poiController.reloadSelectedPoi();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArticlesTab(PointOfInterest poi, bool isAdminViewEnabled) {
    final articles = poi.articles;

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
            poi.id,
            poi.history,
            poi.featuredImageUrl,
            updated,
            poi.metadata,
          );
          await poiController.reloadSelectedPoi();
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
            poi.id,
            poi.history,
            poi.featuredImageUrl,
            updated,
            poi.metadata,
          );
          await poiController.reloadSelectedPoi();
        }

        return updatedEntry;
      },
      onDelete: (entry) async {
        final updated = [...articles]..remove(entry);
        await PoiRepository.updatePoiDataInSupabase(
          poi.id,
          poi.history,
          poi.featuredImageUrl,
          updated,
          poi.metadata,
        );
        await poiController.reloadSelectedPoi();
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
      child: (poi.featuredImageUrl == null || poi.featuredImageUrl!.isEmpty)
          ? const Icon(Icons.image_not_supported, size: 80, color: Colors.grey)
          : Image.network(
              poi.featuredImageUrl!,
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

  Widget _buildEditTab(PointOfInterest poi, bool isAdminViewEnabled) {
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

          Consumer<CategoryState>(
            builder: (context, catState, _) {
              final categories = catState.categories;

              if (categories.isEmpty) {
                return const Text("Keine Kategorien geladen");
              }

              return ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: categories
                    .map((root) => CategoryNodeTile(node: root, poi: poi))
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
                      poi.id,
                      poi.history,
                      featuredImageUrlController.text,
                      poi.articles,
                      poi.metadata,
                    );

                    if (mounted) {
                      await poiController.reloadSelectedPoi();
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
}
