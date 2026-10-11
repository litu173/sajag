import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[Locale('bn'), Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sajag'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'See it. Snap it. Fix it.'**
  String get tagline;

  /// No description provided for @demoBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode · sample data, nothing leaves your phone'**
  String get demoBanner;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get errorNetwork;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @onboard1Title.
  ///
  /// In en, this message translates to:
  /// **'Seen a problem on the street?'**
  String get onboard1Title;

  /// No description provided for @onboard1Body.
  ///
  /// In en, this message translates to:
  /// **'Open manholes, broken roads, garbage, waterlogging — snap a live photo and let your whole area know.'**
  String get onboard1Body;

  /// No description provided for @onboard2Title.
  ///
  /// In en, this message translates to:
  /// **'Your identity stays secret'**
  String get onboard2Title;

  /// No description provided for @onboard2Body.
  ///
  /// In en, this message translates to:
  /// **'Every citizen is verified with mobile and NID to stop fake reports, but your name is never shown. Others only see a random alias.'**
  String get onboard2Body;

  /// No description provided for @onboard3Title.
  ///
  /// In en, this message translates to:
  /// **'Together we fix our city'**
  String get onboard3Title;

  /// No description provided for @onboard3Body.
  ///
  /// In en, this message translates to:
  /// **'Confirm what others report, earn badges, and watch problems get solved on the live map.'**
  String get onboard3Body;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get phoneTitle;

  /// No description provided for @phoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a 6-digit code by SMS.'**
  String get phoneSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get phoneLabel;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Bangladeshi mobile number (11 digits, starts with 01)'**
  String get phoneInvalid;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @otpDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo code: 123456'**
  String get otpDemoHint;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resend;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @nidTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify you\'re a real citizen'**
  String get nidTitle;

  /// No description provided for @nidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your NID is checked once and stored only as a one-way fingerprint. It is never shown to anyone — not even other users.'**
  String get nidSubtitle;

  /// No description provided for @nidLabel.
  ///
  /// In en, this message translates to:
  /// **'NID number'**
  String get nidLabel;

  /// No description provided for @nidHelper.
  ///
  /// In en, this message translates to:
  /// **'10, 13 or 17 digits'**
  String get nidHelper;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dobLabel;

  /// No description provided for @dobPick.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get dobPick;

  /// No description provided for @verifyIdentity.
  ///
  /// In en, this message translates to:
  /// **'Verify identity'**
  String get verifyIdentity;

  /// No description provided for @privacyPromise.
  ///
  /// In en, this message translates to:
  /// **'Your reports are always anonymous.'**
  String get privacyPromise;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification in review'**
  String get pendingTitle;

  /// No description provided for @pendingBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know as soon as your identity is confirmed. This usually takes less than a day.'**
  String get pendingBody;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @errInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect or has expired.'**
  String get errInvalidOtp;

  /// No description provided for @errInvalidNid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid NID number (10, 13 or 17 digits).'**
  String get errInvalidNid;

  /// No description provided for @errInvalidDob.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid date of birth. You must be at least 13.'**
  String get errInvalidDob;

  /// No description provided for @errNidTaken.
  ///
  /// In en, this message translates to:
  /// **'This NID is already linked to another account.'**
  String get errNidTaken;

  /// No description provided for @errNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your identity first.'**
  String get errNotVerified;

  /// No description provided for @errBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your account is restricted. Please contact support.'**
  String get errBlocked;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s report limit. Please try again tomorrow.'**
  String get errRateLimited;

  /// No description provided for @errStaleCapture.
  ///
  /// In en, this message translates to:
  /// **'This photo is too old. Please take a new one.'**
  String get errStaleCapture;

  /// No description provided for @errOwnReport.
  ///
  /// In en, this message translates to:
  /// **'You can\'t confirm your own report.'**
  String get errOwnReport;

  /// No description provided for @errAlreadyDone.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already done this.'**
  String get errAlreadyDone;

  /// No description provided for @locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow your location'**
  String get locationTitle;

  /// No description provided for @locationBody.
  ///
  /// In en, this message translates to:
  /// **'Sajag tags each report with where it happened and shows problems around you. Location is required to use the app.'**
  String get locationBody;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is turned off on your phone. Please turn it on to continue.'**
  String get locationServiceOff;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Please enable it in Settings to continue.'**
  String get locationDeniedForever;

  /// No description provided for @navFeed.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navFeed;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navAchievements.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get navAchievements;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navProfile;

  /// No description provided for @feedNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get feedNearby;

  /// No description provided for @feedLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get feedLatest;

  /// No description provided for @feedFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get feedFollowing;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @emptyNearby.
  ///
  /// In en, this message translates to:
  /// **'No reports near you yet. Be the first to report!'**
  String get emptyNearby;

  /// No description provided for @emptyFollowing.
  ///
  /// In en, this message translates to:
  /// **'Follow citizens to see their reports here.'**
  String get emptyFollowing;

  /// No description provided for @emptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No reports in this category yet.'**
  String get emptyCategory;

  /// No description provided for @demoLocationNote.
  ///
  /// In en, this message translates to:
  /// **'Demo: showing Dhaka because you\'re outside Bangladesh'**
  String get demoLocationNote;

  /// No description provided for @confirmations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Be the first to verify} =1{1 person verified this} other{{count} people verified this}}'**
  String confirmations(int count);

  /// No description provided for @anonymousCitizen.
  ///
  /// In en, this message translates to:
  /// **'Anonymous citizen'**
  String get anonymousCitizen;

  /// No description provided for @awarenessTag.
  ///
  /// In en, this message translates to:
  /// **'Awareness'**
  String get awarenessTag;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportAction;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get statusOpen;

  /// No description provided for @statusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get statusAcknowledged;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusHidden.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get statusHidden;

  /// No description provided for @statusRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get statusRemoved;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String timeMinutes(int n);

  /// No description provided for @timeHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String timeHours(int n);

  /// No description provided for @timeDays.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String timeDays(int n);

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportTitle;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @followingButton.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingButton;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @flagReport.
  ///
  /// In en, this message translates to:
  /// **'Flag this post'**
  String get flagReport;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'{category} reported at {place} — via Sajag'**
  String shareText(String category, String place);

  /// No description provided for @deleteReport.
  ///
  /// In en, this message translates to:
  /// **'Delete report'**
  String get deleteReport;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this report? This can\'t be undone.'**
  String get deleteConfirm;

  /// No description provided for @reportNotFound.
  ///
  /// In en, this message translates to:
  /// **'This report is no longer available.'**
  String get reportNotFound;

  /// No description provided for @levelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String levelShort(int level);

  /// No description provided for @flagTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong with this post?'**
  String get flagTitle;

  /// No description provided for @flagFalse.
  ///
  /// In en, this message translates to:
  /// **'False or misleading'**
  String get flagFalse;

  /// No description provided for @flagLocation.
  ///
  /// In en, this message translates to:
  /// **'Wrong location'**
  String get flagLocation;

  /// No description provided for @flagCategory.
  ///
  /// In en, this message translates to:
  /// **'Wrong category'**
  String get flagCategory;

  /// No description provided for @flagInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate photo'**
  String get flagInappropriate;

  /// No description provided for @flagDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate of another report'**
  String get flagDuplicate;

  /// No description provided for @flagSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or advertising'**
  String get flagSpam;

  /// No description provided for @flagOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get flagOther;

  /// No description provided for @flagNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add details (optional)'**
  String get flagNoteHint;

  /// No description provided for @flagSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send to moderators'**
  String get flagSubmit;

  /// No description provided for @flagThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks — our moderators will review it.'**
  String get flagThanks;

  /// No description provided for @captureHint.
  ///
  /// In en, this message translates to:
  /// **'Point at the problem. Only live photos are allowed — no gallery uploads.'**
  String get captureHint;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @usePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use photo'**
  String get usePhoto;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to take report photos.'**
  String get cameraDenied;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera available on this device.'**
  String get cameraUnavailable;

  /// No description provided for @flash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get flash;

  /// No description provided for @composeTitle.
  ///
  /// In en, this message translates to:
  /// **'New report'**
  String get composeTitle;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s the problem?'**
  String get categoryLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe it briefly'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Manhole open near the school gate'**
  String get descriptionHint;

  /// No description provided for @descriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please add a few more words.'**
  String get descriptionTooShort;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locating;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accurate to about {meters} m'**
  String locationAccuracy(int meters);

  /// No description provided for @showAlias.
  ///
  /// In en, this message translates to:
  /// **'Show my alias'**
  String get showAlias;

  /// No description provided for @showAliasOn.
  ///
  /// In en, this message translates to:
  /// **'Posted as {alias}. Your followers get notified.'**
  String showAliasOn(String alias);

  /// No description provided for @showAliasOff.
  ///
  /// In en, this message translates to:
  /// **'Posted as an anonymous citizen, not linked to your alias.'**
  String get showAliasOff;

  /// No description provided for @identityNeverShown.
  ///
  /// In en, this message translates to:
  /// **'Your real name, phone and NID are never shown to anyone.'**
  String get identityNeverShown;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Post report'**
  String get submitReport;

  /// No description provided for @posted.
  ///
  /// In en, this message translates to:
  /// **'Report posted! Thank you for keeping your area safe.'**
  String get posted;

  /// No description provided for @mockLocation.
  ///
  /// In en, this message translates to:
  /// **'Fake GPS detected. Turn off mock-location apps to post.'**
  String get mockLocation;

  /// No description provided for @pickCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get pickCategory;

  /// No description provided for @mapLast24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get mapLast24h;

  /// No description provided for @mapLast7d.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get mapLast7d;

  /// No description provided for @mapLast30d.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get mapLast30d;

  /// No description provided for @mapReportsHere.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report here} other{{count} reports here}}'**
  String mapReportsHere(int count);

  /// No description provided for @locateMe.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get locateMe;

  /// No description provided for @mapLegendFew.
  ///
  /// In en, this message translates to:
  /// **'Few'**
  String get mapLegendFew;

  /// No description provided for @mapLegendMany.
  ///
  /// In en, this message translates to:
  /// **'Many'**
  String get mapLegendMany;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @tabBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get tabBadges;

  /// No description provided for @tabLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get tabLeaderboard;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(int level);

  /// No description provided for @xpToNext.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to {name}'**
  String xpToNext(int xp, String name);

  /// No description provided for @maxLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level reached — you\'re a legend!'**
  String get maxLevel;

  /// No description provided for @statReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get statReports;

  /// No description provided for @statResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statResolved;

  /// No description provided for @statConfirms.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by others'**
  String get statConfirms;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get statStreak;

  /// No description provided for @badgesEarned.
  ///
  /// In en, this message translates to:
  /// **'{earned} of {total} earned'**
  String badgesEarned(int earned, int total);

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get badgeEarned;

  /// No description provided for @badgeLocked.
  ///
  /// In en, this message translates to:
  /// **'Not earned yet'**
  String get badgeLocked;

  /// No description provided for @badgeReward.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP'**
  String badgeReward(int xp);

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodMonth;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAll;

  /// No description provided for @leaderboardPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Everyone appears by alias only. No one can see who you really are.'**
  String get leaderboardPrivacy;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'{n} XP'**
  String points(int n);

  /// No description provided for @emptyLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'No one on the board yet — post a report to be first!'**
  String get emptyLeaderboard;

  /// No description provided for @verifiedCitizen.
  ///
  /// In en, this message translates to:
  /// **'Verified citizen'**
  String get verifiedCitizen;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @followingLabel.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingLabel;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReports;

  /// No description provided for @noReportsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted any reports yet.'**
  String get noReportsYet;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textLarge;

  /// No description provided for @textExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textExtraLarge;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & anonymity'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'• Your phone number and NID are used only to make sure every reporter is a real, unique person.\n• Your NID is stored as a one-way fingerprint, never as the number itself.\n• Other people only ever see your random alias — or nothing at all if you post anonymously.\n• Photo locations are public; your identity is not.\n• Moderators can restrict accounts that post false reports without seeing who you are.'**
  String get privacyBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Sajag'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Sajag (সজাগ — “alert”) helps citizens report civic problems publicly and safely, so neighbours stay aware and the responsible authorities can act.'**
  String get aboutBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of Sajag?'**
  String get signOutConfirm;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get noNotifications;

  /// No description provided for @nFollowedPost.
  ///
  /// In en, this message translates to:
  /// **'{alias} posted a new report: {category}'**
  String nFollowedPost(String alias, String category);

  /// No description provided for @nBadge.
  ///
  /// In en, this message translates to:
  /// **'You earned the “{badge}” badge!'**
  String nBadge(String badge);

  /// No description provided for @nResolved.
  ///
  /// In en, this message translates to:
  /// **'Your report was marked resolved 🎉'**
  String get nResolved;

  /// No description provided for @nConfirmedResolved.
  ///
  /// In en, this message translates to:
  /// **'A problem you confirmed has been resolved'**
  String get nConfirmedResolved;

  /// No description provided for @nRemoved.
  ///
  /// In en, this message translates to:
  /// **'Your report was removed by moderators'**
  String get nRemoved;

  /// No description provided for @nFollower.
  ///
  /// In en, this message translates to:
  /// **'A citizen started following you'**
  String get nFollower;

  /// No description provided for @nMilestone.
  ///
  /// In en, this message translates to:
  /// **'{count} people have confirmed your report'**
  String nMilestone(int count);

  /// No description provided for @nVerifyApproved.
  ///
  /// In en, this message translates to:
  /// **'Your identity has been verified. You can now post reports.'**
  String get nVerifyApproved;

  /// No description provided for @nVerifyRejected.
  ///
  /// In en, this message translates to:
  /// **'Identity verification failed. Please try again.'**
  String get nVerifyRejected;

  /// No description provided for @citizenTitle.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get citizenTitle;

  /// No description provided for @markSolved.
  ///
  /// In en, this message translates to:
  /// **'Mark as solved'**
  String get markSolved;

  /// No description provided for @markSolvedTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this problem fixed?'**
  String get markSolvedTitle;

  /// No description provided for @markSolvedBody.
  ///
  /// In en, this message translates to:
  /// **'Only mark it solved if the problem is really gone. Everyone who confirmed it will be told.'**
  String get markSolvedBody;

  /// No description provided for @markSolvedNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What changed? (optional)'**
  String get markSolvedNoteHint;

  /// No description provided for @markSolvedDone.
  ///
  /// In en, this message translates to:
  /// **'Marked as solved. Thank you!'**
  String get markSolvedDone;

  /// No description provided for @solvedIn.
  ///
  /// In en, this message translates to:
  /// **'Solved in {duration}'**
  String solvedIn(String duration);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour} other{{n} hours}}'**
  String durationHours(int n);

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String durationDays(int n);

  /// No description provided for @markedByReporter.
  ///
  /// In en, this message translates to:
  /// **'Marked solved by the reporter'**
  String get markedByReporter;

  /// No description provided for @markedByModerator.
  ///
  /// In en, this message translates to:
  /// **'Confirmed solved by a moderator'**
  String get markedByModerator;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get latestVersion;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'You have version {version}'**
  String currentVersion(String version);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version ({version})'**
  String upToDate(String version);

  /// No description provided for @checkingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get checkingUpdate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates. Check your internet.'**
  String get updateCheckFailed;

  /// No description provided for @downloadLatest.
  ///
  /// In en, this message translates to:
  /// **'Download latest version'**
  String get downloadLatest;

  /// No description provided for @iosInstallNote.
  ///
  /// In en, this message translates to:
  /// **'On iPhone, install the downloaded file with Sideloadly or AltStore until Sajag is on the App Store.'**
  String get iosInstallNote;

  /// No description provided for @filterPosts.
  ///
  /// In en, this message translates to:
  /// **'Filter posts'**
  String get filterPosts;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearMe;

  /// No description provided for @everywhere.
  ///
  /// In en, this message translates to:
  /// **'Everywhere'**
  String get everywhere;

  /// No description provided for @chooseArea.
  ///
  /// In en, this message translates to:
  /// **'Choose a location'**
  String get chooseArea;

  /// No description provided for @searchArea.
  ///
  /// In en, this message translates to:
  /// **'Search area'**
  String get searchArea;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyLocation;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @allCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategoriesTitle;

  /// No description provided for @clearCategory.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get clearCategory;

  /// No description provided for @earnedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'{count} earned · {period}'**
  String earnedInPeriod(int count, String period);

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newBadge;

  /// No description provided for @versionTitle.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get versionTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettings;

  /// No description provided for @publicProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfileSection;

  /// No description provided for @publicProfileHint.
  ///
  /// In en, this message translates to:
  /// **'This is all other citizens ever see.'**
  String get publicProfileHint;

  /// No description provided for @avatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile emoji'**
  String get avatarLabel;

  /// No description provided for @aliasLabel.
  ///
  /// In en, this message translates to:
  /// **'Alias'**
  String get aliasLabel;

  /// No description provided for @identitySection.
  ///
  /// In en, this message translates to:
  /// **'Private identity'**
  String get identitySection;

  /// No description provided for @identityHint.
  ///
  /// In en, this message translates to:
  /// **'Used only to verify you. Never shown to anyone.'**
  String get identityHint;

  /// No description provided for @idVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get idVerified;

  /// No description provided for @idPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get idPending;

  /// No description provided for @securitySection.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySection;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set · you sign in with an SMS code'**
  String get passwordNotSet;

  /// No description provided for @passwordIsSet.
  ///
  /// In en, this message translates to:
  /// **'On · sign in with code or password'**
  String get passwordIsSet;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get setPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @passwordIntro.
  ///
  /// In en, this message translates to:
  /// **'Add a password to sign in without waiting for an SMS. First we\'ll send a code to {phone}.'**
  String passwordIntro(String phone);

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get passwordMismatch;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with a letter and a number.'**
  String get passwordRule;

  /// No description provided for @passwordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password saved.'**
  String get passwordSaved;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signInWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get signInWithPassword;

  /// No description provided for @signInWithCode.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an SMS code instead'**
  String get signInWithCode;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Removes your profile, reports and photos for good.'**
  String get deleteAccountHint;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your alias, XP, badges, reports and photos will be permanently deleted. This can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountType.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteAccountType;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @chooseEmoji.
  ///
  /// In en, this message translates to:
  /// **'Choose your emoji'**
  String get chooseEmoji;

  /// No description provided for @emojiBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get emojiBackground;

  /// No description provided for @emojiUseAlias.
  ///
  /// In en, this message translates to:
  /// **'Alias animal'**
  String get emojiUseAlias;

  /// No description provided for @emojiCatAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get emojiCatAnimals;

  /// No description provided for @emojiCatNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get emojiCatNature;

  /// No description provided for @emojiCatFaces.
  ///
  /// In en, this message translates to:
  /// **'Faces'**
  String get emojiCatFaces;

  /// No description provided for @emojiCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get emojiCatFood;

  /// No description provided for @emojiCatActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get emojiCatActivity;

  /// No description provided for @emojiCatPlaces.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get emojiCatPlaces;

  /// No description provided for @emojiCatObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get emojiCatObjects;

  /// No description provided for @emojiCatSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get emojiCatSymbols;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveChanges;

  /// No description provided for @savedMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get savedMessage;

  /// No description provided for @changeAlias.
  ///
  /// In en, this message translates to:
  /// **'Change alias'**
  String get changeAlias;

  /// No description provided for @aliasHelper.
  ///
  /// In en, this message translates to:
  /// **'3–24 letters or numbers, in Bangla or English.'**
  String get aliasHelper;

  /// No description provided for @aliasWarning.
  ///
  /// In en, this message translates to:
  /// **'Keep it anonymous: don\'t use your real name, phone or NID.'**
  String get aliasWarning;

  /// No description provided for @aliasOncePerWeek.
  ///
  /// In en, this message translates to:
  /// **'You can change it once every 7 days.'**
  String get aliasOncePerWeek;

  /// No description provided for @aliasLockedUntil.
  ///
  /// In en, this message translates to:
  /// **'You can change it again on {date}.'**
  String aliasLockedUntil(String date);

  /// No description provided for @suggestAlias.
  ///
  /// In en, this message translates to:
  /// **'Suggest one'**
  String get suggestAlias;

  /// No description provided for @errInvalidAlias.
  ///
  /// In en, this message translates to:
  /// **'Use 3–24 letters, numbers or spaces, without long number sequences.'**
  String get errInvalidAlias;

  /// No description provided for @errAliasTaken.
  ///
  /// In en, this message translates to:
  /// **'That alias is taken. Try another.'**
  String get errAliasTaken;

  /// No description provided for @errAliasCooldown.
  ///
  /// In en, this message translates to:
  /// **'You changed your alias recently. Try again later.'**
  String get errAliasCooldown;

  /// No description provided for @errPhoneTaken.
  ///
  /// In en, this message translates to:
  /// **'That number is already in use.'**
  String get errPhoneTaken;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters with a letter and a number.'**
  String get errWeakPassword;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong number or password.'**
  String get errWrongPassword;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change mobile number'**
  String get changePhone;

  /// No description provided for @newPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'New mobile number'**
  String get newPhoneLabel;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String codeSentTo(String phone);

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get codeLabel;

  /// No description provided for @verifyAndSave.
  ///
  /// In en, this message translates to:
  /// **'Verify and save'**
  String get verifyAndSave;

  /// No description provided for @phoneChanged.
  ///
  /// In en, this message translates to:
  /// **'Mobile number updated.'**
  String get phoneChanged;

  /// No description provided for @updateIdentity.
  ///
  /// In en, this message translates to:
  /// **'Update NID & date of birth'**
  String get updateIdentity;

  /// No description provided for @updateIdentityBody.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your full NID number. For your privacy we only keep its last 4 digits.'**
  String get updateIdentityBody;

  /// No description provided for @identityReviewNote.
  ///
  /// In en, this message translates to:
  /// **'If your details need a manual check, posting pauses until they\'re approved.'**
  String get identityReviewNote;

  /// No description provided for @identityUpdated.
  ///
  /// In en, this message translates to:
  /// **'Identity details updated.'**
  String get identityUpdated;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @helpInfo.
  ///
  /// In en, this message translates to:
  /// **'Help & info'**
  String get helpInfo;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it’s you'**
  String get verifyTitle;

  /// No description provided for @verifyPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'For your security, enter your password to continue.'**
  String get verifyPasswordBody;

  /// No description provided for @verifyCodeBody.
  ///
  /// In en, this message translates to:
  /// **'For your security, we’ll text a 6-digit code to {phone}.'**
  String verifyCodeBody(String phone);

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @useCodeInstead.
  ///
  /// In en, this message translates to:
  /// **'Use an SMS code instead'**
  String get useCodeInstead;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use my password instead'**
  String get usePasswordInstead;

  /// No description provided for @verifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get verifyContinue;

  /// No description provided for @errReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm it’s you first.'**
  String get errReauthRequired;

  /// No description provided for @passwordChooseIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose a password so you can sign in without waiting for an SMS.'**
  String get passwordChooseIntro;

  /// No description provided for @sectionHazards.
  ///
  /// In en, this message translates to:
  /// **'Hazards'**
  String get sectionHazards;

  /// No description provided for @sectionTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic watch'**
  String get sectionTraffic;

  /// No description provided for @searchPlate.
  ///
  /// In en, this message translates to:
  /// **'Search a number plate'**
  String get searchPlate;

  /// No description provided for @allVehicles.
  ///
  /// In en, this message translates to:
  /// **'All vehicles'**
  String get allVehicles;

  /// No description provided for @trafficIntro.
  ///
  /// In en, this message translates to:
  /// **'Vehicles breaking traffic law, reported by citizens. The traffic division verifies each one before taking action.'**
  String get trafficIntro;

  /// No description provided for @noTrafficReports.
  ///
  /// In en, this message translates to:
  /// **'No traffic violations reported here yet.'**
  String get noTrafficReports;

  /// No description provided for @reportTypeHazard.
  ///
  /// In en, this message translates to:
  /// **'Hazard'**
  String get reportTypeHazard;

  /// No description provided for @reportTypeTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic violation'**
  String get reportTypeTraffic;

  /// No description provided for @vehicleTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleTypeLabel;

  /// No description provided for @violationsLabel.
  ///
  /// In en, this message translates to:
  /// **'What rule did it break?'**
  String get violationsLabel;

  /// No description provided for @plateLabel.
  ///
  /// In en, this message translates to:
  /// **'Number plate'**
  String get plateLabel;

  /// No description provided for @plateHelper.
  ///
  /// In en, this message translates to:
  /// **'Type it as written on the plate. Leave it empty if it isn’t readable.'**
  String get plateHelper;

  /// No description provided for @pickVehicle.
  ///
  /// In en, this message translates to:
  /// **'Choose the vehicle type.'**
  String get pickVehicle;

  /// No description provided for @pickViolation.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one violation.'**
  String get pickViolation;

  /// No description provided for @trafficSafety.
  ///
  /// In en, this message translates to:
  /// **'Stay safe: never film while driving and don’t confront anyone. Capture the vehicle and its plate, not people’s faces.'**
  String get trafficSafety;

  /// No description provided for @policyNote.
  ///
  /// In en, this message translates to:
  /// **'Report hazards, not people. Posts about any person, politician or celebrity, or for personal gain, are not published — repeated violations get the account banned.'**
  String get policyNote;

  /// No description provided for @policyWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'This can’t be published as written'**
  String get policyWarnTitle;

  /// No description provided for @policyIssuePolitical.
  ///
  /// In en, this message translates to:
  /// **'It mentions politics or a political figure.'**
  String get policyIssuePolitical;

  /// No description provided for @policyIssuePerson.
  ///
  /// In en, this message translates to:
  /// **'It seems to be about a specific person.'**
  String get policyIssuePerson;

  /// No description provided for @policyIssueCelebrity.
  ///
  /// In en, this message translates to:
  /// **'It mentions a celebrity or public personality.'**
  String get policyIssueCelebrity;

  /// No description provided for @policyIssuePersonalGain.
  ///
  /// In en, this message translates to:
  /// **'It looks like an ad, a private dispute or personal gain.'**
  String get policyIssuePersonalGain;

  /// No description provided for @policyIssueContact.
  ///
  /// In en, this message translates to:
  /// **'It contains a phone number, link or social media handle.'**
  String get policyIssueContact;

  /// No description provided for @policyWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Describe only the hazard — what it is and where. If you send it anyway, a moderator reviews it first and it stays hidden until approved. Posts that break the rules count as a strike; after 3 strikes the account is banned.'**
  String get policyWarnBody;

  /// No description provided for @editDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit description'**
  String get editDescription;

  /// No description provided for @sendForReview.
  ///
  /// In en, this message translates to:
  /// **'Send for review anyway'**
  String get sendForReview;

  /// No description provided for @sentForReview.
  ///
  /// In en, this message translates to:
  /// **'Sent for review. You’ll be notified when a moderator decides.'**
  String get sentForReview;

  /// No description provided for @communityRules.
  ///
  /// In en, this message translates to:
  /// **'Community rules'**
  String get communityRules;

  /// No description provided for @rulesIntro.
  ///
  /// In en, this message translates to:
  /// **'Sajag exists to warn people about public hazards. To keep it fair and safe:'**
  String get rulesIntro;

  /// No description provided for @rule1.
  ///
  /// In en, this message translates to:
  /// **'Report only public hazards and traffic violations.'**
  String get rule1;

  /// No description provided for @rule2.
  ///
  /// In en, this message translates to:
  /// **'Never post about a person, politician, political party or celebrity — no names, accusations or campaigns.'**
  String get rule2;

  /// No description provided for @rule3.
  ///
  /// In en, this message translates to:
  /// **'No ads, sales, private disputes, revenge or anything for personal gain.'**
  String get rule3;

  /// No description provided for @rule4.
  ///
  /// In en, this message translates to:
  /// **'No phone numbers, links or social media handles.'**
  String get rule4;

  /// No description provided for @rule5.
  ///
  /// In en, this message translates to:
  /// **'Photos must be live and real. Capture the problem or the vehicle, not people’s faces.'**
  String get rule5;

  /// No description provided for @rule6.
  ///
  /// In en, this message translates to:
  /// **'Posts that break these rules are not published. Each one is a strike; after 3 strikes the account is banned.'**
  String get rule6;

  /// No description provided for @agreeRules.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get agreeRules;

  /// No description provided for @modPending.
  ///
  /// In en, this message translates to:
  /// **'Being checked'**
  String get modPending;

  /// No description provided for @modHeld.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get modHeld;

  /// No description provided for @modRejected.
  ///
  /// In en, this message translates to:
  /// **'Not published'**
  String get modRejected;

  /// No description provided for @modHeldBody.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this post for now. A moderator is checking it against the community rules.'**
  String get modHeldBody;

  /// No description provided for @modRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'This post was not published because it breaks the community rules.'**
  String get modRejectedBody;

  /// No description provided for @nPostHeld.
  ///
  /// In en, this message translates to:
  /// **'Your post is under review before it can be published'**
  String get nPostHeld;

  /// No description provided for @nPostApproved.
  ///
  /// In en, this message translates to:
  /// **'Your post was approved and is now public'**
  String get nPostApproved;

  /// No description provided for @nPostRejected.
  ///
  /// In en, this message translates to:
  /// **'Your post broke the community rules and was not published. Warning {strikes} of {limit}.'**
  String nPostRejected(int strikes, int limit);

  /// No description provided for @nAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended for repeatedly breaking the community rules.'**
  String get nAccountSuspended;

  /// No description provided for @trafficOpen.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get trafficOpen;

  /// No description provided for @trafficAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Under verification'**
  String get trafficAcknowledged;

  /// No description provided for @trafficInProgress.
  ///
  /// In en, this message translates to:
  /// **'Case in progress'**
  String get trafficInProgress;

  /// No description provided for @trafficResolved.
  ///
  /// In en, this message translates to:
  /// **'Action taken'**
  String get trafficResolved;

  /// No description provided for @trafficDetails.
  ///
  /// In en, this message translates to:
  /// **'Violation details'**
  String get trafficDetails;

  /// No description provided for @plateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Plate not readable'**
  String get plateUnknown;

  /// No description provided for @verifyAction.
  ///
  /// In en, this message translates to:
  /// **'I verify'**
  String get verifyAction;

  /// No description provided for @verifiedAction.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedAction;

  /// No description provided for @verifyExplain.
  ///
  /// In en, this message translates to:
  /// **'Saw this too? Verify it so authorities know it’s real.'**
  String get verifyExplain;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
