// TODO add poi owner
// TODO Add Source Attribution  https://flutter-maplibre.pages.dev/docs/ui
// TODO Login form, Passwort zurücksetzen, registrieren usw.
// TODO photo upload
// TODO RLS
// TODO optimize multiple search trigger
// TODO check for double buildings
// TODO Fix overflow issues with thumbnails at the edges
// TODO Multipolygon support für geometrie bearbeitung
// TODO implement watcFzh for CategoriesMenuState
// TODO Umstellung auf Riverpod?
// TODO RiverpodLogger
// TODO Polygon and Line colors

// TODO Icon


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