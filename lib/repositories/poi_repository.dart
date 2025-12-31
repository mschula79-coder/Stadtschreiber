import '../models/park.dart';

class PoiRepository {
  Future<List<Park>> loadParks() async {
    return Future.wait([
      Park.create(
        "Schützenmattpark",
        "https://images.unsplash.com/photo-1501785888041-af3ef285b470",
      ),
      Park.create(
        "Kannenfeldpark",
        "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
      ),
      Park.create(
        "Erlenmattpark",
        "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee",
      ),
    ]);
  }
}
