// TODO Mehrsprachigkeit App Modals und Datenbank
// TODO add poi owner
// TODO Konto löschen button, check ob user vorhanden
// TODO Multipolygon support für geometrie bearbeitung, Polygon consistency check
// TODO Polygon and Line colors
// TODO Design PoiPanel = PoiListPanel (Shadow), List Button ergänzen und Top10 Position und Ratings
// Mehrfachselektion PoiList
// TODO Theme
// Multi category bewertung
// TODO automatisches Scrollen nach expansion im visiblePoismenu fixen
// TODO wenn ich in den link zum passwort zurücksetzen drücke, kehrt die app zum login screen zurück. kann ich in diesem fall eine meldung einblenden dass ein neues passwort einzutragen ist?

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
