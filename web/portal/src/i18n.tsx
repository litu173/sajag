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
  confirmations: { bn: 'জন দেখেছেন', en: 'saw this' },
  anonymous: { bn: 'বেনামি নাগরিক', en: 'Anonymous citizen' },
  reportedBy: { bn: 'রিপোর্ট করেছেন', en: 'Reported by' },
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
