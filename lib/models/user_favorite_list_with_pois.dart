import 'package:stadtschreiber/models/poi.dart';
import 'package:stadtschreiber/models/user_favorites_list_dto.dart';

class UserFavoriteListWithPois {
  final UserFavoritesListDTO list;
  final List<PointOfInterest> pois;

  const UserFavoriteListWithPois({required this.list, required this.pois});
}
