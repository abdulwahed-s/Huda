import * as Format from '../format.js';
import {LOCALES} from '../locale/labels.js';

let count = 0;
function assert(value, message) { if (!value) throw new Error(message); count++; }
for (const locale of Object.keys(LOCALES)) {
    const presentation = {locale, use24HourClock: true, numerals: 'western'};
    const clock = Format.clock(Date.UTC(2026, 9, 11, 12, 30), 'Asia/Kathmandu', presentation);
    assert(clock.includes('18:15'), `${locale} fractional time zone`);
    assert(Format.countdown(3660000, 0, presentation, LOCALES[locale]).includes(LOCALES[locale].hourUnit), `${locale} countdown units`);
    assert(Format.date(Date.UTC(2026, 9, 11), 'Asia/Muscat', presentation).length > 8, `${locale} date`);
    const snapshot = {preferences: {style: 'iconNameCountdown'}, next: {key: 'fajr', utcMs: 3660000},
        validUntilUtcMs: 4000000, presentation, timeZoneId: 'Asia/Muscat'};
    assert(!Format.indicator(snapshot, 0, LOCALES[locale]).includes('{'), `${locale} placeholders`);
    assert(Format.indicator({...snapshot, preferences: {style: 'iconOnly'}}, 0, LOCALES[locale]) === '', 'icon only');
    assert(Format.indicator(snapshot, 4000001, LOCALES[locale]) === LOCALES[locale].prayerTimes, 'stale snapshot');
}
assert(Format.digits('12:45', {numerals: 'arabic'}) === '١٢:٤٥', 'Arabic numerals');
assert(Format.digits('12:45', {numerals: 'easternArabic'}) === '۱۲:۴۵', 'Urdu numerals');
assert(Format.clock(null, 'UTC', {locale: 'en'}) === '\u2068--:--\u2069', 'missing time');
assert(Format.clock(Date.UTC(2026, 9, 11, 12, 30), 'UTC', {locale: 'en', use24HourClock: false}).includes('PM'), '12 hour clock');
print(`PASS: ${count} formatting assertions across 10 locales.`);
