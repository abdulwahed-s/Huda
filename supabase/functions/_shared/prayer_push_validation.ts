export const allowedPrayerNames = [
  "fajr",
  "dhuhr",
  "asr",
  "maghrib",
  "isha",
] as const;

export type PrayerName = (typeof allowedPrayerNames)[number];
export type PrayerPushContent = Record<
  PrayerName,
  { title: string; body: string }
>;
export type CompactPrayerEvent = [number, number, PrayerName];

export interface PrayerPushRevisions {
  locationRevision: number;
  scheduleRevision: number;
  legacy: boolean;
}

export const maxSafeRevision = 9_007_199_254_740_991;

export function validatePrayerPushRevisions(
  locationValue: unknown,
  scheduleValue: unknown,
): PrayerPushRevisions {
  if (
    (locationValue === undefined && scheduleValue === undefined) ||
    (locationValue === 0 && scheduleValue === 0)
  ) {
    return { locationRevision: 0, scheduleRevision: 0, legacy: true };
  }
  if (
    !Number.isSafeInteger(locationValue) ||
    !Number.isSafeInteger(scheduleValue) ||
    (locationValue as number) <= 0 ||
    (scheduleValue as number) <= 0 ||
    (locationValue as number) > maxSafeRevision ||
    (scheduleValue as number) > maxSafeRevision
  ) {
    throw new PrayerPushInputError("invalid_revision");
  }
  return {
    locationRevision: locationValue as number,
    scheduleRevision: scheduleValue as number,
    legacy: false,
  };
}

export function isRemotelyOwned(
  eventEpoch: number,
  localCoverageUntil: Date | null,
): boolean {
  if (!Number.isSafeInteger(eventEpoch)) return false;
  if (localCoverageUntil === null) return true;
  return eventEpoch > Math.floor(localCoverageUntil.getTime() / 1000);
}

const allowedPrayers = new Set<string>(allowedPrayerNames);
const prayerIndexes: Record<PrayerName, number> = {
  fajr: 1,
  dhuhr: 2,
  asr: 3,
  maghrib: 4,
  isha: 5,
};

interface LocaleTemplate {
  prayerNames: Record<PrayerName, string>;
  title: string;
  body: string;
}

const templates: Record<string, LocaleTemplate> = {
  en: {
    prayerNames: {
      fajr: "Fajr",
      dhuhr: "Dhuhr",
      asr: "Asr",
      maghrib: "Maghrib",
      isha: "Isha",
    },
    title: "🕌 {prayerName} Prayer Time",
    body: "It's time for {prayerName} prayer. May Allah accept your prayers.",
  },
  ar: {
    prayerNames: {
      fajr: "الفجر",
      dhuhr: "الظهر",
      asr: "العصر",
      maghrib: "المغرب",
      isha: "العشاء",
    },
    title: "🕌 حان وقت صلاة {prayerName}",
    body: "حان وقت صلاة {prayerName}، تقبّل الله صلاتكم.",
  },
  bn: {
    prayerNames: {
      fajr: "ফজর",
      dhuhr: "জুহর",
      asr: "আসর",
      maghrib: "মাগরিব",
      isha: "ইশা",
    },
    title: "🕌 {prayerName} নামাজের সময়",
    body: "{prayerName} নামাজের সময় হয়েছে। আল্লাহ আপনার নামাজ কবুল করুন।",
  },
  de: {
    prayerNames: {
      fajr: "Fajr",
      dhuhr: "Dhuhr",
      asr: "Asr",
      maghrib: "Maghrib",
      isha: "Isha",
    },
    title: "🕌 Gebetszeit {prayerName}",
    body: "Es ist Zeit für das {prayerName}-Gebet. Möge Allah deine Gebete annehmen.",
  },
  es: {
    prayerNames: {
      fajr: "Fajr",
      dhuhr: "Dhuhr",
      asr: "Asr",
      maghrib: "Maghrib",
      isha: "Isha",
    },
    title: "🕌 Hora de oración {prayerName}",
    body: "Es hora de la oración {prayerName}. Que Allah acepte tus oraciones.",
  },
  fr: {
    prayerNames: {
      fajr: "Fajr",
      dhuhr: "Dhuhr",
      asr: "Asr",
      maghrib: "Maghrib",
      isha: "Isha",
    },
    title: "🕌 Heure de la prière {prayerName}",
    body: "Il est temps pour la prière {prayerName}. Qu'Allah accepte vos prières.",
  },
  ms: {
    prayerNames: {
      fajr: "Subuh",
      dhuhr: "Zohor",
      asr: "Asar",
      maghrib: "Maghrib",
      isha: "Isyak",
    },
    title: "🕌 Waktu Solat {prayerName}",
    body: "Masa untuk solat {prayerName}. Semoga Allah menerima solat anda.",
  },
  ru: {
    prayerNames: {
      fajr: "Фаджр",
      dhuhr: "Зухр",
      asr: "Аср",
      maghrib: "Магриб",
      isha: "Иша",
    },
    title: "🕌 Время намаза {prayerName}",
    body: "Время намаза {prayerName}. Да примет Аллах ваши молитвы.",
  },
  tr: {
    prayerNames: {
      fajr: "Sabah",
      dhuhr: "Öğle",
      asr: "İkindi",
      maghrib: "Akşam",
      isha: "Yatsı",
    },
    title: "🕌 {prayerName} Namaz Vakti",
    body: "{prayerName} namazının vakti geldi. Allah namazlarınızı kabul etsin.",
  },
  ur: {
    prayerNames: {
      fajr: "فجر",
      dhuhr: "ظہر",
      asr: "عصر",
      maghrib: "مغرب",
      isha: "عشاء",
    },
    title: "🕌 {prayerName} نماز کا وقت",
    body: "{prayerName} نماز کا وقت ہو گیا ہے۔ اللہ آپ کی نمازیں قبول فرمائے۔",
  },
};

