// TODO Debugging
// TODO Photo gallery
// TODO Bewertungssystem
// TODO Icon
// TODO Fix overflow issues with thumbnails at the edges
// TODO Add Source Attribution  https://flutter-maplibre.pages.dev/docs/ui
// TODO add poi owner
// TODO Photo credits
// TODO Login form, Passwort zurücksetzen, registrieren usw.
// TODO Kategorie Filter
// TODO photo upload
// TODO RLS
// TODO implement watch for CategoriesMenuState
// TODO Umstellung auf Riverpod?
// TODO RiverpodLogger
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