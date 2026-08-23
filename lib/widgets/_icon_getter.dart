import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
/* import 'package:iconify_flutter/icons/fa.dart';
 */
import 'package:iconify_flutter/icons/grommet_icons.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:iconify_flutter/icons/fluent_mdl2.dart';

import 'package:iconify_flutter/icons/game_icons.dart';
import 'package:iconify_flutter/icons/icomoon_free.dart';
import 'package:iconify_flutter/icons/clarity.dart';
import 'package:iconify_flutter/icons/tabler.dart';
/* import 'package:iconify_flutter/icons/bx.dart'; */
import 'package:iconify_flutter/icons/simple_icons.dart';
// ignore: unused_import
import 'package:iconify_flutter/icons/maki.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:flutter_svg/flutter_svg.dart';
/* import 'package:iconify_flutter/icons/cib.dart';

 */
Widget getIcon(String category, double? iconsize, Color? color) {
  switch (category) {
    case "airplane": 
    return Iconify(Mdi.airplane, size: iconsize ?? 24, color: color ?? Colors.black);
    case "architecture":
      return Iconify(Mdi.house_heart, size: iconsize ?? 24, color: color ?? Colors.black);
    case "art-on-buildings":
      return Iconify(Mdi.art, size: iconsize ?? 24, color: color ?? Colors.black);
    case "basel-christmas":
      return Iconify(Tabler.christmas_tree, size: iconsize ?? 24, color: color ?? Colors.black);
    case "basel-specials":
      return Iconify(Mdi.star_outline, size: iconsize ?? 24, color: color ?? Colors.black);

    case "basketball_court":
      return Icon(Icons.sports_basketball, size: iconsize ?? 24, color: color ?? Colors.black);
    case "boule":
      return Iconify(GameIcons.dragon_balls, size: iconsize ?? 24, color: color ?? Colors.black);
    case "boulevards":
      return FaIcon(FontAwesomeIcons.personWalking, size: iconsize ?? 24, color: color ?? Colors.black);
    /* case "clubs":
      return Iconify(Mdi.olympics, size: iconsize ?? 24, color: color ?? Colors.black); */
    case "center": 
    return Iconify(Mdi.image_filter_center_focus, size: iconsize ?? 24, color: color ?? Colors.black);
    
    case "clubs":
      return Iconify(Mdi.olympics, size: iconsize ?? 24, color: color ?? Colors.black);case "culture":
      return Iconify(Mdi.historic, size: iconsize ?? 24, color: color ?? Colors.black);

    case "districts":
      return Iconify(Mdi.home_city_outline, size: iconsize ?? 24, color: color ?? Colors.black);
    case "fasnacht":
      return FaIcon(FontAwesomeIcons.masksTheater, size: iconsize ?? 24, color: color ?? Colors.black);
    case "fasnachtscliquen":
      return FaIcon(FontAwesomeIcons.masksTheater, size: iconsize ?? 24, color: color ?? Colors.black);
    case "foodcourts":
      return Icon(Icons.restaurant, size: iconsize ?? 24, color: color ?? Colors.black);
    case "gardens":
      return Iconify(GameIcons.flowers, size: iconsize ?? 24, color: color ?? Colors.black);
    case "hangout":
      return Icon(Icons.park, size: iconsize ?? 24, color: color ?? Colors.black);
    case "highlights":
      return Iconify(Mdi.star_outline, size: iconsize ?? 24, color: color ?? Colors.black);
    case "historical":
      return Iconify(Mdi.historic, size: iconsize ?? 24, color: color ?? Colors.black);
    case "icerink":
      return Iconify(Mdi.skate, size: iconsize ?? 24, color: color ?? Colors.black);
    case "Idylle":
      return Iconify(Mdi.plant, size: iconsize ?? 24, color: color ?? Colors.black);
    case "information":
      return Iconify(IcomoonFree.info);
    case "libraries":
      return Iconify(Clarity.library_line);
    case "markets":
      return Icon(Icons.local_grocery_store, size: iconsize ?? 24, color: color ?? Colors.black);
    case "memorials":
      return Iconify(GameIcons.martyr_memorial, size: iconsize ?? 24, color: color ?? Colors.black);
    case "museums":
      return Iconify(Mdi.museum_outline, size: iconsize ?? 24, color: color ?? Colors.black);
    case "musicvenues":
      return Iconify(Mdi.music, size: iconsize ?? 24, color: color ?? Colors.black);
    case "open-air-gym":
      return Iconify(Mdi.gym, size: iconsize ?? 24, color: color ?? Colors.black);
    case "orientation":
      return Iconify(Mdi.compass_outline, size: iconsize ?? 24, color: color ?? Colors.black);
    case "parks":
      return Icon(Icons.park, size: iconsize ?? 24, color: color ?? Colors.black);
    case "playgrounds":
      return Icon(Icons.local_play, size: iconsize ?? 24, color: color ?? Colors.black);
    case "pools":
      return Iconify(Mdi.swim, size: iconsize ?? 24, color: color ?? Colors.black);
    case "public_institutions":
      return Iconify(Mdi.building, size: iconsize ?? 24, color: color ?? Colors.black);
    case "quarter-centers":
      return Iconify(Mdi.home_city_outline, size: iconsize ?? 24, color: color ?? Colors.black);
    
    case "ranking":      
    return FaIcon(FontAwesomeIcons.rankingStar, size: iconsize ?? 24, color: color ?? Colors.black);
    case "Regionalität":
      return Iconify(FluentMdl2.location_outline, size: iconsize ?? 24, color: color ?? Colors.black);

    case "rhineswimming":
      return Iconify(Mdi.swim, size: iconsize ?? 24, color: color ?? Colors.black);
    case "Sauberkeit":
      return Iconify(Mdi.cleaning, size: iconsize ?? 24, color: color ?? Colors.black);
    case "Sport und Spiel":
      return Iconify(Mdi.family, size: iconsize ?? 24, color: color ?? Colors.black);

    case "social-clubs":
      return Iconify(Mdi.talk, size: iconsize ?? 24, color: color ?? Colors.black);
/*     case "sports":
      return Iconify(Mdi.olympics, size: iconsize ?? 24, color: color ?? Colors.black);
 */    case "sportsclubs":
      return Iconify(Mdi.olympics, size: iconsize ?? 24, color: color ?? Colors.black);
    case "sports":
      return Iconify(MaterialSymbols.stadium, size: iconsize ?? 24, color: color ?? Colors.black);
    case "squares":
      return Iconify(SimpleIcons.square, size: iconsize ?? 24, color: color ?? Colors.black);
    case "stadiums":
      return Iconify(MaterialSymbols.stadium, size: iconsize ?? 24, color: color ?? Colors.black);
    case "streetart":
      return Iconify(Mdi.spray, size: iconsize ?? 24, color: color ?? Colors.black);
    case "table-tennis":
      return Iconify(Mdi.table_tennis, size: iconsize ?? 24, color: color ?? Colors.black);
    case "tennis-courts":
      return Icon(Icons.sports_tennis, size: iconsize ?? 24, color: color ?? Colors.black);
    case "theatres":
      return Iconify(Mdi.theatre, size: iconsize ?? 24, color: color ?? Colors.black);
    case "touristattractions":
      return Iconify(Mdi.camera_outline, size: iconsize ?? 24, color: color ?? Colors.black);

    case "Unterhaltungswert":
      return Iconify(Mdi.home_city_outline, size: iconsize ?? 24, color: color ?? Colors.black);
    case "Urbanität":
      return Iconify(Mdi.home_city_outline, size: iconsize ?? 24, color: color ?? Colors.black);

    case "viewpoints":
      return Iconify(GrommetIcons.form_view_hide, size: iconsize ?? 24, color: color ?? Colors.black);
      case "Ausblick":
      return Iconify(GrommetIcons.form_view_hide, size: iconsize ?? 24, color: color ?? Colors.black);
    case "vita-parcours":
      return Iconify(Mdi.run, size: iconsize ?? 24, color: color ?? Colors.black);
    case "wells":
      return Iconify(Mdi.water_well_outline, size: iconsize ?? 24, color: color ?? Colors.black);
    case "youth-centers":
      return Iconify(Mdi.human_greeting_proximity, size: iconsize ?? 24, color: color ?? Colors.black);
    
    // Flaggen für Spracheinstellung
    case "CH":
      return SvgPicture.asset(
        'assets/icons/locale_ch.svg',
        width: iconsize ?? 24,
        height: iconsize ?? 24, 
      );
      case "de":
      case "DE":
      return SvgPicture.asset(
        'assets/icons/locale_de.svg',
        width: iconsize ?? 24,
        height: iconsize ?? 24
      );
      case "en":
      case "EN":
      return SvgPicture.asset(
        'assets/icons/locale_en.svg',
        width: iconsize ?? 24,
        height: iconsize ?? 24,
      );
      case "fr":
      case "FR":
      return SvgPicture.asset(
        'assets/icons/locale_fr.svg',
        width: iconsize ?? 24, 
        height: iconsize ?? 24,
      );
    default:
      return const SizedBox.shrink();
  }
}
