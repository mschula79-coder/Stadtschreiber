import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:intl/intl.dart';
import 'package:stadtschreiber/models/article_entry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';

class ArticlesModal extends StatefulWidget {
  final List<ArticleEntry> articles;
  final int initialIndex;

  const ArticlesModal({
    super.key,
    required this.articles,
    required this.initialIndex,
  });

  static Future<void> open(
    BuildContext context, {
    required List<ArticleEntry> articles,
    required int initialIndex,
  }) async {
    if (articles.isEmpty) {
      return;
    }

    final normalizedInitialIndex = initialIndex.clamp(0, articles.length - 1);

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Articles',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ArticlesModal(
          articles: List<ArticleEntry>.unmodifiable(articles),
          initialIndex: normalizedInitialIndex,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<ArticlesModal> createState() {
    return _ArticlesModalState();
  }
}

class _ArticlesModalState extends State<ArticlesModal> {
  late final List<WebViewController?> _webViewControllers;
  late int _currentIndex;

  bool _isPageLoading = false;
  String? _pageError;

  ArticleEntry get _currentArticle {
    return widget.articles[_currentIndex];
  }

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex.clamp(0, widget.articles.length - 1);

    _webViewControllers = List<WebViewController?>.filled(
      widget.articles.length,
      null,
      growable: false,
    );

    _prepareCurrentArticle();
  }

  void _prepareCurrentArticle() {
    final article = _currentArticle;

    _pageError = null;
    _isPageLoading = false;

    if (article.canEmbed != true) {
      return;
    }

    if (_webViewControllers[_currentIndex] != null) {
      return;
    }

    _isPageLoading = true;

    _webViewControllers[_currentIndex] = _createWebViewController(
      article,
      _currentIndex,
    );
  }

  WebViewController _createWebViewController(
    ArticleEntry article,
    int articleIndex,
  ) {
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted || articleIndex != _currentIndex) {
              return;
            }

