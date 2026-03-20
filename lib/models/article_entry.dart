class ArticleEntry {
  final String title;
  final String url;
  final String source;

  ArticleEntry({
    required this.title,
    required this.url,
    required this.source,
  });

  factory ArticleEntry.fromJson(Map<String, dynamic> json) {
    return ArticleEntry(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      source: json['source'] ?? ''
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'source': source
      };
}
