// TODO General Debugging
// TODO Photo gallery
// TODO Icons
// TODO Kategorien
// TODO Bewertungsschemata
// TODO Info Popup (© Planetiler, OpenStreetMap, Maplibre...)
// TODO add poi owner
// TODO Photo credits
// TODO Login form, Passwort zurücksetzen, registrieren usw.
// TODO Kategorie Filter
// TODO photo upload
// TODO RLS
// TODO Multipolygon support für geometrie bearbeitung
// TODO Polygon and Line colors
// TODO Polygon consistency check


class ToDo {
  String id;
  String title;
  String description;
  bool isCompleted;

  ToDo({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  void toggleCompletion() {
    isCompleted = !isCompleted;
  }
} 