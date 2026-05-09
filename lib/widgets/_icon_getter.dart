import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/grommet_icons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
/* import 'package:iconify_flutter/icons/fluent_mdl2.dart';
 */import 'package:iconify_flutter/icons/game_icons.dart';
import 'package:iconify_flutter/icons/icomoon_free.dart';
import 'package:iconify_flutter/icons/clarity.dart';
import 'package:iconify_flutter/icons/tabler.dart';
/* import 'package:iconify_flutter/icons/cib.dart';
 */
Widget getIcon(String category) {
  switch (category) {
    case "basel-christmas":
      return Iconify(Tabler.christmas_tree, size: 24);

    case "basketball_court":
      return Icon(Icons.sports_basketball, size: 24);
    case "boule":
      return Iconify(GameIcons.dragon_balls, size: 24);
    case "boulevards":
      return FaIcon(FontAwesomeIcons.personWalking, size: 24);
    case "clubs":
      return SizedBox.shrink();
    case "districts":
      return Iconify(Mdi.home_city_outline, size: 24);
    case "fasnacht":
      return FaIcon(FontAwesomeIcons.masksTheater, size: 24);
    case "fasnachtscliquen":
      return FaIcon(FontAwesomeIcons.masksTheater, size: 24);
    case "foodcourts":
      return Icon(Icons.restaurant, size: 24);
    case "highlights":
      return Iconify(Mdi.star_outline, size: 24);
    case "historical":
      return Iconify(Mdi.historic, size: 24);

    case "icerink":
      return Iconify(Mdi.skate, size: 24);
    case "information":
      return Iconify(IcomoonFree.info);
    case "libraries":
      return Iconify(Clarity.library_line);
    case "markets":
      return Icon(Icons.local_grocery_store, size: 24);
    case "memorials":
      return Iconify(GameIcons.martyr_memorial, size: 24);
    case "museums":
      return SizedBox.shrink();
    case "musicvenues":
      return SizedBox.shrink();
    case "open-air-gym":
      return SizedBox.shrink();
    case "orientation":
      return Iconify(Mdi.compass_outline, size: 24);
    case "parks":
      return Icon(Icons.park, size: 24);
    case "playgrounds":
      return Icon(Icons.local_play, size: 24);
    case "pools":
      return SizedBox.shrink();
    case "public_institutions":
      return SizedBox.shrink();
    case "quarter-centers":
      return SizedBox.shrink();
    case "rhineswimming":
      return Iconify(Mdi.swim, size: 24);
    case "social-clubs":
      return SizedBox.shrink();
    case "sports":
      return SizedBox.shrink();
    case "sportsclubs":
      return SizedBox.shrink();
    case "squares":
      return SizedBox.shrink();
    case "stadiums":
      return SizedBox.shrink();
    case "streetart":
      return Iconify(Mdi.spray, size: 24);
    case "table-tennis":
      return Iconify(Mdi.table_tennis, size: 24);
    case "tennis-courts":
      return Icon(Icons.sports_tennis, size: 24);
    case "theatres":
      return Iconify(Mdi.theatre, size: 24);
    case "touristattractions":
      return Iconify(Mdi.camera_outline, size: 24);
    case "viewpoints":
      return Iconify(GrommetIcons.form_view_hide, size: 24);
    case "vita-parcours":
      return SizedBox.shrink();
    case "wells":
      return SizedBox.shrink();
    case "youth-centers":
      return SizedBox.shrink();

    default:
      return const SizedBox.shrink();
  }
}
