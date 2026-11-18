class ArticleEntry {
  final String title;
  final String url;
  final String source;
  final DateTime? date;
  final bool? canEmbed;
  final String? embedCheckReason;
  final String? finalUrl;

  const ArticleEntry({
    required this.title,
    required this.url,
    required this.source,
    this.date,
    this.canEmbed,
    this.embedCheckReason,
    this.finalUrl,
  });

  factory ArticleEntry.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString().trim();

    return ArticleEntry(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      date: rawDate == null || rawDate.isEmpty
          ? null
          : DateTime.tryParse(rawDate),
      canEmbed: json['canEmbed'] is bool ? json['canEmbed'] as bool : null,
      embedCheckReason: json['embedCheckReason']?.toString(),
      finalUrl: json['finalUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'url': url,
      'source': source,
      'date': date?.toIso8601String(),
      'canEmbed': canEmbed,
      'embedCheckReason': embedCheckReason,
      'finalUrl': finalUrl,
    };
  }

  ArticleEntry copyWith({
    String? title,
    String? url,
    String? source,
    Object? date = _unset,
    Object? canEmbed = _unset,
    Object? embedCheckReason = _unset,
    Object? finalUrl = _unset,
  }) {
    return ArticleEntry(
      title: title ?? this.title,
      url: url ?? this.url,
      source: source ?? this.source,
      date: identical(date, _unset) ? this.date : date as DateTime?,
      canEmbed: identical(canEmbed, _unset) ? this.canEmbed : canEmbed as bool?,
      embedCheckReason: identical(embedCheckReason, _unset)
          ? this.embedCheckReason
          : embedCheckReason as String?,
      finalUrl: identical(finalUrl, _unset)
          ? this.finalUrl
          : finalUrl as String?,
    );
  }

  static const Object _unset = Object();
}
