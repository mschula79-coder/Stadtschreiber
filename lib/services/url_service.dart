String getFilenameNoExtensionFromUrl(String url) {
  final uri = Uri.parse(url);

  // letzten Pfadteil holen
  final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

  // Query/Fragment sind hier schon entfernt
  if (filename.isEmpty) return '';

  // Endung entfernen
  final dotIndex = filename.lastIndexOf('.');
  if (dotIndex == -1) return filename; // keine Endung vorhanden

  return filename.substring(0, dotIndex);
}


String sanitizeFilename(String input) {
  // 1. Umlaute ersetzen
  const umlauts = {
    'ä': 'ae',
    'ö': 'oe',
    'ü': 'ue',
    'Ä': 'Ae',
    'Ö': 'Oe',
    'Ü': 'Ue',
    'ß': 'ss',
  };

  umlauts.forEach((k, v) {
    input = input.replaceAll(k, v);
  });

  // 2. Nur Dateiname extrahieren
  final uri = Uri.parse(input);
  String filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : input;

  // 3. Extension trennen
  final dotIndex = filename.lastIndexOf('.');
  String name = dotIndex != -1 ? filename.substring(0, dotIndex) : filename;
  String ext = dotIndex != -1 ? filename.substring(dotIndex) : '';

  // 4. Unzulässige Zeichen entfernen
  name = name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

  // 5. Mehrere Unterstriche reduzieren
  name = name.replaceAll(RegExp(r'_+'), '_');

  // 6. Trim underscores
  name = name.replaceAll(RegExp(r'^_+|_+$'), '');

  return "$name$ext".toLowerCase();
}
