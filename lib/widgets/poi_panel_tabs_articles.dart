import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/models/article_entry.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/widgets/modal_article_edit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class PoiPanelArticlesTab extends ConsumerWidget {
  const PoiPanelArticlesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DebugService.log('build PoiPanelInfoTab $this.key $this.hashcode');
    final selectedPoi = ref.watch(selectedPoiProvider);
    final isEditModeEnabled = ref.watch(appStateProvider).isPoiEditMode;
    if (selectedPoi == null) return SizedBox.shrink();

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
                    initialDate: entry.date,
                  ),
                );

                if (updatedEntry != null) {
                  final updated = [...articles];
                  final index = updated.indexOf(entry);
                  if (index != -1) {
                    updated[index] = updatedEntry;
                  }
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
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText:
                                '${entry.source}${entry.date != null ? ', ${DateFormat('dd.MM.yyyy').format(entry.date!)}' : ''}',
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.fromLTRB(0, 0, 20, 10),
                            border:
                                UnderlineInputBorder(), // oder OutlineInputBorder()
                          ),
                          child: Text(
                            entry.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
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
}
