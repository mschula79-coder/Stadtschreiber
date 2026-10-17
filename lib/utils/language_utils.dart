import 'package:stadtschreiber/l10n/app_localizations_de.dart';

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

String getText(String textCode) {
  switch (textCode) {
    case "add":
      return AppLocalizationsDe().add;

    case "apply":
      return "Übernehmen";

    case "cancel":
      return AppLocalizationsDe().cancel;

    case "close":
      return 'Schliessen';

    case "deleteDate":
      return "Datum löschen";

    case "description":
      return "Beschreibung";

    case "editArticle":
      return "Artikel bearbeiten";

    case "editCategory":
      return "Kategorie bearbeiten";

    case "editFavorite":
      return "Favorit bearbeiten";

    case "editImageInformation":
      return "Bildinformationen bearbeiten";

    case "editProfile":
      return "Profil bearbeiten";

    case "enterName":
      return "Name eingeben";

    case "editRatingCriterion":
      return "Bewertungskriterium bearbeiten";

    case "filterCategories":
      return "Kategorien filtern";

    case "loginRequired":
      return "Neu einloggen erforderlich";

    case "newList":
      return "+ neue Liste";

    case "noEntries":
      return AppLocalizationsDe().noEntries;

    case 'msgNewLogin':
      return "Jetzt neu einloggen";
    case "msgImageEditError":
      return "Titel, URL und Eingetragen von dürfen nicht leer sein";

    case "msgRoleUpdate":
      return "Deine Rollen wurden aktualisiert. Bitte melde dich einmal neu an, damit die Änderungen aktiv werden.";
    case "msgArticleEditError":
      return "Titel, URL und Quelle dürfen nicht leer sein";

    case "processLink":
      return "Link prüfen";

    case "save":
      return AppLocalizationsDe().save;

    case "selectAll":
      return "Alle auswählen";

    case "upload":
      return "Upload";

    default:
      return "NO TEXT FOUND FOR $textCode";
  }
}
