// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'সজাগ';

  @override
  String get tagline => 'দেখুন। ছবি তুলুন। সমাধান করুন।';

  @override
  String get demoBanner => 'ডেমো মোড · নমুনা তথ্য, কিছুই ফোনের বাইরে যায় না';

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get continueLabel => 'এগিয়ে যান';

  @override
  String get next => 'পরবর্তী';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get delete => 'মুছে ফেলুন';

  @override
  String get errorGeneric => 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get errorNetwork => 'ইন্টারনেট সংযোগ নেই। নেটওয়ার্ক দেখে আবার চেষ্টা করুন।';

  @override
  String get chooseLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get onboard1Title => 'রাস্তায় কোনো সমস্যা দেখেছেন?';

  @override
  String get onboard1Body =>
      'খোলা ম্যানহোল, ভাঙা রাস্তা, ময়লা, জলাবদ্ধতা — সরাসরি ছবি তুলুন আর পুরো এলাকাকে জানিয়ে দিন।';

  @override
  String get onboard2Title => 'আপনার পরিচয় থাকবে গোপন';

  @override
  String get onboard2Body =>
      'ভুয়া রিপোর্ট ঠেকাতে প্রত্যেক নাগরিককে মোবাইল ও এনআইডি দিয়ে যাচাই করা হয়, কিন্তু আপনার নাম কখনো দেখানো হয় না। অন্যরা শুধু একটি ছদ্মনাম দেখেন।';

  @override
  String get onboard3Title => 'সবাই মিলে শহর বদলাই';

  @override
  String get onboard3Body =>
      'অন্যদের রিপোর্ট নিশ্চিত করুন, ব্যাজ অর্জন করুন, আর লাইভ ম্যাপে দেখুন সমস্যার সমাধান হচ্ছে।';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get phoneTitle => 'আপনার মোবাইল নম্বর দিন';

  @override
  String get phoneSubtitle => 'এসএমএসে একটি ৬ সংখ্যার কোড পাঠানো হবে।';

  @override
  String get phoneLabel => 'মোবাইল নম্বর';

  @override
  String get phoneInvalid => 'সঠিক বাংলাদেশি মোবাইল নম্বর দিন (০১ দিয়ে শুরু, ১১ সংখ্যা)';

  @override
  String get sendCode => 'কোড পাঠান';

  @override
  String get otpTitle => 'কোডটি লিখুন';

  @override
  String otpSubtitle(String phone) {
    return '$phone নম্বরে পাঠানো হয়েছে';
  }

  @override
  String get otpDemoHint => 'ডেমো কোড: 123456';

  @override
  String resendIn(int seconds) {
    return '$seconds সেকেন্ড পর আবার পাঠানো যাবে';
  }

  @override
  String get resend => 'আবার কোড পাঠান';

  @override
  String get verify => 'যাচাই করুন';

  @override
  String get changeNumber => 'নম্বর পরিবর্তন';

  @override
  String get nidTitle => 'আপনি যে প্রকৃত নাগরিক তা যাচাই করুন';

  @override
  String get nidSubtitle =>
      'আপনার এনআইডি একবার যাচাই করা হয় এবং শুধু একমুখী সংকেত হিসেবে সংরক্ষিত থাকে। এটি কাউকে কখনো দেখানো হয় না।';

  @override
  String get nidLabel => 'এনআইডি নম্বর';

  @override
  String get nidHelper => '১০, ১৩ অথবা ১৭ সংখ্যা';

  @override
  String get dobLabel => 'জন্ম তারিখ';

  @override
  String get dobPick => 'জন্ম তারিখ নির্বাচন করুন';

  @override
  String get verifyIdentity => 'পরিচয় যাচাই করুন';

  @override
  String get privacyPromise => 'আপনার রিপোর্ট সবসময় বেনামি থাকবে।';

  @override
  String get pendingTitle => 'যাচাই প্রক্রিয়াধীন';

  @override
  String get pendingBody => 'পরিচয় নিশ্চিত হলেই আপনাকে জানানো হবে। সাধারণত এক দিনের কম সময় লাগে।';

  @override
  String get checkAgain => 'আবার দেখুন';

  @override
  String get errInvalidOtp => 'কোডটি ভুল অথবা মেয়াদ শেষ।';

  @override
  String get errInvalidNid => 'সঠিক এনআইডি নম্বর দিন (১০, ১৩ অথবা ১৭ সংখ্যা)।';

  @override
  String get errInvalidDob => 'সঠিক জন্ম তারিখ দিন। বয়স কমপক্ষে ১৩ হতে হবে।';

  @override
  String get errNidTaken => 'এই এনআইডি ইতিমধ্যে অন্য একটি অ্যাকাউন্টে যুক্ত।';

  @override
  String get errNotVerified => 'আগে আপনার পরিচয় যাচাই করুন।';

  @override
  String get errBlocked => 'আপনার অ্যাকাউন্ট সীমিত করা হয়েছে। সাপোর্টে যোগাযোগ করুন।';

  @override
  String get errRateLimited => 'আজকের রিপোর্টের সীমা শেষ। আগামীকাল আবার চেষ্টা করুন।';

  @override
  String get errStaleCapture => 'ছবিটি অনেক পুরোনো। নতুন করে ছবি তুলুন।';

  @override
  String get errOwnReport => 'নিজের রিপোর্ট নিজে নিশ্চিত করা যায় না।';

  @override
  String get errAlreadyDone => 'আপনি এটি আগেই করেছেন।';

  @override
  String get locationTitle => 'লোকেশন চালু করুন';

  @override
  String get locationBody =>
      'সজাগ প্রতিটি রিপোর্টে ঘটনার স্থান যুক্ত করে এবং আপনার আশেপাশের সমস্যা দেখায়। অ্যাপ ব্যবহারে লোকেশন প্রয়োজন।';

  @override
  String get allowLocation => 'লোকেশন অনুমতি দিন';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get locationServiceOff => 'ফোনের লোকেশন বন্ধ আছে। চালিয়ে যেতে লোকেশন চালু করুন।';

  @override
  String get locationDeniedForever => 'লোকেশন অনুমতি বন্ধ করা আছে। চালিয়ে যেতে সেটিংস থেকে চালু করুন।';

  @override
  String get navFeed => 'হোম';

  @override
  String get navMap => 'ম্যাপ';

  @override
  String get navReport => 'রিপোর্ট';

  @override
  String get navAchievements => 'ব্যাজ';

  @override
  String get navProfile => 'আমি';

  @override
  String get feedNearby => 'কাছাকাছি';

  @override
  String get feedLatest => 'সর্বশেষ';

  @override
  String get feedFollowing => 'অনুসরণ';

  @override
  String get allCategories => 'সব';

  @override
  String get emptyNearby => 'আপনার কাছাকাছি এখনো কোনো রিপোর্ট নেই। প্রথম রিপোর্টটি আপনিই করুন!';

  @override
  String get emptyFollowing => 'নাগরিকদের অনুসরণ করুন, তাদের রিপোর্ট এখানে দেখবেন।';

  @override
  String get emptyCategory => 'এই ক্যাটাগরিতে এখনো কোনো রিপোর্ট নেই।';

  @override
  String get demoLocationNote => 'ডেমো: আপনি বাংলাদেশের বাইরে, তাই ঢাকা দেখানো হচ্ছে';

  @override
  String confirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count জন নিশ্চিত করেছেন',
      zero: 'প্রথম নিশ্চিতকারী হোন',
    );
    return '$_temp0';
  }

  @override
  String get anonymousCitizen => 'বেনামি নাগরিক';

  @override
  String get awarenessTag => 'সচেতনতা';

  @override
  String get reportAction => 'সমস্যা রিপোর্ট করুন';

  @override
  String get statusOpen => 'পোস্ট করা হয়েছে';

  @override
  String get statusAcknowledged => 'গৃহীত';

  @override
  String get statusInProgress => 'কাজ চলছে';

  @override
  String get statusResolved => 'সমাধান হয়েছে';

  @override
  String get statusHidden => 'রিপোর্ট করা হয়েছে';

  @override
  String get statusRemoved => 'সরানো হয়েছে';

  @override
  String get timeJustNow => 'এইমাত্র';

  @override
  String timeMinutes(int n) {
    return '$n মিনিট আগে';
  }

  @override
  String timeHours(int n) {
    return '$n ঘণ্টা আগে';
  }

  @override
  String timeDays(int n) {
    return '$n দিন আগে';
  }

  @override
  String get reportTitle => 'রিপোর্ট';

  @override
  String get follow => 'অনুসরণ';

  @override
  String get followingButton => 'অনুসরণ করছেন';

  @override
  String get share => 'শেয়ার';

  @override
  String get flagReport => 'পোস্টটি রিপোর্ট করুন';

  @override
  String get openInMaps => 'ম্যাপে দেখুন';

  @override
  String get locationLabel => 'স্থান';

  @override
  String shareText(String category, String place) {
    return '$place-এ $category — সজাগ অ্যাপে রিপোর্ট করা হয়েছে';
  }

  @override
  String get deleteReport => 'রিপোর্ট মুছুন';

  @override
  String get deleteConfirm => 'রিপোর্টটি মুছে ফেলবেন? এটি আর ফেরত আনা যাবে না।';

  @override
  String get reportNotFound => 'এই রিপোর্টটি আর পাওয়া যাচ্ছে না।';

  @override
  String levelShort(int level) {
    return 'লেভেল $level';
  }

  @override
  String get flagTitle => 'এই পোস্টে কী সমস্যা?';

  @override
  String get flagFalse => 'মিথ্যা বা বিভ্রান্তিকর';

  @override
  String get flagLocation => 'ভুল স্থান';

  @override
  String get flagCategory => 'ভুল ক্যাটাগরি';

  @override
  String get flagInappropriate => 'অনুপযুক্ত ছবি';

  @override
  String get flagDuplicate => 'অন্য রিপোর্টের পুনরাবৃত্তি';

  @override
  String get flagSpam => 'স্প্যাম বা বিজ্ঞাপন';

  @override
  String get flagOther => 'অন্য কিছু';

  @override
  String get flagNoteHint => 'বিস্তারিত লিখুন (ঐচ্ছিক)';

  @override
  String get flagSubmit => 'মডারেটরদের পাঠান';

  @override
  String get flagThanks => 'ধন্যবাদ — আমাদের মডারেটররা বিষয়টি দেখবেন।';

  @override
  String get captureHint => 'সমস্যার দিকে ক্যামেরা ধরুন। শুধু সরাসরি তোলা ছবি দেওয়া যাবে — গ্যালারি থেকে নয়।';

  @override
  String get retake => 'আবার তুলুন';

  @override
  String get usePhoto => 'ছবিটি ব্যবহার করুন';

  @override
  String get cameraDenied => 'রিপোর্টের ছবি তুলতে ক্যামেরার অনুমতি প্রয়োজন।';

  @override
  String get cameraUnavailable => 'এই ডিভাইসে কোনো ক্যামেরা পাওয়া যায়নি।';

  @override
  String get flash => 'ফ্ল্যাশ';

  @override
  String get composeTitle => 'নতুন রিপোর্ট';

  @override
  String get categoryLabel => 'সমস্যাটি কী?';

  @override
  String get descriptionLabel => 'সংক্ষেপে বর্ণনা দিন';

  @override
  String get descriptionHint => 'যেমন: স্কুল গেটের পাশে ম্যানহোল খোলা';

  @override
  String get descriptionTooShort => 'আরও কয়েকটি শব্দ লিখুন।';

  @override
  String get locating => 'আপনার অবস্থান খোঁজা হচ্ছে…';

  @override
  String locationAccuracy(int meters) {
    return 'প্রায় $meters মিটার নির্ভুল';
  }

  @override
  String get showAlias => 'আমার ছদ্মনাম দেখাও';

  @override
  String showAliasOn(String alias) {
    return '$alias নামে পোস্ট হবে। আপনার অনুসারীরা নোটিফিকেশন পাবেন।';
  }

  @override
  String get showAliasOff => 'বেনামি নাগরিক হিসেবে পোস্ট হবে, আপনার ছদ্মনামের সাথে যুক্ত থাকবে না।';

  @override
  String get identityNeverShown => 'আপনার আসল নাম, ফোন নম্বর ও এনআইডি কখনো কাউকে দেখানো হয় না।';

  @override
  String get submitReport => 'রিপোর্ট পোস্ট করুন';

  @override
  String get posted => 'রিপোর্ট পোস্ট হয়েছে! এলাকাকে নিরাপদ রাখতে সাহায্য করার জন্য ধন্যবাদ।';

  @override
  String get mockLocation => 'ভুয়া জিপিএস শনাক্ত হয়েছে। পোস্ট করতে মক-লোকেশন অ্যাপ বন্ধ করুন।';

  @override
  String get pickCategory => 'একটি ক্যাটাগরি বেছে নিন';

  @override
  String get mapLast24h => '২৪ ঘণ্টা';

  @override
  String get mapLast7d => '৭ দিন';

  @override
  String get mapLast30d => '৩০ দিন';

  @override
  String mapReportsHere(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'এখানে $countটি রিপোর্ট');
    return '$_temp0';
  }

  @override
  String get locateMe => 'আমার অবস্থান';

  @override
  String get mapLegendFew => 'কম';

  @override
  String get mapLegendMany => 'বেশি';

  @override
  String get achievementsTitle => 'অর্জন';

  @override
  String get tabBadges => 'ব্যাজ';

  @override
  String get tabLeaderboard => 'লিডারবোর্ড';

  @override
  String levelLabel(int level) {
    return 'লেভেল $level';
  }

  @override
  String xpToNext(int xp, String name) {
    return '$name হতে আর $xp XP';
  }

  @override
  String get maxLevel => 'সর্বোচ্চ লেভেলে পৌঁছেছেন — আপনি কিংবদন্তি!';

  @override
  String get statReports => 'রিপোর্ট';

  @override
  String get statResolved => 'সমাধান';

  @override
  String get statConfirms => 'অন্যরা নিশ্চিত করেছেন';

  @override
  String get statStreak => 'টানা দিন';

  @override
  String badgesEarned(int earned, int total) {
    return '$totalটির মধ্যে $earnedটি অর্জিত';
  }

  @override
  String get badgeEarned => 'অর্জিত';

  @override
  String get badgeLocked => 'এখনো অর্জিত হয়নি';

  @override
  String badgeReward(int xp) {
    return '+$xp XP';
  }

  @override
  String get periodWeek => 'এই সপ্তাহ';

  @override
  String get periodMonth => 'এই মাস';

  @override
  String get periodAll => 'সর্বকাল';

  @override
  String get leaderboardPrivacy => 'সবাই শুধু ছদ্মনামে দেখা যায়। আপনি আসলে কে, তা কেউ জানতে পারে না।';

  @override
  String get you => 'আপনি';

  @override
  String points(int n) {
    return '$n XP';
  }

  @override
  String get emptyLeaderboard => 'বোর্ডে এখনো কেউ নেই — রিপোর্ট করে প্রথম হোন!';

  @override
  String get verifiedCitizen => 'যাচাইকৃত নাগরিক';

  @override
  String get followers => 'অনুসারী';

  @override
  String get followingLabel => 'অনুসরণ করছেন';

  @override
  String get myReports => 'আমার রিপোর্ট';

  @override
  String get noReportsYet => 'আপনি এখনো কোনো রিপোর্ট করেননি।';

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get textSize => 'লেখার আকার';

  @override
  String get textNormal => 'স্বাভাবিক';

  @override
  String get textLarge => 'বড়';

  @override
  String get textExtraLarge => 'অনেক বড়';

  @override
  String get privacy => 'গোপনীয়তা ও বেনামি';

  @override
  String get privacyBody =>
      '• আপনার ফোন নম্বর ও এনআইডি শুধু নিশ্চিত করে যে প্রত্যেক রিপোর্টকারী একজন প্রকৃত ও স্বতন্ত্র মানুষ।\n• এনআইডি নম্বর নিজে সংরক্ষিত হয় না, শুধু একমুখী সংকেত রাখা হয়।\n• অন্যরা শুধু আপনার ছদ্মনাম দেখেন — বেনামি পোস্ট করলে তাও নয়।\n• ছবির স্থান সবার জন্য উন্মুক্ত; আপনার পরিচয় নয়।\n• মডারেটররা আপনার পরিচয় না জেনেই ভুয়া রিপোর্টকারীর অ্যাকাউন্ট সীমিত করতে পারেন।';

  @override
  String get about => 'সজাগ সম্পর্কে';

  @override
  String get aboutBody =>
      'সজাগ নাগরিকদের নিরাপদে ও প্রকাশ্যে নাগরিক সমস্যা রিপোর্ট করতে সাহায্য করে, যাতে প্রতিবেশীরা সচেতন থাকেন এবং দায়িত্বপ্রাপ্ত কর্তৃপক্ষ ব্যবস্থা নিতে পারে।';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get signOutConfirm => 'সজাগ থেকে সাইন আউট করবেন?';

  @override
  String get notificationsTitle => 'নোটিফিকেশন';

  @override
  String get noNotifications => 'নতুন কিছু নেই।';

  @override
  String nFollowedPost(String alias, String category) {
    return '$alias নতুন রিপোর্ট করেছেন: $category';
  }

  @override
  String nBadge(String badge) {
    return 'আপনি “$badge” ব্যাজ অর্জন করেছেন!';
  }

  @override
  String get nResolved => 'আপনার রিপোর্টের সমাধান হয়েছে 🎉';

  @override
  String get nConfirmedResolved => 'আপনার নিশ্চিত করা একটি সমস্যার সমাধান হয়েছে';

  @override
  String get nRemoved => 'মডারেটররা আপনার রিপোর্টটি সরিয়ে দিয়েছেন';

  @override
  String get nFollower => 'একজন নাগরিক আপনাকে অনুসরণ করছেন';

  @override
  String nMilestone(int count) {
    return '$count জন আপনার রিপোর্ট নিশ্চিত করেছেন';
  }

  @override
  String get nVerifyApproved => 'আপনার পরিচয় যাচাই হয়েছে। এখন আপনি রিপোর্ট করতে পারবেন।';

  @override
  String get nVerifyRejected => 'পরিচয় যাচাই ব্যর্থ হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get citizenTitle => 'নাগরিক';

  @override
  String get markSolved => 'সমাধান হয়েছে চিহ্নিত করুন';

  @override
  String get markSolvedTitle => 'সমস্যাটির কি সমাধান হয়েছে?';

  @override
  String get markSolvedBody =>
      'সমস্যা সত্যিই দূর হলে তবেই সমাধান চিহ্নিত করুন। যারা নিশ্চিত করেছিলেন তাদের জানানো হবে।';

  @override
  String get markSolvedNoteHint => 'কী পরিবর্তন হয়েছে? (ঐচ্ছিক)';

  @override
  String get markSolvedDone => 'সমাধান চিহ্নিত হয়েছে। ধন্যবাদ!';

  @override
  String solvedIn(String duration) {
    return '$duration সমাধান হয়েছে';
  }

  @override
  String durationHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n ঘণ্টায়');
    return '$_temp0';
  }

  @override
  String durationDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n দিনে');
    return '$_temp0';
  }

  @override
  String get markedByReporter => 'রিপোর্টকারী নিজে সমাধান চিহ্নিত করেছেন';

  @override
  String get markedByModerator => 'মডারেটর সমাধান নিশ্চিত করেছেন';

  @override
  String get latestVersion => 'অ্যাপ সংস্করণ';

  @override
  String currentVersion(String version) {
    return 'আপনার সংস্করণ $version';
  }

  @override
  String updateAvailable(String version) {
    return 'নতুন সংস্করণ $version এসেছে';
  }

  @override
  String upToDate(String version) {
    return 'আপনার কাছে সর্বশেষ সংস্করণ আছে ($version)';
  }

  @override
  String get checkingUpdate => 'আপডেট খোঁজা হচ্ছে…';

  @override
  String get updateCheckFailed => 'আপডেট দেখা যায়নি। ইন্টারনেট সংযোগ দেখুন।';

  @override
  String get downloadLatest => 'সর্বশেষ সংস্করণ ডাউনলোড করুন';

  @override
  String get iosInstallNote =>
      'অ্যাপ স্টোরে আসার আগ পর্যন্ত আইফোনে ডাউনলোড করা ফাইলটি Sideloadly বা AltStore দিয়ে ইনস্টল করুন।';

  @override
  String get filterPosts => 'পোস্ট ফিল্টার';

  @override
  String get nearMe => 'আমার কাছাকাছি';

  @override
  String get everywhere => 'সব এলাকা';

  @override
  String get chooseArea => 'এলাকা বেছে নিন';

  @override
  String get searchArea => 'এলাকা খুঁজুন';

  @override
  String get useMyLocation => 'আমার বর্তমান অবস্থান ব্যবহার করুন';

  @override
  String get showAll => 'সব দেখুন';

  @override
  String get allCategoriesTitle => 'সব ক্যাটাগরি';

  @override
  String get clearCategory => 'সব ক্যাটাগরি';

  @override
  String earnedInPeriod(int count, String period) {
    return '$period: $countটি অর্জিত';
  }

  @override
  String get newBadge => 'নতুন';

  @override
  String get versionTitle => 'অ্যাপ সংস্করণ';

  @override
  String get accountSettings => 'অ্যাকাউন্ট সেটিংস';

  @override
  String get publicProfileSection => 'পাবলিক প্রোফাইল';

  @override
  String get publicProfileHint => 'অন্য নাগরিকেরা শুধু এটুকুই দেখতে পান।';

  @override
  String get avatarLabel => 'প্রোফাইল ইমোজি';

  @override
  String get aliasLabel => 'ছদ্মনাম';

  @override
  String get identitySection => 'ব্যক্তিগত পরিচয়';

  @override
  String get identityHint => 'শুধু আপনাকে যাচাই করতে ব্যবহৃত হয়। কাউকে কখনো দেখানো হয় না।';

  @override
  String get idVerified => 'যাচাইকৃত';

  @override
  String get idPending => 'যাচাই চলছে';

  @override
  String get securitySection => 'নিরাপত্তা';

  @override
  String get passwordLabel => 'পাসওয়ার্ড';

  @override
  String get passwordNotSet => 'সেট করা নেই · এসএমএস কোড দিয়ে সাইন ইন করেন';

  @override
  String get passwordIsSet => 'চালু · কোড বা পাসওয়ার্ড দিয়ে সাইন ইন';

  @override
  String get setPassword => 'পাসওয়ার্ড সেট করুন';

  @override
  String get changePassword => 'পাসওয়ার্ড পরিবর্তন করুন';

  @override
  String passwordIntro(String phone) {
    return 'এসএমএসের অপেক্ষা ছাড়াই সাইন ইন করতে পাসওয়ার্ড যোগ করুন। প্রথমে $phone নম্বরে একটি কোড পাঠাব।';
  }

  @override
  String get newPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get confirmPassword => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get passwordMismatch => 'পাসওয়ার্ড মেলেনি।';

  @override
  String get passwordRule => 'অন্তত ৮ অক্ষর, একটি বর্ণ ও একটি সংখ্যাসহ।';

  @override
  String get passwordSaved => 'পাসওয়ার্ড সংরক্ষিত হয়েছে।';

  @override
  String get showPassword => 'পাসওয়ার্ড দেখুন';

  @override
  String get hidePassword => 'পাসওয়ার্ড লুকান';

  @override
  String get signInWithPassword => 'পাসওয়ার্ড দিয়ে সাইন ইন';

  @override
  String get signInWithCode => 'এর বদলে এসএমএস কোড দিয়ে সাইন ইন';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get deleteAccount => 'অ্যাকাউন্ট মুছে ফেলুন';

  @override
  String get deleteAccountHint => 'আপনার প্রোফাইল, রিপোর্ট ও ছবি স্থায়ীভাবে মুছে যাবে।';

  @override
  String get deleteAccountConfirm => 'অ্যাকাউন্ট মুছে ফেলবেন?';

  @override
  String get deleteAccountBody =>
      'আপনার ছদ্মনাম, এক্সপি, ব্যাজ, রিপোর্ট ও ছবি স্থায়ীভাবে মুছে যাবে। এটি আর ফেরানো যাবে না।';

  @override
  String get deleteAccountType => 'নিশ্চিত করতে DELETE লিখুন';

  @override
  String get accountDeleted => 'আপনার অ্যাকাউন্ট মুছে ফেলা হয়েছে।';

  @override
  String get chooseEmoji => 'আপনার ইমোজি বেছে নিন';

  @override
  String get emojiBackground => 'পটভূমি';

  @override
  String get emojiUseAlias => 'ছদ্মনামের প্রাণী';

  @override
  String get emojiCatAnimals => 'প্রাণী';

  @override
  String get emojiCatNature => 'প্রকৃতি';

  @override
  String get emojiCatFaces => 'মুখ';

  @override
  String get emojiCatFood => 'খাবার';

  @override
  String get emojiCatActivity => 'খেলাধুলা';

  @override
  String get emojiCatPlaces => 'স্থান';

  @override
  String get emojiCatObjects => 'বস্তু';

  @override
  String get emojiCatSymbols => 'প্রতীক';

  @override
  String get saveChanges => 'সংরক্ষণ করুন';

  @override
  String get savedMessage => 'সংরক্ষিত হয়েছে।';

  @override
  String get changeAlias => 'ছদ্মনাম পরিবর্তন করুন';

  @override
  String get aliasHelper => 'বাংলা বা ইংরেজিতে ৩–২৪টি অক্ষর বা সংখ্যা।';

  @override
  String get aliasWarning => 'বেনামি রাখুন: আসল নাম, ফোন নম্বর বা এনআইডি ব্যবহার করবেন না।';

  @override
  String get aliasOncePerWeek => 'প্রতি ৭ দিনে একবার বদলানো যায়।';

  @override
  String aliasLockedUntil(String date) {
    return 'আবার বদলাতে পারবেন $date তারিখে।';
  }

  @override
  String get suggestAlias => 'একটি প্রস্তাব দিন';

  @override
  String get errInvalidAlias => '৩–২৪টি অক্ষর, সংখ্যা বা স্পেস দিন; লম্বা সংখ্যার ধারা নয়।';

  @override
  String get errAliasTaken => 'এই ছদ্মনাম আগেই নেওয়া। অন্যটি চেষ্টা করুন।';

  @override
  String get errAliasCooldown => 'আপনি সম্প্রতি ছদ্মনাম বদলেছেন। পরে চেষ্টা করুন।';

  @override
  String get errPhoneTaken => 'এই নম্বর ইতিমধ্যে ব্যবহৃত হচ্ছে।';

  @override
  String get errWeakPassword => 'অন্তত ৮ অক্ষর, একটি বর্ণ ও একটি সংখ্যা দিন।';

  @override
  String get errWrongPassword => 'নম্বর বা পাসওয়ার্ড ভুল।';

  @override
  String get changePhone => 'মোবাইল নম্বর পরিবর্তন করুন';

  @override
  String get newPhoneLabel => 'নতুন মোবাইল নম্বর';

  @override
  String codeSentTo(String phone) {
    return '$phone নম্বরে পাঠানো ৬ সংখ্যার কোড দিন';
  }

  @override
  String get codeLabel => 'যাচাই কোড';

  @override
  String get verifyAndSave => 'যাচাই করে সংরক্ষণ করুন';

  @override
  String get phoneChanged => 'মোবাইল নম্বর হালনাগাদ হয়েছে।';

  @override
  String get updateIdentity => 'এনআইডি ও জন্মতারিখ হালনাগাদ';

  @override
  String get updateIdentityBody => 'পুরো এনআইডি নম্বর আবার দিন। গোপনীয়তার জন্য আমরা শুধু শেষ ৪ সংখ্যা রাখি।';

  @override
  String get identityReviewNote => 'তথ্য হাতে যাচাই করতে হলে অনুমোদন না হওয়া পর্যন্ত পোস্ট করা বন্ধ থাকবে।';

  @override
  String get identityUpdated => 'পরিচয়ের তথ্য হালনাগাদ হয়েছে।';

  @override
  String get preferences => 'পছন্দসমূহ';

  @override
  String get helpInfo => 'সহায়তা ও তথ্য';

  @override
  String get appearance => 'থিম';

  @override
  String get themeSystem => 'অটো';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get verifyTitle => 'আপনার পরিচয় নিশ্চিত করুন';

  @override
  String get verifyPasswordBody => 'নিরাপত্তার জন্য, চালিয়ে যেতে আপনার পাসওয়ার্ড দিন।';

  @override
  String verifyCodeBody(String phone) {
    return 'নিরাপত্তার জন্য, $phone নম্বরে ৬ সংখ্যার একটি কোড পাঠানো হবে।';
  }

  @override
  String get currentPassword => 'বর্তমান পাসওয়ার্ড';

  @override
  String get useCodeInstead => 'এর বদলে এসএমএস কোড ব্যবহার করুন';

  @override
  String get usePasswordInstead => 'এর বদলে পাসওয়ার্ড ব্যবহার করুন';

  @override
  String get verifyContinue => 'যাচাই করে এগিয়ে যান';

  @override
  String get errReauthRequired => 'প্রথমে আপনার পরিচয় নিশ্চিত করুন।';

  @override
  String get passwordChooseIntro => 'একটি পাসওয়ার্ড বেছে নিন, যাতে এসএমএসের অপেক্ষা ছাড়াই সাইন ইন করতে পারেন।';

  @override
  String get sectionHazards => 'সমস্যা';

  @override
  String get sectionTraffic => 'ট্রাফিক নজরদারি';

  @override
  String get searchPlate => 'নম্বরপ্লেট খুঁজুন';

  @override
  String get allVehicles => 'সব যানবাহন';

  @override
  String get trafficIntro =>
      'নাগরিকদের রিপোর্ট করা ট্রাফিক আইন ভঙ্গকারী যানবাহন। ট্রাফিক বিভাগ প্রতিটি রিপোর্ট যাচাই করে ব্যবস্থা নেয়।';

  @override
  String get noTrafficReports => 'এখানে এখনো কোনো ট্রাফিক আইন ভঙ্গের রিপোর্ট নেই।';

  @override
  String get reportTypeHazard => 'সমস্যা';

  @override
  String get reportTypeTraffic => 'ট্রাফিক আইন ভঙ্গ';

  @override
  String get vehicleTypeLabel => 'যানবাহন';

  @override
  String get violationsLabel => 'কোন আইন ভেঙেছে?';

  @override
  String get plateLabel => 'নম্বরপ্লেট';

  @override
  String get plateHelper => 'প্লেটে যেমন লেখা তেমন লিখুন। পড়া না গেলে খালি রাখুন।';

  @override
  String get pickVehicle => 'যানবাহনের ধরন বেছে নিন।';

  @override
  String get pickViolation => 'অন্তত একটি আইন ভঙ্গ বেছে নিন।';

  @override
  String get trafficSafety =>
      'নিরাপদ থাকুন: গাড়ি চালানোর সময় ছবি তুলবেন না, কারও সঙ্গে বিতণ্ডায় জড়াবেন না। মানুষের মুখ নয়, যানবাহন ও নম্বরপ্লেটের ছবি তুলুন।';

  @override
  String get policyNote =>
      'মানুষ নয়, সমস্যার রিপোর্ট করুন। কোনো ব্যক্তি, রাজনীতিবিদ বা তারকাকে নিয়ে কিংবা ব্যক্তিগত স্বার্থে করা পোস্ট প্রকাশ করা হয় না — বারবার নিয়ম ভাঙলে অ্যাকাউন্ট নিষিদ্ধ করা হয়।';

  @override
  String get policyWarnTitle => 'এভাবে লিখলে পোস্টটি প্রকাশ হবে না';

  @override
  String get policyIssuePolitical => 'এতে রাজনীতি বা রাজনৈতিক ব্যক্তির উল্লেখ আছে।';

  @override
  String get policyIssuePerson => 'এটি নির্দিষ্ট কোনো ব্যক্তিকে নিয়ে মনে হচ্ছে।';

  @override
  String get policyIssueCelebrity => 'এতে তারকা বা পরিচিত ব্যক্তির উল্লেখ আছে।';

  @override
  String get policyIssuePersonalGain => 'এটি বিজ্ঞাপন, ব্যক্তিগত বিরোধ বা ব্যক্তিগত স্বার্থের মতো মনে হচ্ছে।';

  @override
  String get policyIssueContact => 'এতে ফোন নম্বর, লিংক বা সোশ্যাল মিডিয়া আইডি আছে।';

  @override
  String get policyWarnBody =>
      'শুধু সমস্যাটি লিখুন — কী সমস্যা এবং কোথায়। তবুও পাঠালে মডারেটর আগে যাচাই করবেন, অনুমোদনের আগে পোস্টটি দেখা যাবে না। নিয়ম ভাঙা প্রতিটি পোস্ট একটি সতর্কতা হিসেবে গণ্য হয়; ৩টি হলে অ্যাকাউন্ট নিষিদ্ধ হয়।';

  @override
  String get editDescription => 'বিবরণ ঠিক করুন';

  @override
  String get sendForReview => 'তবুও যাচাইয়ে পাঠান';

  @override
  String get sentForReview => 'যাচাইয়ের জন্য পাঠানো হয়েছে। মডারেটরের সিদ্ধান্ত আপনাকে জানানো হবে।';

  @override
  String get communityRules => 'কমিউনিটির নিয়ম';

  @override
  String get rulesIntro => 'সজাগ মানুষকে জনসাধারণের বিপদ সম্পর্কে সতর্ক করার জন্য। একে ন্যায্য ও নিরাপদ রাখতে:';

  @override
  String get rule1 => 'শুধু জনসাধারণের বিপদ ও ট্রাফিক আইন ভঙ্গের রিপোর্ট করুন।';

  @override
  String get rule2 =>
      'কোনো ব্যক্তি, রাজনীতিবিদ, রাজনৈতিক দল বা তারকাকে নিয়ে পোস্ট করবেন না — নাম, অভিযোগ বা প্রচারণা নয়।';

  @override
  String get rule3 => 'বিজ্ঞাপন, বেচাকেনা, ব্যক্তিগত বিরোধ, প্রতিশোধ বা ব্যক্তিগত স্বার্থে কিছু নয়।';

  @override
  String get rule4 => 'ফোন নম্বর, লিংক বা সোশ্যাল মিডিয়া আইডি দেবেন না।';

  @override
  String get rule5 => 'ছবি অবশ্যই সরাসরি তোলা ও সত্য হতে হবে। মানুষের মুখ নয়, সমস্যা বা যানবাহনের ছবি তুলুন।';

  @override
  String get rule6 =>
      'নিয়ম ভাঙা পোস্ট প্রকাশ করা হয় না। প্রতিটি একটি সতর্কতা; ৩টি সতর্কতার পর অ্যাকাউন্ট নিষিদ্ধ করা হয়।';

  @override
  String get agreeRules => 'আমি সম্মত';

  @override
  String get modPending => 'যাচাই চলছে';

  @override
  String get modHeld => 'পর্যালোচনায় আছে';

  @override
  String get modRejected => 'প্রকাশিত হয়নি';

  @override
  String get modHeldBody => 'আপাতত শুধু আপনি পোস্টটি দেখতে পাচ্ছেন। মডারেটর কমিউনিটির নিয়ম অনুযায়ী এটি যাচাই করছেন।';

  @override
  String get modRejectedBody => 'কমিউনিটির নিয়ম ভাঙায় পোস্টটি প্রকাশ করা হয়নি।';

  @override
  String get nPostHeld => 'প্রকাশের আগে আপনার পোস্টটি পর্যালোচনায় আছে';

  @override
  String get nPostApproved => 'আপনার পোস্ট অনুমোদিত হয়েছে এবং এখন সবাই দেখতে পাচ্ছে';

  @override
  String nPostRejected(int strikes, int limit) {
    return 'আপনার পোস্ট কমিউনিটির নিয়ম ভেঙেছে, তাই প্রকাশ করা হয়নি। সতর্কতা $limitটির মধ্যে $strikesটি।';
  }

  @override
  String get nAccountSuspended => 'বারবার কমিউনিটির নিয়ম ভাঙায় আপনার অ্যাকাউন্ট স্থগিত করা হয়েছে।';

  @override
  String get trafficOpen => 'রিপোর্ট করা হয়েছে';

  @override
  String get trafficAcknowledged => 'যাচাই চলছে';

  @override
  String get trafficInProgress => 'মামলা প্রক্রিয়াধীন';

  @override
  String get trafficResolved => 'ব্যবস্থা নেওয়া হয়েছে';

  @override
  String get trafficDetails => 'আইন ভঙ্গের বিবরণ';

  @override
  String get plateUnknown => 'নম্বরপ্লেট পড়া যায়নি';

  @override
  String get verifyAction => 'আমি নিশ্চিত';

  @override
  String get verifiedAction => 'নিশ্চিত করেছেন';

  @override
  String get verifyExplain => 'আপনিও দেখেছেন? নিশ্চিত করুন, যাতে কর্তৃপক্ষ বুঝতে পারে এটি সত্যি।';

  @override
  String get moreActions => 'আরও';
}
