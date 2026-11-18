import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stadtschreiber/models/article_entry.dart';
import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/provider/app_state_provider.dart';
import 'package:stadtschreiber/provider/poi_repository_provider.dart';
import 'package:stadtschreiber/provider/selected_poi_provider.dart';
import 'package:stadtschreiber/provider/supabase_user_state_provider.dart';
import 'package:stadtschreiber/services/article_embed_service.dart';
import 'package:stadtschreiber/services/debug_service.dart';
import 'package:stadtschreiber/widgets/_editable_list.dart';
import 'package:stadtschreiber/widgets/modal_article_edit.dart';
import 'package:stadtschreiber/widgets/modal_articles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PoiPanelArticlesTab extends ConsumerWidget {
  const PoiPanelArticlesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DebugService.log('build PoiPanelArticlesTab $key $hashCode');

    final selectedPoi = ref.watch(selectedPoiProvider);

    final isEditor = ref.watch(supabaseUserStateProvider.notifier).isEditor();

    final isEditModeEnabled =
        ref.watch(appStateProvider).isPoiEditMode && isEditor;

    if (selectedPoi == null) {
      return const SizedBox.shrink();
    }

    final articles = selectedPoi.articles;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const SizedBox(height: 16),
            EditableList<ArticleEntry>(
              items: articles,
              isEditModeEnabled: isEditModeEnabled,
              onAdd: () async {
                final newEntry = await showDialog<ArticleEntry>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return const ArticleEditModal(
                      initialTitle: '',
                      initialUrl: '',
                      initialSource: '',
                    );
                  },
                );

                if (newEntry == null) {
                  return null;
                }

                final checkedEntry = await _checkArticleEmbed(newEntry);

                final updated = <ArticleEntry>[...articles, checkedEntry];

                await _saveArticles(
                  ref: ref,
                  poi: selectedPoi,
                  articles: updated,
                );

                return checkedEntry;
              },
              onEdit: (entry) async {
                final updatedEntry = await showDialog<ArticleEntry>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return ArticleEditModal(
                      initialTitle: entry.title,
                      initialUrl: entry.url,
                      initialSource: entry.source,
                      initialDate: entry.date,
                    );
                  },
                );

                if (updatedEntry == null) {
                  return null;
                }

                final urlChanged = updatedEntry.url.trim() != entry.url.trim();

                final ArticleEntry checkedEntry;

                if (urlChanged || entry.canEmbed == null) {
                  checkedEntry = await _checkArticleEmbed(updatedEntry);
                } else {
                  checkedEntry = updatedEntry.copyWith(
                    canEmbed: entry.canEmbed,
                    embedCheckReason: entry.embedCheckReason,
                    finalUrl: entry.finalUrl,
                  );
                }

                final updated = List<ArticleEntry>.from(articles);

                final index = _findArticleIndex(updated, entry);

                if (index < 0) {
                  return null;
                }

                updated[index] = checkedEntry;

                await _saveArticles(
                  ref: ref,
                  poi: selectedPoi,
                  articles: updated,
                );

                return checkedEntry;
              },
              onDelete: (entry) async {
                final updated = List<ArticleEntry>.from(articles);

                final index = _findArticleIndex(updated, entry);

                if (index < 0) {
                  return;
                }

                updated.removeAt(index);

                await _saveArticles(
                  ref: ref,
                  poi: selectedPoi,
                  articles: updated,
                );
              },
              itemBuilder: (entry) {
                final metadata = <String>[];

                final source = entry.source.trim();

                if (source.isNotEmpty) {
                  metadata.add(source);
                }

                if (entry.date != null) {
                  metadata.add(DateFormat('dd.MM.yyyy').format(entry.date!));
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () async {
                      await _openArticle(context, ref, selectedPoi, entry);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: metadata.join(', '),
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.fromLTRB(0, 0, 20, 10),
                        border: const UnderlineInputBorder(),
                        suffixIcon: const Icon(Icons.arrow_outward, size: 20),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openArticle(
    BuildContext context,
    WidgetRef ref,
    PointOfInterest poi,
    ArticleEntry article,
  ) async {
    final currentArticles = List<ArticleEntry>.from(poi.articles);

    final selectedIndex = _findArticleIndex(currentArticles, article);

    if (selectedIndex < 0) {
      return;
    }

    var hasChanges = false;
    var checkedArticle = currentArticles[selectedIndex];

    if (checkedArticle.canEmbed == null) {
      checkedArticle = await _checkArticleEmbed(checkedArticle);

      currentArticles[selectedIndex] = checkedArticle;

      hasChanges = true;
    }

    if (checkedArticle.canEmbed != true) {
      if (hasChanges) {
        await _saveArticles(ref: ref, poi: poi, articles: currentArticles);
      }

      await _openArticleInBrowser(checkedArticle);

      return;
    }

    for (var index = 0; index < currentArticles.length; index += 1) {
      if (index == selectedIndex) {
        continue;
      }

      final currentArticle = currentArticles[index];

      if (currentArticle.canEmbed != null) {
        continue;
      }

      currentArticles[index] = await _checkArticleEmbed(currentArticle);

      hasChanges = true;
    }

    if (hasChanges) {
      await _saveArticles(ref: ref, poi: poi, articles: currentArticles);
    }

    if (!context.mounted) {
      return;
    }

    await ArticlesModal.open(
      context,
      articles: currentArticles,
      initialIndex: selectedIndex,
    );
  }

  Future<void> _saveArticles({
    required WidgetRef ref,
    required PointOfInterest poi,
    required List<ArticleEntry> articles,
  }) async {
    await ref
        .read(poiRepositoryProvider)
        .updatePoiDataInSupabase(id: poi.id, articles: articles);

    ref
        .read(selectedPoiProvider.notifier)
        .setPoi(poi.copyWith(articles: articles));
  }

  Future<void> _openArticleInBrowser(ArticleEntry article) async {
    final storedFinalUrl = article.finalUrl?.trim();

    final targetUrl = storedFinalUrl != null && storedFinalUrl.isNotEmpty
        ? storedFinalUrl
        : article.url.trim();

    final uri = Uri.tryParse(targetUrl);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }

    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_blank');

      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<ArticleEntry> _checkArticleEmbed(ArticleEntry article) async {
    try {
      final embedService = ArticleEmbedService(Supabase.instance.client);

      final embedResult = await embedService.checkUrl(article.url.trim());

      DebugService.log(
        'Embed-Prüfung: '
        'url=${article.url}, '
        'canEmbed=${embedResult.canEmbed}, '
        'reason=${embedResult.reason}, '
        'finalUrl=${embedResult.finalUrl}',
      );

      return article.copyWith(
        canEmbed: embedResult.canEmbed,
        embedCheckReason: embedResult.reason,
        finalUrl: embedResult.finalUrl,
      );
    } catch (error) {
      DebugService.log(
        'Artikel-Einbettung konnte nicht geprüft werden: '
        '$error',
      );

      return article.copyWith(
        canEmbed: false,
        embedCheckReason: 'embed_check_failed',
        finalUrl: null,
      );
    }
  }

  int _findArticleIndex(List<ArticleEntry> articles, ArticleEntry article) {
    final identityIndex = articles.indexWhere(
      (current) => identical(current, article),
    );

    if (identityIndex >= 0) {
      return identityIndex;
    }

    return articles.indexWhere(
      (current) =>
          current.url.trim() == article.url.trim() &&
          current.title.trim() == article.title.trim() &&
          current.source.trim() == article.source.trim() &&
          current.date == article.date,
    );
  }
}
