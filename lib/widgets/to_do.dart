// TODO add poi owner
// TODO: In Supabase: OSM-ID Check und Import umbauen: siehe Chat: 1. Du importierst OSM‑Daten NICHT per „truncate + insert“
// TODO remove name if too many items on screen
// TODO Add Source Attribution  https://flutter-maplibre.pages.dev/docs/ui
// TODO District center calculation auskommentieren

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