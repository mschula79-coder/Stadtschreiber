// TODO Test UpdateProfile Email
// TODO red screen when loading and overflow when opening menu
// TODO Mehrsprachigkeit App Modals und Datenbank
// TODO add poi owner
// TODO Konto löschen button, check ob user vorhanden
// TODO Multipolygon support für geometrie bearbeitung, Polygon consistency check
// TODO Polygon and Line colors
// TODO Theme
// TODO Suche beschleunigen
// TODO Dubletten löschen z.B. Münsterplatz
// TODO nicht mehr existierende Kategorien in der Datenbank löschen
// Multi category bewertung
// TODO wenn ich in den link zum passwort zurücksetzen drücke, kehrt die app zum login screen zurück. kann ich in diesem fall eine meldung einblenden dass ein neues passwort einzutragen ist?
// TODO variable poi list panel

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
