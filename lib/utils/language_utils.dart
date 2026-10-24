import 'package:stadtschreiber/l10n/app_localizations.dart';
import 'package:stadtschreiber/l10n/app_localizations_de.dart';
import 'package:stadtschreiber/l10n/app_localizations_en.dart';
import 'package:stadtschreiber/l10n/app_localizations_fr.dart';

int germanCompare(String a, String b) {
  String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
  }

  return normalize(a).compareTo(normalize(b));
}

String getText(
  String textCode, {
  String? languageCode,
  String? countryCode,
}) {
  final AppLocalizations localization;

  if (languageCode == 'de' && countryCode == 'CH') {
    localization = AppLocalizationsDeCh();
  } else {
    switch (languageCode) {
      case 'en':
        localization = AppLocalizationsEn();
        break;
      case 'fr':
        localization = AppLocalizationsFr();
        break;
      case 'ch':
        localization = AppLocalizationsDeCh();
        break;
      case 'de':
      default:
        localization = AppLocalizationsDe();
        break;
    }
  }

  switch (textCode) {
    case 'add':
      return localization.add;
    case 'address':
      return localization.address;
    case 'apply':
      return localization.apply;
    case 'attention':
      return localization.attention;
    case 'cancel':
      return localization.cancel;
    case 'changePassword':
      return localization.changePassword;
    case 'checkEmail':
      return localization.checkEmail;
    case 'close':
      return localization.close;
    case 'comments':
      return localization.comments;
    case 'confirmDeletionOfPoint':
      return localization.confirmDeletionOfPoint;
    case 'confirmEmail':
      return localization.confirmEmail;
    case 'criterion':
      return localization.criterion;
    case 'deleteDate':
      return localization.deleteDate;
    case 'deleteUser':
      return localization.deleteUser;
    case 'description':
      return localization.description;
    case 'editArticle':
      return localization.editArticle;
    case 'editCategories':
      return localization.editCategories;
    case 'editCategory':
      return localization.editCategory;
    case 'editFavorite':
      return localization.editFavorite;
    case 'editFeatures':
      return localization.editFeatures;
    case 'editGeometryPoints':
      return localization.editGeometryPoints;
    case 'editGeometryPointsInstruction':
      return localization.editGeometryPointsInstruction;
    case 'editImageInformation':
      return localization.editImageInformation;
    case 'editLinks':
      return localization.editLinks;
    case 'editProfile':
      return localization.editProfile;
    case 'editRatingCriterion':
      return localization.editRatingCriterion;
    case 'email':
      return localization.email;
    case 'enterName':
      return localization.enterName;
    case 'error':
      return localization.error;
    case 'favorites':
      return localization.favorites;
    case 'features':
      return localization.features;
    case 'filterCategories':
      return localization.filterCategories;
    case 'finishDragMode':
      return localization.finishDragMode;
    case 'finishEditMode':
      return localization.finishEditMode;
    case 'geometryType':
      return localization.geometryType;
    case 'hello':
      return localization.hello;
    case 'joinus1':
      return localization.joinus1;
    case 'joinus2':
      return localization.joinus2;
    case 'lengthOfPoiList':
      return localization.lengthOfPoiList;
    case 'line':
      return localization.line;
    case 'links':
      return localization.links;
    case 'locationAndGeometrie':
      return localization.locationAndGeometrie;
    case 'login':
      return localization.login;
    case 'loginRequired':
      return localization.loginRequired;
    case 'moveMapMessage':
      return localization.moveMapMessage;
    case 'msgArticleEditError':
      return localization.msgArticleEditError;
    case 'msgImageEditError':
      return localization.msgImageEditError;
    case 'msgNewLogin':
      return localization.msgNewLogin;
    case 'msgRoleUpdate':
      return localization.msgRoleUpdate;
    case 'multipolygone':
      return localization.multipolygone;
    case 'myRating':
      return localization.myRating;
    case 'name':
      return localization.name;
    case 'newHere':
      return localization.newHere;
    case 'newList':
      return localization.newList;
    case 'newPassword':
      return localization.newPassword;
    case 'noEntries':
      return localization.noEntries;
    case 'noFavoritesListsAvailable':
      return localization.noFavoritesListsAvailable;
    case 'noPoiFound':
      return localization.noPoiFound;
    case 'noPoiFoundWithTheseCriteria':
      return localization.noPoiFoundWithTheseCriteria;
    case 'password':
      return localization.password;
    case 'passwordChanged':
      return localization.passwordChanged;
    case 'passwordForgotten':
      return localization.passwordForgotten;
    case 'passwordsDoNotMatch':
      return localization.passwordsDoNotMatch;
    case 'poiNotFound':
      return localization.poiNotFound;
    case 'point':
      return localization.point;
    case 'polygone':
      return localization.polygone;
    case 'processLink':
      return localization.processLink;
    case 'register':
      return localization.register;
    case 'results':
      return localization.results;
    case 'role':
      return localization.role;
    case 'save':
      return localization.save;
    case 'search':
      return localization.search;
    case 'selectAll':
      return localization.selectAll;
    case 'selectCategory':
      return localization.selectCategory;
    case 'selectLengthOfPoiList':
      return localization.selectLengthOfPoiList;
    case 'selectRatingCriterion':
      return localization.selectRatingCriterion;
    case 'setNewPassword':
      return localization.setNewPassword;
    case 'slogan':
      return localization.slogan;
    case 'underConstruction':
      return localization.underConstruction;
    case 'upload':
      return localization.upload;
    case 'user':
      return localization.user;
    case 'username':
      return localization.userName;
    default:
      return 'NO TEXT FOUND FOR $textCode';
  }
}