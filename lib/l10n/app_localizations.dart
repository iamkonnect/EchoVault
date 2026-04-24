import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_sw.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('sw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EchoVault'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @offersTitle.
  ///
  /// In en, this message translates to:
  /// **'Special Offers'**
  String get offersTitle;

  /// No description provided for @shortsReward.
  ///
  /// In en, this message translates to:
  /// **'Earn rewards by making shorts of your favorite artists!'**
  String get shortsReward;

  /// No description provided for @liveImportance.
  ///
  /// In en, this message translates to:
  /// **'Go live to connect with fans and earn real gifts!'**
  String get liveImportance;

  /// No description provided for @challengeWin.
  ///
  /// In en, this message translates to:
  /// **'Join challenges to win exclusive prizes!'**
  String get challengeWin;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English (Primary)'**
  String get english;

  /// No description provided for @swahili.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get swahili;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @deactivateWarning.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your data. Are you sure?'**
  String get deactivateWarning;

  /// No description provided for @giftAction.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get giftAction;

  /// No description provided for @likeAction.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeAction;

  /// No description provided for @commentAction.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get commentAction;

  /// No description provided for @buyCoinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Coins'**
  String get buyCoinsTitle;

  /// No description provided for @selectPackageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a package to top up your balance and support creators'**
  String get selectPackageSubtitle;

  /// No description provided for @giftSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Gift sent successfully!'**
  String get giftSentSuccess;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @categoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesLabel;

  /// No description provided for @latestVideosLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest Videos'**
  String get latestVideosLabel;

  /// No description provided for @trendingLiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Trending Live Streams'**
  String get trendingLiveLabel;

  /// No description provided for @echoRealmsLabel.
  ///
  /// In en, this message translates to:
  /// **'Echo Realms'**
  String get echoRealmsLabel;

  /// No description provided for @liveNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Live Now'**
  String get liveNowLabel;

  /// In en, this message translates to:
  /// **'Shake It (Maracca)'**
  String get giftMaracca;

  /// In en, this message translates to:
  /// **'Jingle Tap (Tambourine)'**
  String get giftTambourine;

  /// In en, this message translates to:
  /// **'Acoustic Vibe (Guitar)'**
  String get giftGuitar;

  /// In en, this message translates to:
  /// **'Midnight Soul (Saxophone)'**
  String get giftSaxophone;

  /// In en, this message translates to:
  /// **'Rock Legend (Electric Guitar)'**
  String get giftElectricGuitar;

  /// In en, this message translates to:
  /// **'Grand Maestro (Piano)'**
  String get giftPiano;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'sw': return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
