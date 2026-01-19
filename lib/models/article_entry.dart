class ArticleEntry {
  final String title;
  final String url;

  ArticleEntry({
    required this.title,
    required this.url,
  });

  factory ArticleEntry.fromJson(Map<String, dynamic> json) {
    return ArticleEntry(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
      };
}
