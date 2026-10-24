import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('de', 'CH'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @allRated.
  ///
  /// In en, this message translates to:
  /// **'All rated places'**
  String get allRated;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Please check your email and click the confirmation link. Also check your spam folder.'**
  String get checkEmail;

  /// No description provided for @chooseUserName.
  ///
  /// In en, this message translates to:
  /// **'Choose username'**
  String get chooseUserName;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDeletionOfPoint.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this point?'**
  String get confirmDeletionOfPoint;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new email address.'**
  String get confirmEmail;

  /// No description provided for @criterion.
  ///
  /// In en, this message translates to:
  /// **'Criterion'**
  String get criterion;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteDate.
  ///
  /// In en, this message translates to:
  /// **'Delete date'**
  String get deleteDate;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get deleteUser;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @distanceFromCenter.
  ///
  /// In en, this message translates to:
  /// **'Distance from the center of the map'**
  String get distanceFromCenter;

  /// No description provided for @editArticle.
  ///
  /// In en, this message translates to:
  /// **'Edit article'**
  String get editArticle;

  /// No description provided for @editCategories.
  ///
  /// In en, this message translates to:
  /// **'Edit categories'**
  String get editCategories;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @editFavorite.
  ///
  /// In en, this message translates to:
  /// **'Edit favorite'**
  String get editFavorite;

  /// No description provided for @editFeatures.
  ///
  /// In en, this message translates to:
  /// **'Edit features'**
  String get editFeatures;

  /// No description provided for @editGeometryPoints.
  ///
  /// In en, this message translates to:
  /// **'Edit geometry points'**
  String get editGeometryPoints;

  /// No description provided for @editGeometryPointsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Tap and hold the map position where you want to add or edit a point'**
  String get editGeometryPointsInstruction;

  /// No description provided for @editImageInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit image information'**
  String get editImageInformation;

  /// No description provided for @editLinks.
  ///
  /// In en, this message translates to:
  /// **'Edit links'**
  String get editLinks;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editRatingCriterion.
  ///
  /// In en, this message translates to:
  /// **'Edit rating criterion'**
  String get editRatingCriterion;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @filterCategories.
  ///
  /// In en, this message translates to:
  /// **'Filter categories'**
  String get filterCategories;

  /// No description provided for @finishDragMode.
  ///
  /// In en, this message translates to:
  /// **'Finish drag mode'**
  String get finishDragMode;

  /// No description provided for @finishEditMode.
  ///
  /// In en, this message translates to:
  /// **'Finish edit mode'**
  String get finishEditMode;

  /// No description provided for @geometryType.
  ///
  /// In en, this message translates to:
  /// **'Geometry type'**
  String get geometryType;

  /// No description provided for @goOn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get goOn;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @houseNumber.
  ///
  /// In en, this message translates to:
  /// **'House number'**
  String get houseNumber;

  /// No description provided for @joinus1.
  ///
  /// In en, this message translates to:
  /// **'Join us!'**
  String get joinus1;

  /// No description provided for @joinus2.
  ///
  /// In en, this message translates to:
  /// **'Become part of the Stadtschreiber community and share your favorite places!'**
  String get joinus2;

  /// No description provided for @lengthOfPoiList.
  ///
  /// In en, this message translates to:
  /// **'Select length of the ranking list'**
  String get lengthOfPoiList;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @locationAndGeometrie.
  ///
  /// In en, this message translates to:
  /// **'Location and geometry'**
  String get locationAndGeometrie;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get loginRequired;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @moveMapMessage.
  ///
  /// In en, this message translates to:
  /// **'Move the map to set the new position'**
  String get moveMapMessage;

  /// No description provided for @msgArticleEditError.
  ///
  /// In en, this message translates to:
  /// **'Title, URL and source must not be empty'**
  String get msgArticleEditError;

  /// No description provided for @msgImageEditError.
  ///
  /// In en, this message translates to:
  /// **'Title, URL and submitted by must not be empty'**
  String get msgImageEditError;

  /// No description provided for @msgNewLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in again now'**
  String get msgNewLogin;

  /// No description provided for @msgRoleUpdate.
  ///
  /// In en, this message translates to:
  /// **'Your roles have been updated. Please sign in again for the changes to take effect.'**
  String get msgRoleUpdate;

  /// No description provided for @multipolygone.
  ///
  /// In en, this message translates to:
  /// **'Multipolygon'**
  String get multipolygone;

  /// No description provided for @myRating.
  ///
  /// In en, this message translates to:
  /// **'My rating'**
  String get myRating;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'+ new list'**
  String get newList;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noCategoriesLoaded.
  ///
  /// In en, this message translates to:
  /// **'No categories loaded'**
  String get noCategoriesLoaded;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get noEntries;

  /// No description provided for @noFavoritesListsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No favorite lists available'**
  String get noFavoritesListsAvailable;

  /// No description provided for @noPoiFound.
  ///
  /// In en, this message translates to:
  /// **'No place found'**
  String get noPoiFound;

  /// No description provided for @noPoiFoundWithTheseCriteria.
  ///
  /// In en, this message translates to:
  /// **'No places matching these criteria are available'**
  String get noPoiFoundWithTheseCriteria;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @openDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get openDetails;

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMap;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// No description provided for @passwordForgotten.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get passwordForgotten;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @poiList.
  ///
  /// In en, this message translates to:
  /// **'List of displayed places'**
  String get poiList;

  /// No description provided for @poiNotFound.
  ///
  /// In en, this message translates to:
  /// **'Place not found'**
  String get poiNotFound;

  /// No description provided for @point.
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get point;

  /// No description provided for @polygone.
  ///
  /// In en, this message translates to:
  /// **'Polygon'**
  String get polygone;

  /// No description provided for @processLink.
  ///
  /// In en, this message translates to:
  /// **'Check link'**
  String get processLink;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We have sent you a link'**
  String get resetLinkSent;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @selectLengthOfPoiList.
  ///
  /// In en, this message translates to:
  /// **'Select the length of the ranking list'**
  String get selectLengthOfPoiList;

  /// No description provided for @selectRatingCriterion.
  ///
  /// In en, this message translates to:
  /// **'Select rating criterion'**
  String get selectRatingCriterion;

  /// No description provided for @selectionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Selection incomplete'**
  String get selectionIncomplete;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPassword;

  /// No description provided for @showTop10.
  ///
  /// In en, this message translates to:
  /// **'Show top 10 list'**
  String get showTop10;

  /// No description provided for @slogan.
  ///
  /// In en, this message translates to:
  /// **'Discover your home'**
  String get slogan;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @underConstruction.
  ///
  /// In en, this message translates to:
  /// **'The app is still under development.'**
  String get underConstruction;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get userName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'de':
      {
        switch (locale.countryCode) {
          case 'CH':
            return AppLocalizationsDeCh();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
