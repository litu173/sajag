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
  String get seeItToo => 'আমিও দেখেছি';

  @override
  String confirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count জন দেখেছেন',
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
  String get statusOpen => 'রিপোর্ট করা হয়েছে';

  @override
  String get statusAcknowledged => 'গৃহীত';

  @override
  String get statusInProgress => 'কাজ চলছে';

  @override
  String get statusResolved => 'সমাধান হয়েছে';

  @override
  String get statusHidden => 'পর্যালোচনায়';

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
}
