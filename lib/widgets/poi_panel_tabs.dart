import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:stadtschreiber/models/history_entry.dart';
import 'package:stadtschreiber/models/rating_criterion.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/categories_provider.dart';
import 'package:stadtschreiber/provider/poi_drag_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_provider.dart';
import 'package:stadtschreiber/provider/poi_ratings_stats_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/widgets/modal_history_edit.dart';
import 'package:stadtschreiber/widgets/poi_panel_tabs_gallery.dart';
import 'package:stadtschreiber/widgets/poi_panel_tabs_info.dart';
import 'package:stadtschreiber/widgets/poi_rating_editor_dialog.dart';
import 'package:stadtschreiber/widgets/poi_rating_list.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/article_entry.dart';
import '../models/poi.dart';

import '../widgets/_editable_list.dart';
import 'modal_article_edit.dart';

class PoiPanelTabs extends ConsumerStatefulWidget {
  const PoiPanelTabs({super.key});

  @override
  ConsumerState<PoiPanelTabs> createState() => _PoiPanelTabsState();
}

class _PoiPanelTabsState extends ConsumerState<PoiPanelTabs> {
  /*   bool _listenerRegistered = false;
 */
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
    super.dispose();
    DebugService.log('Dispose PoiPanelTabs');
  }

  @override
  Widget build(BuildContext context) {
    DebugService.log('Build PoiPanelTabs');
    final selectedPoi = ref.watch(selectedPoiProvider);
    if (selectedPoi == null) return const SizedBox.shrink();

    final bool isEditModeEnabled = ref.watch(appStateProvider).isPoiEditMode;
    /* 
    if (!_listenerRegistered) {
      _listenerRegistered = true;

      // 1. Listener registrieren
      _sub = ref.listenManual<PointOfInterest?>(selectedPoiProvider, (
        prev,
        next,
      ) {
        
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
    } */

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
      PoiPanelInfoTab(),
      PoiPanelGalleryTab(),
      _buildRatingsTab(selectedPoi),
      _buildHistoryTab(selectedPoi, isEditModeEnabled),
      _buildArticlesTab(selectedPoi, isEditModeEnabled),
    ];
    int initialIndex;
    if (selectedPoi.images.isEmpty) {
      initialIndex = 0;
    } else {
      initialIndex = 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        DebugService.log("PoiPanelTabs constraints: $constraints");

        return DefaultTabController(
          length: tabs.length,
          initialIndex: initialIndex,
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

  Widget _buildHistoryTab(PointOfInterest selectedPoi, bool isEditModeEnabled) {
    final historyEntries = selectedPoi.historyEntries;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 8),
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
                            selectedPoi.copyWith(historyEntries: updated),
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
                            selectedPoi.copyWith(historyEntries: updated),
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
                        .setPoi(selectedPoi.copyWith(historyEntries: updated));
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
                      .setPoi(selectedPoi.copyWith(articles: updated));
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
                      .setPoi(selectedPoi.copyWith(articles: updated));
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
}
