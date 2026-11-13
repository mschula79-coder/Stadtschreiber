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

String getText(String textCode, {String? languageCode, String? countryCode}) {
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
    case 'addToList':
      return localization.addToList;
    case 'address':
      return localization.address;
    case 'apply':
      return localization.apply;
    case 'attention':
      return localization.attention;
    case 'cancel':
      return localization.cancel;
    case 'categories':
      return localization.categories;

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
    case 'confirmDeletionOfList1':
      return localization.confirmDeletionOfList1;
    case 'confirmDeletionOfList2':
      return localization.confirmDeletionOfList2;
    case 'confirmEmail':
      return localization.confirmEmail;
    case 'confirmPassword':
      return localization.confirmPassword;
    case 'criterion':
      return localization.criterion;
    case 'deleteDate':
      return localization.deleteDate;
    case 'deleteUser':
      return localization.deleteUser;
    case 'deleteList':
      return localization.deleteList;
    case 'description':
      return localization.description;
    case 'done':
      return localization.done;
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
    case 'filterFeatures':
      return localization.filterFeatures;

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
    case 'passwordTooShort':
      return localization.passwordTooShort;
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
    case 'removeSelection':
      return localization.removeSelection;

    case 'results':
      return localization.results;
    case 'role':
      return localization.role;
    case 'save':
      return localization.save;
    case 'search':
      return localization.search;
    case 'searchRadius':
      return localization.searchRadius;
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
    case 'authActionForbidden':
      return localization.authActionForbidden;
    case 'authCaptchaFailed':
      return localization.authCaptchaFailed;
    case 'authConfirmationLinkInvalid':
      return localization.authConfirmationLinkInvalid;
    case 'authConflict':
      return localization.authConflict;
    case 'authDataStatus422':
      return localization.authDataStatus422;
    case 'authEmailConfirmationFailed':
      return localization.authEmailConfirmationFailed;
    case 'authEmailNotAuthorized':
      return localization.authEmailNotAuthorized;
    case 'authEmailNotConfirmed':
      return localization.authEmailNotConfirmed;
    case 'authEmailProviderDisabled':
      return localization.authEmailProviderDisabled;
    case 'authEmailRateLimit':
      return localization.authEmailRateLimit;
    case 'authFlowExpired':
      return localization.authFlowExpired;
    case 'authIdentityLinkFailed':
      return localization.authIdentityLinkFailed;
    case 'authInvalidCredentials':
      return localization.authInvalidCredentials;
    case 'authInvalidEmailAddress':
      return localization.authInvalidEmailAddress;
    case 'authInvalidLogin':
      return localization.authInvalidLogin;
    case 'authLoginFailed':
      return localization.authLoginFailed;
    case 'authLoginStatus400':
      return localization.authLoginStatus400;
    case 'authOtpDisabled':
      return localization.authOtpDisabled;
    case 'authOtpExpired':
      return localization.authOtpExpired;
    case 'authPasswordResetFailed':
      return localization.authPasswordResetFailed;
    case 'authPasswordResetStatus400':
      return localization.authPasswordResetStatus400;
    case 'authPasswordUpdateFailed':
      return localization.authPasswordUpdateFailed;
    case 'authPasswordUpdateStatus400':
      return localization.authPasswordUpdateStatus400;
    case 'authPasswordUpdateStatus422':
      return localization.authPasswordUpdateStatus422;
    case 'authRegistrationFailed':
      return localization.authRegistrationFailed;
    case 'authRegistrationStatus400':
      return localization.authRegistrationStatus400;
    case 'authRegistrationStatus422':
      return localization.authRegistrationStatus422;
    case 'authRequestRateLimit':
      return localization.authRequestRateLimit;
    case 'authSamePassword':
      return localization.authSamePassword;
    case 'authServiceUnavailable':
      return localization.authServiceUnavailable;
    case 'authSessionExpired':
      return localization.authSessionExpired;
    case 'authSignupDisabled':
      return localization.authSignupDisabled;
    case 'authStatus429':
      return localization.authStatus429;
    case 'authUnexpectedFailure':
      return localization.authUnexpectedFailure;
    case 'authUserAlreadyExists':
      return localization.authUserAlreadyExists;
    case 'authUserBanned':
      return localization.authUserBanned;
    case 'authWeakPassword':
      return localization.authWeakPassword;
    case 'authDatabaseUserCreationFailed':
      return localization.authDatabaseUserCreationFailed;
    case 'authNetworkError':
      return localization.authNetworkError;
    case 'authReauthenticationInvalid':
      return localization.authReauthenticationInvalid;
    case 'authReauthenticationNeeded':
      return localization.authReauthenticationNeeded;
    default:
      return 'NO TEXT FOUND FOR $textCode';
  }
}
