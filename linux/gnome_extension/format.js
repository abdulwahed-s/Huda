export const PRAYERS = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
export const isolate = value => `\u2068${value}\u2069`;

export function digits(value, presentation) {
    const alphabet = presentation?.numerals === 'arabic' ? '٠١٢٣٤٥٦٧٨٩'
        : presentation?.numerals === 'easternArabic' ? '۰۱۲۳۴۵۶۷۸۹' : '0123456789';
    return String(value).replace(/[0-9]/g, digit => alphabet[Number(digit)]);
}

export function countdown(utcMs, now, presentation, labels) {
    const minutes = Math.max(0, Math.ceil((utcMs - now) / 60000));
    const hours = Math.floor(minutes / 60);
    return isolate(digits(`${hours ? `${hours}${labels.hourUnit} ` : ''}${minutes % 60}${labels.minuteUnit}`, presentation));
}

export function elapsed(utcMs, now, presentation, labels) {
    const minutes = Math.max(0, Math.floor((now - utcMs) / 60000));
    const hours = Math.floor(minutes / 60);
    return isolate(digits(`+${hours ? `${hours}${labels.hourUnit} ` : ''}${minutes % 60}${labels.minuteUnit}`, presentation));
}

export function moment(snapshot, now) {
    return snapshot?.current && now < snapshot.currentUntilUtcMs ? snapshot.current : snapshot?.next;
}

export function clock(utcMs, zone, presentation) {
    if (!Number.isFinite(utcMs) || !zone) return isolate('--:--');
    const value = new Intl.DateTimeFormat(`${presentation.locale}-u-nu-latn`, {
        timeZone: zone, hour: '2-digit', minute: '2-digit', hour12: !presentation.use24HourClock,
    }).format(new Date(utcMs));
    return isolate(digits(value, presentation));
}

export function date(now, zone, presentation) {
    return digits(new Intl.DateTimeFormat(`${presentation.locale}-u-nu-latn`, {
        timeZone: zone ?? 'UTC', dateStyle: 'full',
    }).format(new Date(now)), presentation);
}

export function indicator(snapshot, now, labels) {
    const style = snapshot?.preferences?.style ?? 'iconNameCountdown';
    if (style === 'iconOnly') return '';
    const prayer = moment(snapshot, now);
    if (!prayer || snapshot.validUntilUtcMs <= now) return labels.prayerTimes;
    const name = labels[prayer.key];
    const current = prayer === snapshot.current;
    const value = style === 'iconNameClock'
        ? clock(prayer.utcMs, snapshot.timeZoneId, snapshot.presentation)
        : current ? elapsed(prayer.utcMs, now, snapshot.presentation, labels)
            : countdown(prayer.utcMs, now, snapshot.presentation, labels);
    return (current || style === 'iconNameClock' ? labels.nameElapsed : labels.nameCountdown).replace('{prayer}', name).replace('{time}', value);
}

export function validateSnapshot(snapshot) {
    return snapshot?.schemaVersion === 1 && Number.isSafeInteger(snapshot.appliedRevision) &&
        ['ready', 'needsSetup', 'disabled', 'stopped', 'calculationUnavailable'].includes(snapshot.state) &&
        Number.isFinite(snapshot.generatedAtUtcMs) && Number.isFinite(snapshot.validUntilUtcMs) &&
        Array.isArray(snapshot.rows) && snapshot.rows.length === 6 &&
        PRAYERS.every((key, index) => snapshot.rows[index]?.key === key);
}
