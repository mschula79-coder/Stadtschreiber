class ArticleEntry {
  final String title;
  final String url;
  final String source;
  DateTime? date;

  ArticleEntry({
    required this.title,
    required this.url,
    required this.source,
    this.date,
  });

  factory ArticleEntry.fromJson(Map<String, dynamic> json) {
    return ArticleEntry(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      source: json['source'] ?? '',
      date: json['date'] != null && json['date'] != ''
          ? DateTime.tryParse(json['date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'source': source,
    'date': date?.toIso8601String(),
  };
}
