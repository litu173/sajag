import { createContext, type ReactNode, useContext, useEffect, useMemo, useState } from 'react';
import type { Lang } from '@sajag/shared';

const strings = {
  tagline: { bn: 'দেখুন। ছবি তুলুন। সমাধান করুন।', en: 'See it. Snap it. Fix it.' },
  latest: { bn: 'সর্বশেষ', en: 'Latest' },
  allNews: { bn: 'সব খবর', en: 'All reports' },
  topStory: { bn: 'প্রধান খবর', en: 'Top story' },
  mostConfirmed: { bn: 'সবচেয়ে বেশি নিশ্চিত', en: 'Most confirmed' },
  justIn: { bn: 'এইমাত্র এসেছে', en: 'Just in' },
  confirmations: { bn: 'জন দেখেছেন', en: 'people saw this' },
  statTotal: { bn: 'মোট রিপোর্ট', en: 'Reports' },
  statResolved: { bn: 'সমাধান হয়েছে', en: 'Resolved' },
  statWeek: { bn: 'এই সপ্তাহে', en: 'This week' },
  statAreas: { bn: 'সক্রিয় এলাকা', en: 'Active areas' },
  hotspots: { bn: 'এলাকাভিত্তিক হটস্পট', en: 'Hotspots by area' },
  hotspotsHint: {
    bn: 'গত ৩০ দিনের রিপোর্ট। রঙ যত লাল, সমস্যা তত বেশি। বৃত্তে ক্লিক করে রিপোর্ট দেখুন।',
    en: 'Reports from the last 30 days. Redder means more problems. Click a hotspot to see its reports.',
  },
  topAreas: { bn: 'সবচেয়ে বেশি রিপোর্ট', en: 'Most reported areas' },
  goodNews: { bn: 'সুখবর: সমাধান হয়েছে', en: 'Good news: fixed' },
  goodNewsHint: { bn: 'নাগরিকদের রিপোর্টের পর যে সমস্যাগুলোর সমাধান হয়েছে', en: 'Problems solved after citizens reported them' },
  awareness: { bn: 'সচেতনতা', en: 'Awareness' },
  awarenessHint: { bn: 'আমাদের ছোট অভ্যাসই শহরকে বাঁচায়', en: 'Small habits that keep our city livable' },
  leaderboard: { bn: 'এই মাসের সজাগ নাগরিক', en: 'Most alert citizens this month' },
  leaderboardHint: { bn: 'সবাই ছদ্মনামে — পরিচয় সবসময় গোপন', en: 'Everyone appears by alias — identities stay private' },
  points: { bn: 'পয়েন্ট', en: 'XP' },
  reports: { bn: 'রিপোর্ট', en: 'reports' },
  moreIn: { bn: 'আরও দেখুন', en: 'More' },
  getApp: { bn: 'অ্যাপ ডাউনলোড', en: 'Get the app' },
  appPitchTitle: { bn: 'রাস্তায় সমস্যা দেখেছেন?', en: 'Seen a problem on your street?' },
  appPitchBody: {
    bn: 'সজাগ অ্যাপ দিয়ে সরাসরি ছবি তুলে রিপোর্ট করুন। আপনার পরিচয় থাকবে সম্পূর্ণ গোপন।',
    en: 'Snap a live photo and report it with the Sajag app. Your identity stays completely private.',
  },
  anonymous: { bn: 'বেনামি নাগরিক', en: 'Anonymous citizen' },
  reportedBy: { bn: 'রিপোর্ট করেছেন', en: 'Reported by' },
  location: { bn: 'স্থান', en: 'Location' },
  openInMaps: { bn: 'ম্যাপে দেখুন', en: 'Open in Maps' },
  share: { bn: 'শেয়ার', en: 'Share' },
  copied: { bn: 'লিংক কপি হয়েছে', en: 'Link copied' },
  status: { bn: 'অবস্থা', en: 'Status' },
  related: { bn: 'এই ধরনের আরও রিপোর্ট', en: 'More like this' },
  notFound: { bn: 'রিপোর্টটি পাওয়া যায়নি।', en: 'This report could not be found.' },
  backHome: { bn: 'প্রথম পাতায় ফিরুন', en: 'Back to front page' },
  noReports: { bn: 'এই বিভাগে এখনো কোনো রিপোর্ট নেই।', en: 'No reports in this section yet.' },
  loading: { bn: 'লোড হচ্ছে…', en: 'Loading…' },
  error: { bn: 'তথ্য আনা যায়নি। আবার চেষ্টা করুন।', en: "Couldn't load. Please try again." },
  retry: { bn: 'আবার চেষ্টা', en: 'Retry' },
  demo: { bn: 'ডেমো: নমুনা তথ্য দেখানো হচ্ছে', en: 'Demo: showing sample data' },
  aboutTitle: { bn: 'সজাগ কী?', en: 'What is Sajag?' },
  aboutBody: {
    bn: 'সজাগ একটি নাগরিক উদ্যোগ। যে কেউ রাস্তার সমস্যা — খোলা ম্যানহোল, ভাঙা রাস্তা, ময়লা, জলাবদ্ধতা — সরাসরি ছবি তুলে বেনামে রিপোর্ট করতে পারেন, যাতে এলাকার মানুষ সচেতন থাকে এবং দায়িত্বপ্রাপ্তরা ব্যবস্থা নিতে পারেন।',
    en: 'Sajag is a civic initiative. Anyone can report street problems — open manholes, broken roads, garbage, waterlogging — with a live photo, anonymously, so neighbours stay aware and the people responsible can act.',
  },
  privacyTitle: { bn: 'গোপনীয়তা', en: 'Privacy' },
  privacyBody: {
    bn: 'প্রত্যেক রিপোর্টকারী মোবাইল ও এনআইডি দিয়ে যাচাইকৃত, কিন্তু কারো পরিচয় কখনো প্রকাশ করা হয় না।',
    en: 'Every reporter is verified with mobile and NID, but no one’s identity is ever made public.',
  },
  admin: { bn: 'অ্যাডমিন', en: 'Admin' },
  rights: { bn: 'সজাগ — নাগরিকের চোখ, শহরের পাহারা', en: 'Sajag — citizens watching out for their city' },
  frontPage: { bn: 'প্রথম পাতা', en: 'Front page' },
  pause: { bn: 'থামান', en: 'Pause' },
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