            setState(() {
              _isPageLoading = true;
              _pageError = null;
            });
          },
          onPageFinished: (url) {
            if (!mounted || articleIndex != _currentIndex) {
              return;
            }

            setState(() {
              _isPageLoading = false;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || articleIndex != _currentIndex) {
              return;
            }

            setState(() {
              _isPageLoading = false;
              _pageError = error.description;
            });
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);

            if (uri == null) {
              return NavigationDecision.prevent;
            }

            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }

            unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));

            return NavigationDecision.prevent;
          },
        ),
      );

    final uri = _getArticleUri(article);

    if (uri != null) {
      unawaited(controller.loadRequest(uri));
    } else {
      _pageError = 'Ungültige Artikeladresse';
      _isPageLoading = false;
    }

    return controller;
  }

  Uri? _getArticleUri(ArticleEntry article) {
    final storedFinalUrl = article.finalUrl?.trim();

    final targetUrl = storedFinalUrl != null && storedFinalUrl.isNotEmpty
        ? storedFinalUrl
        : article.url.trim();

    final uri = Uri.tryParse(targetUrl);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    return uri;
  }

  String _formatArticleMetadata(ArticleEntry article) {
    final values = <String>[];
    final source = article.source.trim();

    if (source.isNotEmpty) {
      values.add(source);
    }

    if (article.date != null) {
      values.add(DateFormat('dd.MM.yyyy').format(article.date!));
    }

    return values.join(', ');
  }

  Future<bool> _openArticleExternally(ArticleEntry article) async {
    final uri = _getArticleUri(article);

    if (uri == null) {
      return false;
    }

    if (kIsWeb) {
      return launchUrl(uri, webOnlyWindowName: '_blank');
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openCurrentArticleExternally() async {
    await _openArticleExternally(_currentArticle);
  }

  void _showArticleAt(int requestedIndex) {
    if (widget.articles.isEmpty) {
      return;
    }

    final articleCount = widget.articles.length;

    final normalizedIndex =
        ((requestedIndex % articleCount) + articleCount) % articleCount;

    final targetArticle = widget.articles[normalizedIndex];

    _currentIndex = normalizedIndex;
    _pageError = null;
    _isPageLoading = false;

    _prepareCurrentArticle();

    setState(() {});

    if (targetArticle.canEmbed != true) {
      unawaited(_openArticleExternally(targetArticle));
    }
  }

  void _showPreviousArticle() {
    _showArticleAt(_currentIndex - 1);
  }

  void _showNextArticle() {
    _showArticleAt(_currentIndex + 1);
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    if (widget.articles.length <= 1) {
      return;
    }

    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() < 250) {
      return;
    }

    if (velocity < 0) {
      _showNextArticle();
      return;
    }

    _showPreviousArticle();
  }

  Future<void> _reloadCurrentArticle() async {
    final article = _currentArticle;

    if (article.canEmbed != true) {
      await _openArticleExternally(article);

      return;
    }

    final controller = _webViewControllers[_currentIndex];

    if (controller == null) {
      _prepareCurrentArticle();

      if (mounted) {
        setState(() {});
      }

      return;
    }

    setState(() {
      _isPageLoading = true;
      _pageError = null;
    });

    await controller.reload();
  }

  Widget _buildBlockedArticle(BuildContext context, ArticleEntry article) {
    return KeyedSubtree(
      key: ValueKey<String>('blocked-article-$_currentIndex-${article.url}'),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new, size: 48),
                const SizedBox(height: 16),
                Text(
                  article.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dieser Artikel kann nicht im Fenster eingebettet werden.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    unawaited(_openCurrentArticleExternally());
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Im Browser öffnen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticleContent(BuildContext context) {
    final article = _currentArticle;

    if (article.canEmbed != true) {
      return _buildBlockedArticle(context, article);
    }

    final controller = _webViewControllers[_currentIndex];

    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return KeyedSubtree(
      key: ValueKey<String>('article-webview-$_currentIndex-${article.url}'),
      child: WebViewWidget(controller: controller),
    );
  }

  Widget _buildPageError(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.web_asset_off,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _currentArticle.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_pageError != null && _pageError!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_pageError!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  unawaited(_openCurrentArticleExternally());
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Im Browser öffnen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowArticleArea(BuildContext context, ArticleEntry article) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _handleHorizontalSwipe,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey<String>('article-$_currentIndex-${article.url}'),
                child: _buildArticleContent(context),
              ),
            ),
          ),
        ),
        if (_isPageLoading && article.canEmbed == true)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
        if (_pageError != null)
          Positioned.fill(child: _buildPageError(context)),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'open-article-browser',
            tooltip: 'Im Browser öffnen',
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            onPressed: () async {
              final opened = await _openArticleExternally(_currentArticle);

              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Der Artikel konnte nicht im Browser geöffnet werden.',
                    ),
                  ),
                );
              }
            },
            child: const Iconify(
              Mdi.open_in_new,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideArticleArea(BuildContext context, ArticleEntry article) {
    return Stack(
      children: [
        Positioned.fill(child: _buildArticleContent(context)),
        if (_isPageLoading && article.canEmbed == true)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
        if (_pageError != null)
          Positioned.fill(child: _buildPageError(context)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final article = _currentArticle;

    final metadata = _formatArticleMetadata(article);

    final canNavigate = widget.articles.length > 1;
    final isNarrowScreen = size.width < 700;

    final modalWidth = isNarrowScreen ? size.width : size.width * 0.9;

    final modalHeight = isNarrowScreen ? size.height : size.height * 0.92;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.82)),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: modalWidth,
                  maxHeight: modalHeight,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isNarrowScreen ? 0 : 12),
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.black87,
                          padding: EdgeInsets.fromLTRB(
                            isNarrowScreen ? 12 : 16,
                            8,
                            8,
                            8,
                          ),
                          child: IconTheme(
                            data: const IconThemeData(color: Colors.white),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: Colors.white),
                                      ),
                                      if (metadata.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          metadata,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_currentIndex + 1} / '
                                  '${widget.articles.length}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.white),
                                ),
                                if (!isNarrowScreen)
                                  IconButton(
                                    tooltip: 'Neu laden',
                                    color: Colors.white,
                                    disabledColor: Colors.white38,
                                    onPressed: _reloadCurrentArticle,
                                    icon: const Icon(Icons.refresh),
                                  ),
                                if (!isNarrowScreen)
                                  IconButton(
                                    tooltip: 'Im Browser öffnen',
                                    color: Colors.white,
                                    disabledColor: Colors.white38,
                                    onPressed: () {
                                      unawaited(
                                        _openCurrentArticleExternally(),
                                      );
                                    },
                                    icon: const Icon(Icons.open_in_browser),
                                  ),
                                IconButton(
                                  tooltip: 'Schliessen',
                                  color: Colors.white,
                                  disabledColor: Colors.white38,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: isNarrowScreen
                              ? _buildNarrowArticleArea(context, article)
                              : _buildWideArticleArea(context, article),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isNarrowScreen)
              Positioned(
                left: 8,
                child: IconButton(
                  tooltip: 'Vorheriger Artikel',
                  iconSize: 48,
                  color: canNavigate ? Colors.white : Colors.white38,
                  disabledColor: Colors.white38,
                  onPressed: canNavigate ? _showPreviousArticle : null,
                  icon: const Icon(Icons.chevron_left),
                ),
              ),
            if (!isNarrowScreen)
              Positioned(
                right: 8,
                child: IconButton(
                  tooltip: 'Nächster Artikel',
                  iconSize: 48,
                  color: canNavigate ? Colors.white : Colors.white38,
                  disabledColor: Colors.white38,
                  onPressed: canNavigate ? _showNextArticle : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
