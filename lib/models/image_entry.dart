class ImageEntry {
  final String title;
  final String url;
  final String enteredBy;
  final String? creditsName;
  final String? creditsUrl;

  ImageEntry({
    required this.title,
    required this.url,
    required this.enteredBy,
    this.creditsName,
    this.creditsUrl,
  });

  factory ImageEntry.fromJson(Map<String, dynamic> json) {
    return ImageEntry(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      enteredBy: json['entered_by'] ?? '',
      creditsName: json['credits_name'] ?? '',
      creditsUrl: json['credits_Url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'entered_by': enteredBy,
    'credits_name': creditsName,
    'credits_Url': creditsUrl,
  };
}
