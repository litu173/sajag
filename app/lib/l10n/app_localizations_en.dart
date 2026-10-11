// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sajag';

  @override
  String get tagline => 'See it. Snap it. Fix it.';

  @override
  String get demoBanner => 'Demo mode · sample data, nothing leaves your phone';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get continueLabel => 'Continue';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection. Check your network and try again.';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get onboard1Title => 'Seen a problem on the street?';

  @override
  String get onboard1Body =>
      'Open manholes, broken roads, garbage, waterlogging — snap a live photo and let your whole area know.';

  @override
  String get onboard2Title => 'Your identity stays secret';

  @override
  String get onboard2Body =>
      'Every citizen is verified with mobile and NID to stop fake reports, but your name is never shown. Others only see a random alias.';

  @override
  String get onboard3Title => 'Together we fix our city';

  @override
  String get onboard3Body => 'Confirm what others report, earn badges, and watch problems get solved on the live map.';

  @override
  String get getStarted => 'Get started';

  @override
  String get phoneTitle => 'Enter your mobile number';

  @override
  String get phoneSubtitle => 'We\'ll send you a 6-digit code by SMS.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneInvalid => 'Enter a valid Bangladeshi mobile number (11 digits, starts with 01)';

  @override
  String get sendCode => 'Send code';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'Sent to $phone';
  }

  @override
  String get otpDemoHint => 'Demo code: 123456';

  @override
  String resendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resend => 'Resend code';

  @override
  String get verify => 'Verify';

  @override
  String get changeNumber => 'Change number';

  @override
  String get nidTitle => 'Verify you\'re a real citizen';

  @override
  String get nidSubtitle =>
      'Your NID is checked once and stored only as a one-way fingerprint. It is never shown to anyone — not even other users.';

  @override
  String get nidLabel => 'NID number';

  @override
  String get nidHelper => '10, 13 or 17 digits';

  @override
  String get dobLabel => 'Date of birth';

  @override
  String get dobPick => 'Select your date of birth';

  @override
  String get verifyIdentity => 'Verify identity';

  @override
  String get privacyPromise => 'Your reports are always anonymous.';

  @override
  String get pendingTitle => 'Verification in review';

  @override
  String get pendingBody =>
      'We\'ll let you know as soon as your identity is confirmed. This usually takes less than a day.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get errInvalidOtp => 'That code is incorrect or has expired.';

  @override
  String get errInvalidNid => 'Enter a valid NID number (10, 13 or 17 digits).';

  @override
  String get errInvalidDob => 'Enter a valid date of birth. You must be at least 13.';

  @override
  String get errNidTaken => 'This NID is already linked to another account.';

  @override
  String get errNotVerified => 'Please verify your identity first.';

  @override
  String get errBlocked => 'Your account is restricted. Please contact support.';

  @override
  String get errRateLimited => 'You\'ve reached today\'s report limit. Please try again tomorrow.';

  @override
  String get errStaleCapture => 'This photo is too old. Please take a new one.';

  @override
  String get errOwnReport => 'You can\'t confirm your own report.';

  @override
  String get errAlreadyDone => 'You\'ve already done this.';

  @override
  String get locationTitle => 'Allow your location';

  @override
  String get locationBody =>
      'Sajag tags each report with where it happened and shows problems around you. Location is required to use the app.';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get openSettings => 'Open settings';

  @override
  String get locationServiceOff => 'Location is turned off on your phone. Please turn it on to continue.';

  @override
  String get locationDeniedForever => 'Location permission is blocked. Please enable it in Settings to continue.';

  @override
  String get navFeed => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navReport => 'Report';

  @override
  String get navAchievements => 'Badges';

  @override
  String get navProfile => 'Me';

  @override
  String get feedNearby => 'Nearby';

  @override
  String get feedLatest => 'Latest';

  @override
  String get feedFollowing => 'Following';

  @override
  String get allCategories => 'All';

  @override
  String get emptyNearby => 'No reports near you yet. Be the first to report!';

  @override
  String get emptyFollowing => 'Follow citizens to see their reports here.';

  @override
  String get emptyCategory => 'No reports in this category yet.';

  @override
  String get demoLocationNote => 'Demo: showing Dhaka because you\'re outside Bangladesh';

  @override
  String confirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people verified this',
      one: '1 person verified this',
      zero: 'Be the first to verify',
    );
    return '$_temp0';
  }

  @override
  String get anonymousCitizen => 'Anonymous citizen';

  @override
  String get awarenessTag => 'Awareness';

  @override
  String get reportAction => 'Report a problem';

  @override
  String get statusOpen => 'Posted';

  @override
  String get statusAcknowledged => 'Acknowledged';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusHidden => 'Flagged';

  @override
  String get statusRemoved => 'Removed';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutes(int n) {
    return '${n}m ago';
  }

  @override
  String timeHours(int n) {
    return '${n}h ago';
  }

  @override
  String timeDays(int n) {
    return '${n}d ago';
  }

  @override
  String get reportTitle => 'Report';

  @override
  String get follow => 'Follow';

  @override
  String get followingButton => 'Following';

  @override
  String get share => 'Share';

  @override
  String get flagReport => 'Flag this post';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get locationLabel => 'Location';

  @override
  String shareText(String category, String place) {
    return '$category reported at $place — via Sajag';
  }

  @override
  String get deleteReport => 'Delete report';

  @override
  String get deleteConfirm => 'Delete this report? This can\'t be undone.';

  @override
  String get reportNotFound => 'This report is no longer available.';

  @override
  String levelShort(int level) {
    return 'Lv $level';
  }

  @override
  String get flagTitle => 'What\'s wrong with this post?';

  @override
  String get flagFalse => 'False or misleading';

  @override
  String get flagLocation => 'Wrong location';

  @override
  String get flagCategory => 'Wrong category';

  @override
  String get flagInappropriate => 'Inappropriate photo';

  @override
  String get flagDuplicate => 'Duplicate of another report';

  @override
  String get flagSpam => 'Spam or advertising';

  @override
  String get flagOther => 'Something else';

  @override
  String get flagNoteHint => 'Add details (optional)';

  @override
  String get flagSubmit => 'Send to moderators';

  @override
  String get flagThanks => 'Thanks — our moderators will review it.';

  @override
  String get captureHint => 'Point at the problem. Only live photos are allowed — no gallery uploads.';

  @override
  String get retake => 'Retake';

  @override
  String get usePhoto => 'Use photo';

  @override
  String get cameraDenied => 'Camera access is needed to take report photos.';

  @override
  String get cameraUnavailable => 'No camera available on this device.';

  @override
  String get flash => 'Flash';

  @override
  String get composeTitle => 'New report';

  @override
  String get categoryLabel => 'What\'s the problem?';

  @override
  String get descriptionLabel => 'Describe it briefly';

  @override
  String get descriptionHint => 'e.g. Manhole open near the school gate';

  @override
  String get descriptionTooShort => 'Please add a few more words.';

  @override
  String get locating => 'Finding your location…';

  @override
  String locationAccuracy(int meters) {
    return 'Accurate to about $meters m';
  }

  @override
  String get showAlias => 'Show my alias';

  @override
  String showAliasOn(String alias) {
    return 'Posted as $alias. Your followers get notified.';
  }

  @override
  String get showAliasOff => 'Posted as an anonymous citizen, not linked to your alias.';

  @override
  String get identityNeverShown => 'Your real name, phone and NID are never shown to anyone.';

  @override
  String get submitReport => 'Post report';

  @override
  String get posted => 'Report posted! Thank you for keeping your area safe.';

  @override
  String get mockLocation => 'Fake GPS detected. Turn off mock-location apps to post.';

  @override
  String get pickCategory => 'Choose a category';

  @override
  String get mapLast24h => '24 hours';

  @override
  String get mapLast7d => '7 days';

  @override
  String get mapLast30d => '30 days';

  @override
  String mapReportsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports here',
      one: '1 report here',
    );
    return '$_temp0';
  }

  @override
  String get locateMe => 'My location';

  @override
  String get mapLegendFew => 'Few';

  @override
  String get mapLegendMany => 'Many';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get tabBadges => 'Badges';

  @override
  String get tabLeaderboard => 'Leaderboard';

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String xpToNext(int xp, String name) {
    return '$xp XP to $name';
  }

  @override
  String get maxLevel => 'Top level reached — you\'re a legend!';

  @override
  String get statReports => 'Reports';

  @override
  String get statResolved => 'Resolved';

  @override
  String get statConfirms => 'Confirmed by others';

  @override
  String get statStreak => 'Day streak';

  @override
  String badgesEarned(int earned, int total) {
    return '$earned of $total earned';
  }

  @override
  String get badgeEarned => 'Earned';

  @override
  String get badgeLocked => 'Not earned yet';

  @override
  String badgeReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get periodWeek => 'This week';

  @override
  String get periodMonth => 'This month';

  @override
  String get periodAll => 'All time';

  @override
  String get leaderboardPrivacy => 'Everyone appears by alias only. No one can see who you really are.';

  @override
  String get you => 'You';

  @override
  String points(int n) {
    return '$n XP';
  }

  @override
  String get emptyLeaderboard => 'No one on the board yet — post a report to be first!';

  @override
  String get verifiedCitizen => 'Verified citizen';

  @override
  String get followers => 'Followers';

  @override
  String get followingLabel => 'Following';

  @override
  String get myReports => 'My reports';

  @override
  String get noReportsYet => 'You haven\'t posted any reports yet.';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get textSize => 'Text size';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get textExtraLarge => 'Extra large';

  @override
  String get privacy => 'Privacy & anonymity';

  @override
  String get privacyBody =>
      '• Your phone number and NID are used only to make sure every reporter is a real, unique person.\n• Your NID is stored as a one-way fingerprint, never as the number itself.\n• Other people only ever see your random alias — or nothing at all if you post anonymously.\n• Photo locations are public; your identity is not.\n• Moderators can restrict accounts that post false reports without seeing who you are.';

  @override
  String get about => 'About Sajag';

  @override
  String get aboutBody =>
      'Sajag (সজাগ — “alert”) helps citizens report civic problems publicly and safely, so neighbours stay aware and the responsible authorities can act.';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of Sajag?';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'You\'re all caught up.';

  @override
  String nFollowedPost(String alias, String category) {
    return '$alias posted a new report: $category';
  }

  @override
  String nBadge(String badge) {
    return 'You earned the “$badge” badge!';
  }

  @override
  String get nResolved => 'Your report was marked resolved 🎉';

  @override
  String get nConfirmedResolved => 'A problem you confirmed has been resolved';

  @override
  String get nRemoved => 'Your report was removed by moderators';

  @override
  String get nFollower => 'A citizen started following you';

  @override
  String nMilestone(int count) {
    return '$count people have confirmed your report';
  }

  @override
  String get nVerifyApproved => 'Your identity has been verified. You can now post reports.';

  @override
  String get nVerifyRejected => 'Identity verification failed. Please try again.';

  @override
  String get citizenTitle => 'Citizen';

  @override
  String get markSolved => 'Mark as solved';

  @override
  String get markSolvedTitle => 'Is this problem fixed?';

  @override
  String get markSolvedBody =>
      'Only mark it solved if the problem is really gone. Everyone who confirmed it will be told.';

  @override
  String get markSolvedNoteHint => 'What changed? (optional)';

  @override
  String get markSolvedDone => 'Marked as solved. Thank you!';

  @override
  String solvedIn(String duration) {
    return 'Solved in $duration';
  }

  @override
  String durationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n hours', one: '1 hour');
    return '$_temp0';
  }

  @override
  String durationDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get markedByReporter => 'Marked solved by the reporter';

  @override
  String get markedByModerator => 'Confirmed solved by a moderator';

  @override
  String get latestVersion => 'App version';

  @override
  String currentVersion(String version) {
    return 'You have version $version';
  }

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String upToDate(String version) {
    return 'You have the latest version ($version)';
  }

  @override
  String get checkingUpdate => 'Checking for updates…';

  @override
  String get updateCheckFailed => 'Couldn\'t check for updates. Check your internet.';

  @override
  String get downloadLatest => 'Download latest version';

  @override
  String get iosInstallNote =>
      'On iPhone, install the downloaded file with Sideloadly or AltStore until Sajag is on the App Store.';

  @override
  String get filterPosts => 'Filter posts';

  @override
  String get nearMe => 'Near me';

  @override
  String get everywhere => 'Everywhere';

  @override
  String get chooseArea => 'Choose a location';

  @override
  String get searchArea => 'Search area';

  @override
  String get useMyLocation => 'Use my current location';

  @override
  String get showAll => 'Show all';

  @override
  String get allCategoriesTitle => 'All categories';

  @override
  String get clearCategory => 'All categories';

  @override
  String earnedInPeriod(int count, String period) {
    return '$count earned · $period';
  }

  @override
  String get newBadge => 'New';

  @override
  String get versionTitle => 'App version';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get publicProfileSection => 'Public profile';

  @override
  String get publicProfileHint => 'This is all other citizens ever see.';

  @override
  String get avatarLabel => 'Profile emoji';

  @override
  String get aliasLabel => 'Alias';

  @override
  String get identitySection => 'Private identity';

  @override
  String get identityHint => 'Used only to verify you. Never shown to anyone.';

  @override
  String get idVerified => 'Verified';

  @override
  String get idPending => 'Under review';

  @override
  String get securitySection => 'Security';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordNotSet => 'Not set · you sign in with an SMS code';

  @override
  String get passwordIsSet => 'On · sign in with code or password';

  @override
  String get setPassword => 'Set password';

  @override
  String get changePassword => 'Change password';

  @override
  String passwordIntro(String phone) {
    return 'Add a password to sign in without waiting for an SMS. First we\'ll send a code to $phone.';
  }

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMismatch => 'Passwords don\'t match.';

  @override
  String get passwordRule => 'At least 8 characters, with a letter and a number.';

  @override
  String get passwordSaved => 'Password saved.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signInWithPassword => 'Sign in with password';

  @override
  String get signInWithCode => 'Sign in with an SMS code instead';

  @override
  String get signIn => 'Sign in';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountHint => 'Removes your profile, reports and photos for good.';

  @override
  String get deleteAccountConfirm => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your alias, XP, badges, reports and photos will be permanently deleted. This can\'t be undone.';

  @override
  String get deleteAccountType => 'Type DELETE to confirm';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get chooseEmoji => 'Choose your emoji';

  @override
  String get emojiBackground => 'Background';

  @override
  String get emojiUseAlias => 'Alias animal';

  @override
  String get emojiCatAnimals => 'Animals';

  @override
  String get emojiCatNature => 'Nature';

  @override
  String get emojiCatFaces => 'Faces';

  @override
  String get emojiCatFood => 'Food';

  @override
  String get emojiCatActivity => 'Activity';

  @override
  String get emojiCatPlaces => 'Places';

  @override
  String get emojiCatObjects => 'Objects';

  @override
  String get emojiCatSymbols => 'Symbols';

  @override
  String get saveChanges => 'Save';

  @override
  String get savedMessage => 'Saved.';

  @override
  String get changeAlias => 'Change alias';

  @override
  String get aliasHelper => '3–24 letters or numbers, in Bangla or English.';

  @override
  String get aliasWarning => 'Keep it anonymous: don\'t use your real name, phone or NID.';

  @override
  String get aliasOncePerWeek => 'You can change it once every 7 days.';

  @override
  String aliasLockedUntil(String date) {
    return 'You can change it again on $date.';
  }

  @override
  String get suggestAlias => 'Suggest one';

  @override
  String get errInvalidAlias => 'Use 3–24 letters, numbers or spaces, without long number sequences.';

  @override
  String get errAliasTaken => 'That alias is taken. Try another.';

  @override
  String get errAliasCooldown => 'You changed your alias recently. Try again later.';

  @override
  String get errPhoneTaken => 'That number is already in use.';

  @override
  String get errWeakPassword => 'Use at least 8 characters with a letter and a number.';

  @override
  String get errWrongPassword => 'Wrong number or password.';

  @override
  String get changePhone => 'Change mobile number';

  @override
  String get newPhoneLabel => 'New mobile number';

  @override
  String codeSentTo(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get codeLabel => 'Verification code';

  @override
  String get verifyAndSave => 'Verify and save';

  @override
  String get phoneChanged => 'Mobile number updated.';

  @override
  String get updateIdentity => 'Update NID & date of birth';

  @override
  String get updateIdentityBody => 'Re-enter your full NID number. For your privacy we only keep its last 4 digits.';

  @override
  String get identityReviewNote => 'If your details need a manual check, posting pauses until they\'re approved.';

  @override
  String get identityUpdated => 'Identity details updated.';

  @override
  String get preferences => 'Preferences';

  @override
  String get helpInfo => 'Help & info';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get verifyTitle => 'Confirm it’s you';

  @override
  String get verifyPasswordBody => 'For your security, enter your password to continue.';

  @override
  String verifyCodeBody(String phone) {
    return 'For your security, we’ll text a 6-digit code to $phone.';
  }

  @override
  String get currentPassword => 'Current password';

  @override
  String get useCodeInstead => 'Use an SMS code instead';

  @override
  String get usePasswordInstead => 'Use my password instead';

  @override
  String get verifyContinue => 'Verify and continue';

  @override
  String get errReauthRequired => 'Please confirm it’s you first.';

  @override
  String get passwordChooseIntro => 'Choose a password so you can sign in without waiting for an SMS.';

  @override
  String get sectionHazards => 'Hazards';

  @override
  String get sectionTraffic => 'Traffic watch';

  @override
  String get searchPlate => 'Search a number plate';

  @override
  String get allVehicles => 'All vehicles';

  @override
  String get trafficIntro =>
      'Vehicles breaking traffic law, reported by citizens. The traffic division verifies each one before taking action.';

  @override
  String get noTrafficReports => 'No traffic violations reported here yet.';

  @override
  String get reportTypeHazard => 'Hazard';

  @override
  String get reportTypeTraffic => 'Traffic violation';

  @override
  String get vehicleTypeLabel => 'Vehicle';

  @override
  String get violationsLabel => 'What rule did it break?';

  @override
  String get plateLabel => 'Number plate';

  @override
  String get plateHelper => 'Type it as written on the plate. Leave it empty if it isn’t readable.';

  @override
  String get pickVehicle => 'Choose the vehicle type.';

  @override
  String get pickViolation => 'Choose at least one violation.';

  @override
  String get trafficSafety =>
      'Stay safe: never film while driving and don’t confront anyone. Capture the vehicle and its plate, not people’s faces.';

  @override
  String get policyNote =>
      'Report hazards, not people. Posts about any person, politician or celebrity, or for personal gain, are not published — repeated violations get the account banned.';

  @override
  String get policyWarnTitle => 'This can’t be published as written';

  @override
  String get policyIssuePolitical => 'It mentions politics or a political figure.';

  @override
  String get policyIssuePerson => 'It seems to be about a specific person.';

  @override
  String get policyIssueCelebrity => 'It mentions a celebrity or public personality.';

  @override
  String get policyIssuePersonalGain => 'It looks like an ad, a private dispute or personal gain.';

  @override
  String get policyIssueContact => 'It contains a phone number, link or social media handle.';

  @override
  String get policyWarnBody =>
      'Describe only the hazard — what it is and where. If you send it anyway, a moderator reviews it first and it stays hidden until approved. Posts that break the rules count as a strike; after 3 strikes the account is banned.';

  @override
  String get editDescription => 'Edit description';

  @override
  String get sendForReview => 'Send for review anyway';

  @override
  String get sentForReview => 'Sent for review. You’ll be notified when a moderator decides.';

  @override
  String get communityRules => 'Community rules';

  @override
  String get rulesIntro => 'Sajag exists to warn people about public hazards. To keep it fair and safe:';

  @override
  String get rule1 => 'Report only public hazards and traffic violations.';

  @override
  String get rule2 =>
      'Never post about a person, politician, political party or celebrity — no names, accusations or campaigns.';

  @override
  String get rule3 => 'No ads, sales, private disputes, revenge or anything for personal gain.';

  @override
  String get rule4 => 'No phone numbers, links or social media handles.';

  @override
  String get rule5 => 'Photos must be live and real. Capture the problem or the vehicle, not people’s faces.';

  @override
  String get rule6 =>
      'Posts that break these rules are not published. Each one is a strike; after 3 strikes the account is banned.';

  @override
  String get agreeRules => 'I agree';

  @override
  String get modPending => 'Being checked';

  @override
  String get modHeld => 'Under review';

  @override
  String get modRejected => 'Not published';

  @override
  String get modHeldBody =>
      'Only you can see this post for now. A moderator is checking it against the community rules.';

  @override
  String get modRejectedBody => 'This post was not published because it breaks the community rules.';

  @override
  String get nPostHeld => 'Your post is under review before it can be published';

  @override
  String get nPostApproved => 'Your post was approved and is now public';

  @override
  String nPostRejected(int strikes, int limit) {
    return 'Your post broke the community rules and was not published. Warning $strikes of $limit.';
  }

  @override
  String get nAccountSuspended => 'Your account is suspended for repeatedly breaking the community rules.';

  @override
  String get trafficOpen => 'Reported';

  @override
  String get trafficAcknowledged => 'Under verification';

  @override
  String get trafficInProgress => 'Case in progress';

  @override
  String get trafficResolved => 'Action taken';

  @override
  String get trafficDetails => 'Violation details';

  @override
  String get plateUnknown => 'Plate not readable';

  @override
  String get verifyAction => 'I verify';

  @override
  String get verifiedAction => 'Verified';

  @override
  String get verifyExplain => 'Saw this too? Verify it so authorities know it’s real.';

  @override
  String get moreActions => 'More';
}
