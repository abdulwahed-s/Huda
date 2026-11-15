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
for (const [locale, labels] of Object.entries(LOCALES)) {
    const presentation = {locale, numerals: 'western'};
    assert(Format.elapsed(0, 0, presentation, labels) === Format.isolate(`+0${labels.minuteUnit}`), `${locale} exact start`);
    assert(Format.elapsed(0, 1499000, presentation, labels) === Format.isolate(`+24${labels.minuteUnit}`), `${locale} elapsed rounds down`);
    assert(Format.elapsed(0, 3660000, presentation, labels).includes(`+1${labels.hourUnit} 1${labels.minuteUnit}`), `${locale} elapsed hours`);
    const snapshot = {preferences: {}, current: {key: 'isha', utcMs: 0}, currentUntilUtcMs: 1500000,
        next: {key: 'fajr', utcMs: 20000000}, validUntilUtcMs: 2000000, presentation, timeZoneId: 'UTC'};
    assert(Format.indicator(snapshot, 0, labels).includes(labels.isha), `${locale} current name`);
    assert(Format.indicator(snapshot, 1499000, labels).includes('+24'), `${locale} current counter`);
    assert(Format.indicator(snapshot, 1500000, labels).includes(labels.fajr), `${locale} window expiry`);
    const clockSnapshot = {...snapshot, preferences: {style: 'iconNameClock'}};
    assert(Format.indicator(clockSnapshot, 0, labels).includes(labels.isha), `${locale} current clock name`);
    assert(Format.indicator(clockSnapshot, 0, labels).includes(Format.clock(0, 'UTC', presentation)), `${locale} current clock time`);
    assert(Format.indicator(clockSnapshot, 1500000, labels).includes(labels.fajr), `${locale} clock expiry`);
}
assert(Format.elapsed(0, 60000, {numerals: 'arabic'}, LOCALES.ar).includes('+١'), 'Arabic elapsed numerals');
assert(Format.elapsed(0, 60000, {numerals: 'easternArabic'}, LOCALES.ur).includes('+۱'), 'Urdu elapsed numerals');
assert(Format.digits('12:45', {numerals: 'arabic'}) === '١٢:٤٥', 'Arabic numerals');
assert(Format.digits('12:45', {numerals: 'easternArabic'}) === '۱۲:۴۵', 'Urdu numerals');
assert(Format.clock(null, 'UTC', {locale: 'en'}) === '\u2068--:--\u2069', 'missing time');
assert(Format.clock(Date.UTC(2026, 9, 11, 12, 30), 'UTC', {locale: 'en', use24HourClock: false}).includes('PM'), '12 hour clock');
print(`PASS: ${count} formatting assertions across 10 locales.`);
