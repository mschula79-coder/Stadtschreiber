// TODO Mehrsprachigkeit App Modals und Datenbank
// TODO add poi owner
// TODO Login form, Passwort zurücksetzen, registrieren usw.
// TODO Multipolygon support für geometrie bearbeitung, Polygon consistency check
// TODO Polygon and Line colors
// TODO Design PoiPanel = PoiListPanel (Shadow), List Button ergänzen
// TODO Theme



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