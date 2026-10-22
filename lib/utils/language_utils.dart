import 'package:stadtschreiber/l10n/app_localizations_de.dart';
import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/l10n/app_localizations_en.dart';
import 'package:stadtschreiber/l10n/app_localizations_fr.dart';

int germanCompare(String a, String b) {
  String normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  return normalize(a).compareTo(normalize(b));
}

String getText(String textCode, {String? languageCode}) {
  AppLocalizations localization;
  switch (languageCode) {
    case 'de':
      localization = AppLocalizationsDe();
      break;
    case 'en':
      localization = AppLocalizationsEn();
      break;
    case 'fr':
      localization = AppLocalizationsFr();
      break;
    case 'ch':
      localization = AppLocalizationsDeCh();
      break;
    default:
      localization = AppLocalizationsDe();
  }

  switch (textCode) {
    case "add":
      return localization.add;

    case "address":
      return localization.address;

    //TODO update references and aab files
    case "apply":
      return "Übernehmen";

    case "attention":
      return "attention";

    case "cancel":
      return localization.cancel;

    case "close":
      return 'Schliessen';

    case "checkEmail":
      return localization.checkEmail;

    case "changePassword":
      return "Passwort ändern";

    case "comments":
      return "Kommentare";

    case "confirmDeletionOfPoint":
      return "confirm deletion of point";

    case "confirmEmail":
      return "Bitte bestätige deine neue E-Mail-Adresse.";

    case "criterion":
      return 'Kriterium';

    case "deleteDate":
      return "Datum löschen";

    case "deleteUser":
      return "Benutzer löschen";

    case "description":
      return "Beschreibung";

    case "editRatingCriterion":
      return "Bewertungskriterium bearbeiten";

    case "editArticle":
      return "Artikel bearbeiten";

    case "editCategory":
      return "Kategorie bearbeiten";

    case "editCategories":
      return localization.editCategories;

    case "editFavorite":
      return "Favorit bearbeiten";

    case "editFeatures":
      return localization.editFeatures;

    case "editGeometryPoints":
      return localization.editGeometryPoints;

    case "editGeometryPointsInstruction":
      return localization.editGeometryPointsInstruction;

    case "editImageInformation":
      return "Bildinformationen bearbeiten";

    case "editLinks":
      return localization.editLinks;

    case "editProfile":
      return "Profil bearbeiten";

    case "email":
      return localization.email;

    case "enterName":
      return "Name eingeben";

    case "error":
      return localization.error;

    case "favorites":
      return 'Favoriten';

    case "features":
      return localization.features;

    case "filterCategories":
      return "Kategorien filtern";

    case "finishDragMode":
      return "finish drag mode";

    case "finishEditMode":
      return "finish edit mode";

    case "geometryType":
      return localization.geometryType;

    case "joinus1":
      return "Mach mit!";

    case "joinus2":
      return "Werde Teil der Stadtschreiber-Community und teile deine Lieblingsorte mit anderen!";

    case "links":
      return localization.links;

    case "locationAndGeometrie":
      return localization.locationAndGeometrie;

    case "login":
      return localization.login;

    case "loginRequired":
      return "Neu einloggen erforderlich";

    case "hello":
      return localization.hello;

    case 'lengthOfPoiList':
      return "Länge der Hitliste";

    case "line":
      return localization.line;

    case "moveMapMessage":
      return "bewege die Karte um den Punkt zu platzieren";

    case "myRating":
      return "Meine Bewertung";

    case "newHere":
      return "Neu hier?";

    case "newList":
      return "+ neue Liste";

    case 'noFavoritesListsAvailable':
      return "Keine Favoritenlisten vorhanden";

    case "noEntries":
      return localization.noEntries;

    case 'msgNewLogin':
      return "Jetzt neu einloggen";
    case "msgImageEditError":
      return "Titel, URL und Eingetragen von dürfen nicht leer sein";

    case "msgRoleUpdate":
      return "Deine Rollen wurden aktualisiert. Bitte melde dich einmal neu an, damit die Änderungen aktiv werden.";

    case "msgArticleEditError":
      return "Titel, URL und Quelle dürfen nicht leer sein";

    case "multipolygone":
      return localization.multipolygone;

    case "name":
      return localization.name;

    case "newPassword":
      return "Neues Passwort";

    case 'noPoiFound':
      return "kein Ort gefunden";

    case 'noPoiFoundWithTheseCriteria':
      return "Keine Orte mit diesen Kriterien vorhanden";

    case "password":
      return localization.password;

    case "passwordChanged":
      return "Passwort erfolgreich geändert";

    case "passwordForgotten":
      return localization.passwordForgotten;

    case "passwordsDoNotMatch":
      return "Passwörter stimmen nicht überein";

    case 'poiNotFound':
      return "Ort nicht gefunden";

    case "point":
      return localization.point;

    case "polygone":
      return localization.polygone;

    case "processLink":
      return "Link prüfen";

    case "register":
      return localization.register;

    case "results":
      return "Resultate";

    case "role":
      return "Rolle";

    case "save":
      return localization.save;

    case "search":
      return localization.search;

    case "selectAll":
      return "Alle auswählen";

    case "selectCategory":
      return localization.selectCategory;

    case 'selectLengthOfPoiList':
      return "Länge der Hitliste auswählen";

    case "selectRatingCriterion":
      return localization.selectRatingCriterion;

    case "setNewPassword":
      return "neues Password eingeben";

    case "slogan":
      return "Entdecke dein Zuhause";

    case "upload":
      return "Upload";

    case "underConstruction":
      return "Die App befindet sich noch im Aufbau.";

    case "user":
      return "User";

    case "username":
      return localization.userName;

    default:
      return "NO TEXT FOUND FOR $textCode";
  }
}