export function canonicalPrayerContent(locale: string): PrayerPushContent {
  const normalizedLocale = normalizeLocale(locale);
  const template = templates[normalizedLocale] ?? templates.en;
  return Object.fromEntries(
    allowedPrayerNames.map((prayer) => {
      const prayerName = template.prayerNames[prayer];
      return [
        prayer,
        {
          title: interpolate(template.title, prayerName),
          body: interpolate(template.body, prayerName),
        },
      ];
    }),
  ) as PrayerPushContent;
}

export function canonicalizeLegacyPrayerContent(
  value: unknown,
): PrayerPushContent {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new PrayerPushInputError("invalid_content");
  }
  const entries = Object.entries(value);
  if (entries.length === 0) {
    throw new PrayerPushInputError("invalid_content");
  }
  for (const [prayer, raw] of entries) {
    if (!allowedPrayers.has(prayer) || !raw || typeof raw !== "object") {
      throw new PrayerPushInputError("invalid_content");
    }
  }

  for (const locale of Object.keys(templates)) {
    const canonical = canonicalPrayerContent(locale);
    const matches = entries.every(([prayer, raw]) => {
      const item = raw as Record<string, unknown>;
      const expected = canonical[prayer as PrayerName];
      return item.title === expected.title && item.body === expected.body;
    });
    if (matches) return canonical;
  }
  throw new PrayerPushInputError("invalid_content");
}

export function validatePrayerEvents(
  value: unknown,
  nowEpoch = Math.floor(Date.now() / 1000),
): CompactPrayerEvent[] {
  if (!Array.isArray(value) || value.length > 1900) {
    throw new PrayerPushInputError("invalid_events");
  }

  const earliest = nowEpoch - 24 * 60 * 60;
  const latest = nowEpoch + 380 * 24 * 60 * 60;
  const seenIds = new Set<number>();
  const eventsPerDate = new Map<number, number>();
  let previousEpoch = 0;
  const result: CompactPrayerEvent[] = [];
  for (const raw of value) {
    if (!Array.isArray(raw) || raw.length !== 3) {
      throw new PrayerPushInputError("invalid_events");
    }
    const [epoch, notificationId, prayer] = raw;
    if (
      !Number.isSafeInteger(epoch) ||
      epoch < earliest ||
      epoch > latest ||
      epoch <= previousEpoch ||
      !Number.isSafeInteger(notificationId) ||
      typeof prayer !== "string" ||
      !allowedPrayers.has(prayer)
    ) {
      throw new PrayerPushInputError("invalid_events");
    }

    const encodedDate = validateNotificationId(
      notificationId,
      prayer as PrayerName,
    );
    if (seenIds.has(notificationId)) {
      throw new PrayerPushInputError("invalid_events");
    }
    seenIds.add(notificationId);
    const dailyCount = (eventsPerDate.get(encodedDate) ?? 0) + 1;
    if (dailyCount > allowedPrayerNames.length) {
      throw new PrayerPushInputError("invalid_events");
    }
    eventsPerDate.set(encodedDate, dailyCount);

    previousEpoch = epoch;
    result.push([epoch, notificationId, prayer as PrayerName]);
  }
  return result;
}

export function normalizeLocale(value: string): string {
  const language = value.trim().toLowerCase().split(/[-_]/, 1)[0];
  return Object.hasOwn(templates, language) ? language : "en";
}

function validateNotificationId(
  notificationId: number,
  prayer: PrayerName,
): number {
  const modernIdStart = 300000000;
  const modernIdEnd = 400000000;
  if (notificationId < modernIdStart || notificationId >= modernIdEnd) {
    throw new PrayerPushInputError("invalid_events");
  }
  const encoded = notificationId - modernIdStart;
  if (encoded % 10 !== prayerIndexes[prayer]) {
    throw new PrayerPushInputError("invalid_events");
  }

  const encodedDate = Math.floor(encoded / 10) + 20000000;
  const year = Math.floor(encodedDate / 10000);
  const month = Math.floor((encodedDate % 10000) / 100);
  const day = encodedDate % 100;
  const date = new Date(Date.UTC(year, month - 1, day));
  if (
    year < 2000 ||
    year > 9999 ||
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    throw new PrayerPushInputError("invalid_events");
  }
  return encodedDate;
}

function interpolate(template: string, prayerName: string): string {
  return template.replaceAll("{prayerName}", prayerName);
}

export class PrayerPushInputError extends Error {
  readonly code: string;

  constructor(code: string) {
    super(code);
    this.code = code;
    this.name = "PrayerPushInputError";
  }
}
