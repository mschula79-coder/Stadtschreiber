import 'package:supabase_flutter/supabase_flutter.dart';

class PoiRatingRepository {
  final supabase = Supabase.instance.client;

  Future<void> saveRatings({
    required String poiId,
    required Map<String, int> scores,
    required Map<String, String> comments,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    // Alle Criterion-IDs sammeln
    final allCriterionIds = {...scores.keys, ...comments.keys};

    for (final criterionId in allCriterionIds) {
      final score = scores[criterionId];
      final comment = comments[criterionId];

      // rating ist Pflicht → wenn score fehlt, alten Wert laden
      int? finalScore = score;

      if (finalScore == null) {
        // alten Score aus DB holen
        final existing = await supabase
            .from("poi_ratings")
            .select("rating")
            .eq("poi_id", poiId)
            .eq("user_id", userId)
            .eq("criterion_id", criterionId)
            .maybeSingle();

        finalScore = existing?["rating"];
      }

      // jetzt MUSS finalScore existieren
      if (finalScore == null) {
        throw Exception("Rating fehlt für criterion $criterionId");
      }

      final payload = {
        "poi_id": poiId,
        "user_id": userId,
        "criterion_id": criterionId,
        "rating": finalScore,
        "comment": comment ?? "",
      };

      await supabase
          .from("poi_ratings")
          .upsert(payload, onConflict: 'poi_id,user_id,criterion_id');
    }
  }
}
