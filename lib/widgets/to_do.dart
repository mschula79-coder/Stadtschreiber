// TODO add poi owner
// TODO Add Source Attribution  https://flutter-maplibre.pages.dev/docs/ui
// TODO add shapes
// TODO Login form, Passwort zurücksetzen, regisitrieren usw.
// TODO photo upload
// TODO RLS
// TODO optimize multiple search trigger
// TODO check for double buildings

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