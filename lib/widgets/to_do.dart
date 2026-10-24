
// final languageCode = ref.watch(localeProvider).languageCode;
// getText("comments", languageCode: languageCode)
// TODO Test UpdateProfile Email
// TODO Mehrsprachigkeit Kategorien
// TODO add poi owner
// TODO Konto löschen button, check ob user vorhanden
// TODO Multipolygon support für geometrie bearbeitung, Polygon consistency check
// TODO Polygon and Line colors
// TODO Dubletten löschen z.B. Münsterplatz
// TODO nicht mehr existierende Kategorien in der Datenbank löschen
// TODO wenn ich in den link zum passwort zurücksetzen drücke, kehrt die app zum login screen zurück. kann ich in diesem fall eine meldung einblenden dass ein neues passwort einzutragen ist?
// TODO poi list panel und poi panel gegenseitig schliessen

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
