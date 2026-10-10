import { Apple, Download, Smartphone } from 'lucide-react';
import { useEffect, useState } from 'react';
import { config, digits } from '@sajag/shared';
import { SectionHead } from './components';
import { useLang } from './i18n';
import { Reveal } from './motion';

type Platform = 'android' | 'ios' | 'other';

function detectPlatform(): Platform {
  const ua = navigator.userAgent;
  if (/android/i.test(ua)) return 'android';
  if (/iphone|ipad|ipod/i.test(ua) || (/macintosh/i.test(ua) && navigator.maxTouchPoints > 1)) return 'ios';
  return 'other';
}

interface Release {
  version: string;
  sizes: Record<string, number>;
}

/** Latest version and file sizes from the public GitHub API (best effort; buttons work without it). */
function useLatestRelease(): Release | null {
  const [release, setRelease] = useState<Release | null>(null);
  useEffect(() => {
    const ctrl = new AbortController();
    fetch(config.downloads.latestApi, { signal: ctrl.signal })
      .then((r) => (r.ok ? r.json() : Promise.reject(new Error(String(r.status)))))
      .then((data: { tag_name: string; assets: { name: string; size: number }[] }) =>
        setRelease({
          version: data.tag_name.replace(/^v/, ''),
          sizes: Object.fromEntries(data.assets.map((a) => [a.name, a.size])),
        }),
      )
      .catch(() => {
        // Offline or rate-limited: the section simply omits version and size.
      });
    return () => ctrl.abort();
  }, []);
  return release;
}

/** Direct downloads: the links resolve to the newest release file, never to a web page. */
export default function DownloadSection() {
  const { lang, t } = useLang();
  const [platform] = useState(detectPlatform);
  const release = useLatestRelease();
  const size = (file: string) => {
    const bytes = release?.sizes[file];
    return bytes ? digits(`${Math.round(bytes / 1_048_576)} MB`, lang) : null;
  };
  const meta = (file: string) =>
    [release && `${t('version')} ${digits(release.version, lang)}`, size(file)].filter(Boolean).join(' · ');

  return (
    <section className="section" id="download">
      <Reveal>
        <SectionHead eyebrow={t('getApp')} title={t('downloadTitle')} hint={t('downloadHint')} />
      </Reveal>
      <div className="downloads">
        <Reveal className={`dl${platform === 'android' ? ' mine' : ''}`}>
          {platform === 'android' && <span className="chip good dl-badge">{t('forYourPhone')}</span>}
          <span className="dl-icon">
            <Smartphone size={28} />
          </span>
          <h3>{t('androidTitle')}</h3>
          <p>{t('androidBody')}</p>
          <a className="btn brand" href={config.downloads.android} download>
            <Download size={18} aria-hidden="true" /> {t('downloadBtn')} APK
          </a>
          <div className="dl-meta">{meta('sajag-android-arm64.apk')}</div>
          <a className="dl-alt" href={config.downloads.androidUniversal} download>
            {t('androidOther')}
            {size('sajag-android-universal.apk') && ` (${size('sajag-android-universal.apk')})`}
          </a>
        </Reveal>
        <Reveal className={`dl${platform === 'ios' ? ' mine' : ''}`} delay={120}>
          {platform === 'ios' && <span className="chip good dl-badge">{t('forYourPhone')}</span>}
          <span className="dl-icon">
            <Apple size={28} />
          </span>
          <h3>{t('iosTitle')}</h3>
          <p>{t('iosBody')}</p>
          <a className="btn" href={config.downloads.ios} download>
            <Download size={18} aria-hidden="true" /> {t('downloadBtn')} IPA
          </a>
          <div className="dl-meta">{meta('sajag-ios-unsigned.ipa')}</div>
        </Reveal>
      </div>
    </section>
  );
}
