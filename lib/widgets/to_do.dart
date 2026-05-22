// TODO Bewertungsschemata
// TODO Top 10
// TODO add poi owner
// TODO Login form, Passwort zurücksetzen, registrieren usw.
// TODO Mehrsprachig
// TODO implement multiple categories / category for ratings
// TODO Multipolygon support für geometrie bearbeitung, Polygon consistency check
// TODO Polygon and Line colors



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