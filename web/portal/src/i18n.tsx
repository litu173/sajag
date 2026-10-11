import { createContext, type ReactNode, useContext, useEffect, useMemo, useState } from 'react';
import type { Lang } from '@sajag/shared';

const strings = {
  tagline: { bn: 'দেখুন। ছবি তুলুন। সমাধান করুন।', en: 'See it. Snap it. Fix it.' },
  navStories: { bn: 'রিপোর্ট', en: 'Stories' },
  navData: { bn: 'তথ্যচিত্র', en: 'Data' },
  navMap: { bn: 'ম্যাপ', en: 'Map' },
  navAwareness: { bn: 'সচেতনতা', en: 'Awareness' },
  getApp: { bn: 'অ্যাপ নিন', en: 'Get the app' },
  seeReport: { bn: 'রিপোর্টটি দেখুন', en: 'See the report' },
  heroLabel: { bn: 'আজকের আলোচিত', en: 'In focus today' },
  welcomeTitle: { bn: 'প্রতিটি ছবি একজন নাগরিকের কণ্ঠ', en: 'Every photo is a citizen’s voice' },
  welcomeBody: {
    bn: 'খোলা ম্যানহোল, ভাঙা রাস্তা, জলাবদ্ধতা, যত্রতত্র ময়লা — সারা দেশের নাগরিকেরা সরাসরি তোলা ছবিতে তুলে ধরছেন প্রতিদিনের সমস্যা। দেখুন, জানুন, সচেতন হোন।',
    en: 'Open manholes, broken roads, waterlogging, dumped garbage — citizens across the country capture everyday problems in live photos. See them, understand them, and help keep each other safe.',
  },
  statTotal: { bn: 'মোট রিপোর্ট', en: 'Reports' },
  statResolved: { bn: 'সমাধান হয়েছে', en: 'Resolved' },
  statWeek: { bn: 'এই সপ্তাহে', en: 'This week' },
  statAreas: { bn: 'এলাকা', en: 'Areas' },
  latestTitle: { bn: 'রাস্তা থেকে সর্বশেষ', en: 'Latest from the streets' },
  latestHint: { bn: 'নাগরিকদের তোলা সাম্প্রতিক ছবি', en: 'Recent photos taken by citizens' },
  browseTitle: { bn: 'সমস্যা অনুযায়ী দেখুন', en: 'Browse by problem' },
  browseHint: { bn: 'যে বিষয়টি আপনার এলাকায় বেশি চোখে পড়ে', en: 'Pick what you see most in your area' },
  reportsCount: { bn: 'টি রিপোর্ট', en: ' reports' },
  dataTitle: { bn: 'তথ্য যা বলছে', en: 'What the data says' },
  dataHint: { bn: 'গত ৯০ দিনের নাগরিক রিপোর্ট থেকে', en: 'From citizen reports over the last 90 days' },
  mostReported: { bn: 'সবচেয়ে বেশি রিপোর্ট হওয়া সমস্যা', en: 'Most reported problems' },
  mostAffected: { bn: 'সবচেয়ে বেশি আক্রান্ত এলাকা', en: 'Most affected areas' },
  trend: { bn: 'প্রতিদিনের রিপোর্ট, গত ৩০ দিন', en: 'Reports per day, last 30 days' },
  resolutionRate: { bn: 'সমাধানের হার', en: 'Resolution rate' },
  resolutionHint: { bn: 'রিপোর্ট হওয়া সমস্যার যত অংশের সমাধান হয়েছে', en: 'Share of reported problems that have been fixed' },
  solvingTitle: { bn: 'সমাধান কত দ্রুত হচ্ছে', en: 'How fast problems get fixed' },
  solvedCount: { bn: 'সমাধান হয়েছে', en: 'Solved' },
  avgFix: { bn: 'গড় সমাধানের সময়', en: 'Average time to fix' },
  medianFix: { bn: 'মধ্যমা সময়', en: 'Median time to fix' },
  within7: { bn: '৭ দিনের মধ্যে সমাধান', en: 'Fixed within 7 days' },
  fixByProblem: { bn: 'সমস্যা অনুযায়ী গড় সমাধানের সময় (দিন)', en: 'Average days to fix, by problem' },
  selfMarked: { bn: 'টি রিপোর্টকারী নিজে সমাধান চিহ্নিত করেছেন। কর্তৃপক্ষের নিশ্চিতকরণ আসবে পরবর্তী ধাপে।', en: ' were marked solved by the reporter themselves; confirmation by authorities arrives in the next phase.' },
  days: { bn: 'দিন', en: 'days' },
  solvedIn: { bn: 'সমাধান', en: 'Solved in' },
  markedByReporter: { bn: 'রিপোর্টকারী নিজে সমাধান চিহ্নিত করেছেন', en: 'Marked solved by the reporter' },
  markedByModerator: { bn: 'মডারেটর সমাধান নিশ্চিত করেছেন', en: 'Confirmed solved by a moderator' },
  markedByAuthority: { bn: 'কর্তৃপক্ষ সমাধান করেছে', en: 'Resolved by the authority' },
  peakDay: { bn: 'সর্বোচ্চ', en: 'Peak' },
  hotspots: { bn: 'হটস্পট ম্যাপ', en: 'Hotspot map' },
  hotspotsHint: { bn: 'রঙ যত লাল, সমস্যা তত বেশি। বৃত্তে ক্লিক করে ছবি দেখুন।', en: 'The redder the area, the more problems. Click a hotspot to see its photos.' },
  goodNews: { bn: 'সুখবর: সমাধান হয়েছে', en: 'Good news: fixed' },
  goodNewsHint: { bn: 'নাগরিকেরা কথা বলেছেন, পরিবর্তন এসেছে', en: 'Citizens spoke up — and things changed' },
  awareness: { bn: 'সচেতন হই, নিরাপদ দেশ গড়ি', en: 'Be aware, build a safer country' },
  awarenessHint: { bn: 'ছোট অভ্যাসই বড় পরিবর্তন আনে', en: 'Small habits make a big difference' },
  howTitle: { bn: 'কীভাবে কাজ করে', en: 'How it works' },
  step1Title: { bn: 'ছবি তুলুন', en: 'Snap it' },
  step1Body: { bn: 'অ্যাপ খুলে সমস্যার সরাসরি ছবি তুলুন — গ্যালারি নয়, তাই প্রতিটি ছবি সত্যিকারের প্রমাণ।', en: 'Open the app and take a live photo of the problem — no gallery uploads, so every photo is real proof.' },
  step2Title: { bn: 'রিপোর্ট করুন', en: 'Report it' },
  step2Body: { bn: 'ধরন বাছাই করুন, এক লাইনে লিখুন। স্থান নিজে থেকেই যুক্ত হয়। আপনার পরিচয় থাকে গোপন।', en: 'Pick the type and add a line. Location is added automatically. Your identity stays private.' },
  step3Title: { bn: 'পরিবর্তন দেখুন', en: 'See it fixed' },
  step3Body: { bn: 'এলাকার মানুষ সচেতন হন, অন্যরা নিশ্চিত করেন, আর দায়িত্বপ্রাপ্তরা ব্যবস্থা নেন।', en: 'Neighbours stay aware, others confirm it, and the people responsible take action.' },
  downloadTitle: { bn: 'অ্যাপ ডাউনলোড করুন', en: 'Download the app' },
  downloadHint: { bn: 'বিনামূল্যে। বাটনে চাপ দিলেই ফাইল ডাউনলোড শুরু হবে।', en: 'Free. Tap a button and the file downloads straight to your device.' },
  androidTitle: { bn: 'অ্যান্ড্রয়েড', en: 'Android' },
  androidBody: { bn: 'ডাউনলোড শেষে ফাইলটি খুলুন। জিজ্ঞেস করলে “অজানা উৎস থেকে ইনস্টল” অনুমতি দিন।', en: 'Open the file when it finishes. If asked, allow “Install unknown apps”.' },
  androidOther: { bn: 'ইনস্টল না হলে সব ফোনের সংস্করণ নিন', en: 'Won’t install? Get the version for all phones' },
  iosTitle: { bn: 'আইফোন', en: 'iPhone' },
  iosBody: {
    bn: 'অ্যাপ স্টোরে আসার আগ পর্যন্ত: ফাইলটি ডাউনলোড করে কম্পিউটারে Sideloadly বা AltStore দিয়ে নিজের Apple ID-তে সাইন করে ইনস্টল করুন।',
    en: 'Until we’re on the App Store: download the file, then install it with Sideloadly or AltStore on a computer, signed with your own Apple ID.',
  },
  downloadBtn: { bn: 'ডাউনলোড', en: 'Download' },
  forYourPhone: { bn: 'আপনার ফোনের জন্য', en: 'For your phone' },
  version: { bn: 'সংস্করণ', en: 'Version' },
  leaderboard: { bn: 'এই মাসের সজাগ নাগরিক', en: 'Most alert citizens this month' },
  leaderboardHint: { bn: 'সবাই ছদ্মনামে — পরিচয় সবসময় গোপন', en: 'Everyone appears by alias — identities stay private' },
  points: { bn: 'পয়েন্ট', en: 'XP' },
  reports: { bn: 'রিপোর্ট', en: 'reports' },
  viewAll: { bn: 'সব দেখুন', en: 'View all' },
  appPitchTitle: { bn: 'আপনার এলাকার চোখ হয়ে উঠুন', en: 'Be the eyes of your neighbourhood' },
  appPitchBody: { bn: 'সজাগ অ্যাপ বিনামূল্যে। বাংলা ও ইংরেজিতে। আপনার পরিচয় সম্পূর্ণ গোপন।', en: 'Sajag is free, in Bangla and English, and your identity stays completely private.' },
  confirmations: { bn: 'জন নিশ্চিত করেছেন', en: 'verified' },
  anonymous: { bn: 'বেনামি নাগরিক', en: 'Anonymous citizen' },
  reportedBy: { bn: 'পোস্ট করেছেন', en: 'Posted by' },
  location: { bn: 'স্থান', en: 'Location' },
  openInMaps: { bn: 'ম্যাপে দেখুন', en: 'Open in Maps' },
  share: { bn: 'শেয়ার', en: 'Share' },
  copied: { bn: 'লিংক কপি হয়েছে', en: 'Link copied' },
  status: { bn: 'অবস্থা', en: 'Status' },
  related: { bn: 'এই ধরনের আরও', en: 'More like this' },
  notFound: { bn: 'রিপোর্টটি পাওয়া যায়নি।', en: 'This report could not be found.' },
  backHome: { bn: 'প্রথম পাতায় ফিরুন', en: 'Back to the front page' },
  noReports: { bn: 'এই বিভাগে এখনো কোনো রিপোর্ট নেই।', en: 'No reports in this section yet.' },
  error: { bn: 'তথ্য আনা যায়নি। আবার চেষ্টা করুন।', en: "Couldn't load. Please try again." },
  retry: { bn: 'আবার চেষ্টা', en: 'Retry' },
  demo: { bn: 'ডেমো · নমুনা তথ্য ও ছবি', en: 'Demo · sample data & photos' },
  samplePhoto: { bn: 'নমুনা ছবি', en: 'Sample photo' },
  aboutTitle: { bn: 'সজাগ কী?', en: 'What is Sajag?' },
  aboutBody: {
    bn: 'সজাগ একটি নাগরিক উদ্যোগ। যে কেউ রাস্তার সমস্যার সরাসরি ছবি তুলে বেনামে রিপোর্ট করতে পারেন, যাতে এলাকার মানুষ সচেতন থাকে এবং দায়িত্বপ্রাপ্তরা ব্যবস্থা নিতে পারেন।',
    en: 'Sajag is a civic initiative. Anyone can report a street problem with a live photo, anonymously, so neighbours stay aware and the people responsible can act.',
  },
  privacyTitle: { bn: 'গোপনীয়তা', en: 'Privacy' },
  privacyBody: {
    bn: 'প্রত্যেক রিপোর্টকারী মোবাইল ও এনআইডি দিয়ে যাচাইকৃত, কিন্তু কারো পরিচয় কখনো প্রকাশ করা হয় না।',
    en: 'Every reporter is verified with mobile and NID, but no one’s identity is ever made public.',
  },
  admin: { bn: 'অ্যাডমিন', en: 'Admin' },
  rights: { bn: 'সজাগ — নাগরিকের চোখ, শহরের পাহারা', en: 'Sajag — citizens watching out for their city' },
  frontPage: { bn: 'প্রথম পাতা', en: 'Home' },
  allCategories: { bn: 'সব বিভাগ', en: 'All categories' },
  previous: { bn: 'আগের', en: 'Previous' },
  next: { bn: 'পরের', en: 'Next' },
  pause: { bn: 'থামান', en: 'Pause' },
  play: { bn: 'চালান', en: 'Play' },
  close: { bn: 'বন্ধ', en: 'Close' },
  few: { bn: 'কম', en: 'Few' },
  many: { bn: 'বেশি', en: 'Many' },
  photosHere: { bn: 'টি রিপোর্ট এখানে', en: ' reports here' },
  navAreas: { bn: 'আপনার এলাকা', en: 'Your area' },
  theme: { bn: 'থিম', en: 'Theme' },
  themeAuto: { bn: 'অটো (ডিভাইস অনুযায়ী)', en: 'Auto (device)' },
  themeLight: { bn: 'লাইট', en: 'Light' },
  themeDark: { bn: 'ডার্ক', en: 'Dark' },
  areasEyebrow: { bn: 'জেলা অনুযায়ী', en: 'District by district' },
  areasTitle: { bn: 'আপনার এলাকার সমস্যা খুঁজুন', en: 'Find problems in your area' },
  areasLede: { bn: 'বাংলাদেশের ৬৪ জেলার যেকোনোটি বেছে নিন — সেখানকার সব রিপোর্ট, কতগুলোর সমাধান হলো আর কোন এলাকায় নজর দরকার, সব এক জায়গায়।', en: 'Pick any of Bangladesh’s 64 districts to see every report there, how many got solved, and which neighbourhoods need attention.' },
  searchDistrict: { bn: 'জেলা বা বিভাগের নাম লিখুন…', en: 'Type a district or division…' },
  useMyLocation: { bn: 'আমার অবস্থান', en: 'Use my location' },
  locating: { bn: 'অবস্থান খোঁজা হচ্ছে…', en: 'Finding you…' },
  locationFailed: { bn: 'অবস্থান পাওয়া যায়নি। তালিকা থেকে জেলা বেছে নিন।', en: 'Couldn’t get your location. Pick your district from the list.' },
  allDivisions: { bn: 'সব বিভাগ', en: 'All divisions' },
  noReportsYetShort: { bn: 'এখনো রিপোর্ট নেই', en: 'No reports yet' },
  unsolvedWord: { bn: 'অমীমাংসিত', en: 'unsolved' },
  solvedWord: { bn: 'সমাধান', en: 'solved' },
  mostActive: { bn: 'সবচেয়ে বেশি রিপোর্ট', en: 'Most reported' },
  allDistricts: { bn: 'সব জেলা', en: 'All districts' },
  noDistrictMatch: { bn: 'এই নামে কোনো জেলা পাওয়া যায়নি।', en: 'No district matches that name.' },
  filterSearch: { bn: 'বিবরণ বা এলাকা দিয়ে খুঁজুন', en: 'Search descriptions or places' },
  filterCategory: { bn: 'সমস্যার ধরন', en: 'Problem type' },
  filterAllCategories: { bn: 'সব সমস্যা', en: 'All problems' },
  filterStatus: { bn: 'অবস্থা', en: 'Status' },
  statusAll: { bn: 'সব', en: 'All' },
  statusUnsolved: { bn: 'অমীমাংসিত', en: 'Unsolved' },
  statusInProgress: { bn: 'কাজ চলছে', en: 'In progress' },
  statusSolved: { bn: 'সমাধান হয়েছে', en: 'Solved' },
  filterTime: { bn: 'সময়', en: 'Time' },
  time7: { bn: 'গত ৭ দিন', en: 'Last 7 days' },
  time30: { bn: 'গত ৩০ দিন', en: 'Last 30 days' },
  time90: { bn: 'গত ৯০ দিন', en: 'Last 90 days' },
  timeAll: { bn: 'সব সময়', en: 'Any time' },
  filterArea: { bn: 'এলাকা', en: 'Area' },
  allAreas: { bn: 'সব এলাকা', en: 'All areas' },
  sortBy: { bn: 'সাজান', en: 'Sort' },
  sortRecent: { bn: 'সর্বশেষ', en: 'Newest' },
  sortConfirmed: { bn: 'সবচেয়ে বেশি নিশ্চিত', en: 'Most confirmed' },
  sortOldest: { bn: 'সবচেয়ে পুরোনো', en: 'Oldest first' },
  clearFilters: { bn: 'ফিল্টার মুছুন', en: 'Clear filters' },
  resultsSuffix: { bn: 'টি রিপোর্ট পাওয়া গেছে', en: ' reports found' },
  loadMore: { bn: 'আরও দেখুন', en: 'Load more' },
  noResults: { bn: 'এই ফিল্টারে কোনো রিপোর্ট নেই। ফিল্টার বদলে দেখুন।', en: 'No reports match these filters. Try widening them.' },
  solveRate: { bn: 'সমাধানের হার', en: 'Solved' },
  topProblems: { bn: 'প্রধান সমস্যা', en: 'Top problems' },
  hotAreas: { bn: 'যেসব এলাকায় বেশি', en: 'Where it’s worst' },
  changeDistrict: { bn: 'জেলা পরিবর্তন', en: 'Change district' },
  gatewayTitle: { bn: 'আপনার জেলায় কী ঘটছে?', en: 'What’s happening in your district?' },
  gatewayBody: { bn: 'ঢাকা থেকে পঞ্চগড়, কক্সবাজার থেকে সাতক্ষীরা — জেলা বেছে নিন, তারপর ফিল্টার দিয়ে খুঁজে নিন আপনার এলাকার প্রতিটি রিপোর্ট।', en: 'From Dhaka to Panchagarh, Cox’s Bazar to Satkhira — choose a district, then filter down to every report near you.' },
  exploreDistricts: { bn: 'সব জেলা দেখুন', en: 'Browse all districts' },
  filters: { bn: 'ফিল্টার', en: 'Filters' },
  divisionWord: { bn: 'বিভাগ', en: 'Division' },
  districtNotFound: { bn: 'জেলাটি পাওয়া যায়নি।', en: 'District not found.' },
  navTraffic: { bn: 'ট্রাফিক', en: 'Traffic' },
  trafficTeaserTitle: { bn: 'আইন ভাঙলে, রেকর্ডে থাকবে', en: 'Break traffic law, and it’s on record' },
  trafficTeaserHint: { bn: 'নাগরিকদের তোলা ছবিতে উল্টো পথ, সিগন্যাল অমান্য, ফুটপাতে বাইক। নম্বরপ্লেট শুধু ট্রাফিক বিভাগ দেখে, যাচাইয়ের পর তারাই ব্যবস্থা নেয়।', en: 'Wrong-way riding, red-light running, bikes on footpaths — captured by citizens. Number plates go only to the traffic division, which verifies and acts.' },
  trafficEyebrow: { bn: 'ট্রাফিক নজরদারি', en: 'Traffic watch' },
  trafficTitle: { bn: 'প্রতিটি আইন ভঙ্গ, রেকর্ডে', en: 'Every violation, on record' },
  trafficLede: { bn: 'এআই ক্যামেরা বসানোর পর সিগন্যাল মানা বেড়েছে, কারণ চালকেরা জানেন কেউ দেখছে। সজাগে প্রত্যেক নাগরিকই সেই ক্যামেরা: আইন ভাঙা যানবাহনের ছবি নম্বরপ্লেটসহ তুলুন, ট্রাফিক বিভাগ যাচাই করে ব্যবস্থা নেবে। ধরা পড়ার ভয়ই আইন ভাঙা কমানোর সবচেয়ে কার্যকর ওষুধ।', en: 'Signals started working once AI cameras went up, because drivers knew they were being watched. On Sajag every citizen is that camera: capture a vehicle breaking the law, plate included, and the traffic division verifies it and acts. Knowing you\'ll be caught is the best cure for breaking the rules.' },
  trafficStep1: { bn: 'ছবি তুলুন', en: 'Capture it' },
  trafficStep1Body: { bn: 'নিরাপদ দূরত্ব থেকে যানবাহন ও নম্বরপ্লেটের সরাসরি ছবি তুলুন, কোন আইন ভেঙেছে বেছে নিন।', en: 'Take a live photo of the vehicle and its plate from a safe distance, and pick the rule it broke.' },
  trafficStep2: { bn: 'যাচাই', en: 'Verified' },
  trafficStep2Body: { bn: 'ট্রাফিক বিভাগ ছবি, সময় ও অবস্থান যাচাই করে। অন্য নাগরিকেরাও দেখে থাকলে নিশ্চিত করতে পারেন।', en: 'The traffic division checks the photo, time and place. Other citizens who saw it can verify it too.' },
  trafficStep3: { bn: 'ব্যবস্থা', en: 'Action' },
  trafficStep3Body: { bn: 'সত্য প্রমাণিত হলে জরিমানা বা মামলা — আর রিপোর্টে লেখা থাকে ‘ব্যবস্থা নেওয়া হয়েছে’।', en: 'If it holds up: a fine or a case — and the report shows ‘Action taken’.' },
  statReported90: { bn: 'রিপোর্ট (৯০ দিন)', en: 'Reported (90 days)' },
  statVerifying: { bn: 'যাচাই চলছে', en: 'Under verification' },
  statActioned: { bn: 'ব্যবস্থা নেওয়া হয়েছে', en: 'Action taken' },
  topViolations: { bn: 'সবচেয়ে বেশি যে আইন ভাঙা হয়', en: 'Most common violations' },
  byVehicle: { bn: 'যানবাহন অনুযায়ী', en: 'By vehicle' },
  allVehicles: { bn: 'সব যানবাহন', en: 'All vehicles' },
  allViolations: { bn: 'সব আইন ভঙ্গ', en: 'All violations' },
  trafficDisclaimer: { bn: 'নাগরিকদের রিপোর্ট ট্রাফিক বিভাগ যাচাই না করা পর্যন্ত অভিযোগ মাত্র। চালকদের হয়রানি করবেন না — ব্যবস্থা নেওয়ার দায়িত্ব কর্তৃপক্ষের।', en: 'Citizen reports are claims until the traffic division verifies them. Don’t harass drivers — taking action is the authorities’ job.' },
  trafficDetails: { bn: 'আইন ভঙ্গের বিবরণ', en: 'Violation details' },
  vehicleLabel: { bn: 'যানবাহন', en: 'Vehicle' },
  rulesShort: { bn: 'কোনো ব্যক্তি, রাজনীতি বা ব্যক্তিগত স্বার্থ নিয়ে পোস্ট কখনো প্রকাশ হয় না; নিয়ম ভাঙলে অ্যাকাউন্ট নিষিদ্ধ।', en: 'Posts about people, politics or personal gain are never published; rule-breakers are banned.' },
  communityRules: { bn: 'কমিউনিটির নিয়ম', en: 'Community rules' },
  rulesLede: { bn: 'সজাগ মানুষকে জনসাধারণের বিপদ সম্পর্কে সতর্ক করার জন্য — কাউকে আক্রমণ, প্রচারণা বা ব্যক্তিগত লাভের জন্য নয়। প্রতিটি পোস্ট প্রকাশের আগে স্বয়ংক্রিয়ভাবে যাচাই হয়।', en: 'Sajag exists to warn people about public hazards — not to attack anyone, campaign or profit. Every post is screened automatically before it’s published.' },
  rule1: { bn: 'শুধু জনসাধারণের বিপদ ও ট্রাফিক আইন ভঙ্গের রিপোর্ট করুন।', en: 'Report only public hazards and traffic violations.' },
  rule2: { bn: 'কোনো ব্যক্তি, রাজনীতিবিদ, রাজনৈতিক দল বা তারকাকে নিয়ে পোস্ট নয় — নাম, অভিযোগ বা প্রচারণা নয়।', en: 'Never post about a person, politician, political party or celebrity — no names, accusations or campaigns.' },
  rule3: { bn: 'বিজ্ঞাপন, বেচাকেনা, ব্যক্তিগত বিরোধ, প্রতিশোধ বা ব্যক্তিগত স্বার্থে কিছু নয়।', en: 'No ads, sales, private disputes, revenge or anything for personal gain.' },
  rule4: { bn: 'ফোন নম্বর, লিংক বা সোশ্যাল মিডিয়া আইডি দেবেন না।', en: 'No phone numbers, links or social media handles.' },
  rule5: { bn: 'ছবি অবশ্যই সরাসরি তোলা ও সত্য হতে হবে। মানুষের মুখ নয়, সমস্যা বা যানবাহনের ছবি তুলুন।', en: 'Photos must be live and real. Capture the problem or the vehicle, not people’s faces.' },
  rule6: { bn: 'নিয়ম ভাঙা পোস্ট প্রকাশ করা হয় না এবং লেখককে সতর্ক করা হয়। ৩টি সতর্কতার পর অ্যাকাউন্ট নিষিদ্ধ।', en: 'Posts that break these rules are not published and the author is warned. After 3 warnings the account is banned.' },
  rulesHow: { bn: 'যেভাবে যাচাই হয়', en: 'How posts are checked' },
  rulesHowBody: { bn: 'প্রতিটি পোস্ট প্রকাশের আগে স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয়। কোনো ব্যক্তি, রাজনীতি, তারকা বা ব্যক্তিগত স্বার্থের ইঙ্গিত থাকলে পোস্টটি আটকে মডারেটরের কাছে যায়। নিয়ম ভাঙলে পোস্ট বাতিল হয় এবং লেখক একটি সতর্কতা পান।', en: 'Every post is checked automatically before it goes public. Anything that points to a person, politics, a celebrity or personal gain is held for a moderator. If it breaks the rules it is rejected and the author gets a warning.' },
  platePrivate: { bn: 'নম্বরপ্লেট ও অন্য যেকোনো ব্যক্তিগত তথ্য কখনো প্রকাশ্যে দেখানো হয় না — শুধু ট্রাফিক বিভাগ দেখতে পায়, যাতে সজাগের মাধ্যমে কাউকে নিশানা বা আক্রমণ করা না যায়।', en: 'Number plates and any other personal details are never shown publicly — only the traffic division can see them, so no one can be targeted or attacked through Sajag.' },
  rule7: { bn: 'ব্যক্তিগত তথ্য — নাম, মুখ, ফোন নম্বর ও নম্বরপ্লেট — কখনো প্রকাশ্যে দেখানো হয় না। নম্বরপ্লেট যায় শুধু ট্রাফিক বিভাগের কাছে।', en: 'Personal details — names, faces, phone numbers and number plates — are never shown publicly. Plates go only to the traffic division.' },
} satisfies Record<string, Record<Lang, string>>;

export type StringKey = keyof typeof strings;

interface LangValue {
  lang: Lang;
  setLang: (l: Lang) => void;
  t: (key: StringKey) => string;
}

const LangContext = createContext<LangValue | null>(null);

function initialLang(): Lang {
  try {
    const saved = localStorage.getItem('sajag.lang');
    if (saved === 'bn' || saved === 'en') return saved;
  } catch {
    // storage unavailable (private mode); fall through to the default
  }
  return 'bn';
}

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(initialLang);

  useEffect(() => {
    document.documentElement.lang = lang;
  }, [lang]);

  const value = useMemo<LangValue>(
    () => ({
      lang,
      setLang: (l) => {
        setLangState(l);
        try {
          localStorage.setItem('sajag.lang', l);
        } catch {
          // non-critical
        }
      },
      t: (key) => strings[key][lang],
    }),
    [lang],
  );
  return <LangContext.Provider value={value}>{children}</LangContext.Provider>;
}

export function useLang(): LangValue {
  const v = useContext(LangContext);
  if (!v) throw new Error('useLang outside LangProvider');
  return v;
}
