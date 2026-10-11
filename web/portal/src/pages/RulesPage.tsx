import { Ban, Camera, Gavel, PhoneOff, ShieldCheck, TriangleAlert, UserX } from 'lucide-react';
import { useLang } from '../i18n';
import { Reveal } from '../motion';

/** Community rules: what can be posted, how posts are checked, and what happens to rule-breakers. */
export default function RulesPage() {
  const { t } = useLang();
  const rules = [
    [TriangleAlert, 'rule1', false],
    [UserX, 'rule2', true],
    [Ban, 'rule3', true],
    [PhoneOff, 'rule4', true],
    [Camera, 'rule5', false],
    [Gavel, 'rule6', true],
  ] as const;
  return (
    <main className="container rules-page">
      <section className="areas-hero">
        <Reveal>
          <span className="eyebrow">Sajag</span>
          <h1 className="display">{t('communityRules')}</h1>
          <p className="lede">{t('rulesLede')}</p>
        </Reveal>
      </section>
      <section className="rules-grid">
        {rules.map(([Icon, key, warn], i) => (
          <Reveal key={key} delay={(i % 3) * 80} className={`rule${warn ? ' warn' : ''}`}>
            <span className="ic">
              <Icon size={22} aria-hidden="true" />
            </span>
            <p>{t(key)}</p>
          </Reveal>
        ))}
      </section>
      <Reveal className="rules-how">
        <ShieldCheck size={28} aria-hidden="true" />
        <div>
          <h2>{t('rulesHow')}</h2>
          <p>{t('rulesHowBody')}</p>
        </div>
      </Reveal>
    </main>
  );
}
