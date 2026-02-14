class PoiMetadata {
  Map<String, String>? _links;
  Map<String, bool> _features;
  final Map<String, dynamic>? attributes;
  final List<String>? tags;

  PoiMetadata({
    Map<String, String>? links,
    Map<String, bool>? features,
    this.attributes,
    this.tags,
  }) : _features = features ?? {},
       _links = links ?? {};

  factory PoiMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PoiMetadata();
    return PoiMetadata(
      links: (json['links'] as Map?)?.cast<String, String>(),
      features: (json['features'] as Map?)?.cast<String, bool>(),
      attributes: json['attributes'] as Map<String, dynamic>?,
      tags: (json['tags'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'links': _links,
    'features': _features,
    'attributes': attributes,
    'tags': tags,
  };

  Map<String, bool> getFeatures() {
    final Map<String, bool> features = {
      "notBBQAllowed": notBBQAllowed(),
      "wheelchair": isWheelchairAccessible(),
      "benches": hasBenches(),
      "picnictables": hasPicnicTables(),
    };
    return features;
  }

  void setFeatures(Map<String, bool> newFeatures) {
    _features = newFeatures;
  }

  bool notBBQAllowed() {
    return _features['notbbqallowed'] == true;
  }

  void setNotBBQAllowed(bool isBBQAllowed) {
    _features['notbbqallowed'] = isBBQAllowed;
  }

  bool isWheelchairAccessible() {
    return _features['wheelchair'] == true;
  }

  void setWheelchairAccessible(bool isWheelchairAccessible) {
    _features['wheelchair'] = isWheelchairAccessible;
  }

  bool hasBenches() {
    return _features['benches'] == true;
  }

  void setHasBenches(bool hasBenches) {
    _features['benches'] = hasBenches;
  }

  bool hasPicnicTables() {
    return _features['picnictables'] == true;
  }

  void setPicnicTables(bool hasPicnicTables) {
    _features['picnictables'] = hasPicnicTables;
  }

  bool hasBBQGrill() {
    return _features['bbqgrill'] == true;
  }

  void setHasBBQGrill(bool hasPicnicTables) {
    _features['bbqgrill'] = hasPicnicTables;
  }

  Map<String, String> getLinks() {
    final Map<String, String> links = {
      "applemaps": getAppleMapsLink(),
      "googlemaps": getGoogleMapsLink(),
      "OSM" : getOSMLink(),
      "website": getWebsiteLink(),
      "wikipedia": getWikipediaLink(),
    };
    return links;
  }

  void setLinks(Map<String, String> newLinks) {
    _links = newLinks;
  }

  String getGoogleMapsLink() {
    if (_links == null || _links?['googlemaps'] == null) {
      return '';
    }
    return _links!['googlemaps']!;
  }
String getOSMLink() {
    if (_links == null || _links?['OSM'] == null) {
      return '';
    }
    return _links!['OSM']!;
  }
  String getAppleMapsLink() {
    if (_links == null || _links?['applemaps'] == null) {
      return '';
    }
    return _links!['applemaps']!;
  }

  String getWikipediaLink() {
    if (_links == null || _links?['wikipedia'] == null) {
      return '';
    }
    return _links!['wikipedia']!;
  }

  String getWebsiteLink() {
    if (_links == null || _links?['website'] == null) {
      return '';
    }
    return _links!['website']!;
  }
}
