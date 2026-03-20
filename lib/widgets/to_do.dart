// TODO History as List of decorated textboxes
// TODO photo upload
// TODO Kategorien
// TODO Kategorie Filter
// TODO Icons
// TODO Bewertungsschemata
// TODO Info Popup (© Planetiler, OpenStreetMap, Maplibre...)
// TODO add poi owner
// TODO Login form, Passwort zurücksetzen, registrieren usw.
// TODO Photo credits
// TODO RLS
// TODO Multipolygon support für geometrie bearbeitung
// TODO Polygon and Line colors
// TODO Polygon consistency check
// TODO Zoom out animation
// TODO Modal loading distortion 


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