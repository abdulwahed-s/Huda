enum IslamicEventKind {
  ramadan('ramadan'),
  lastTenRamadan('last_ten_ramadan'),
  eidAlFitr('eid_al_fitr'),
  eidAlAdha('eid_al_adha'),
  dayOfArafah('day_of_arafah'),
  firstTenDhulHijjah('first_ten_dhul_hijjah'),
  ashura('ashura'),
  daysOfTashreeq('days_of_tashreeq'),
  whiteDaysFasting('white_days_fasting'),
  mondayThursdayFasting('monday_thursday_fasting'),
  whiteDaysMondayThursdayFasting(
    'white_days_monday_thursday_fasting',
  );

  const IslamicEventKind(this.key);

  final String key;

  static IslamicEventKind? tryParse(String key) => switch (key) {
        'ramadan' => IslamicEventKind.ramadan,
        'last_ten_ramadan' => IslamicEventKind.lastTenRamadan,
        'eid_al_fitr' => IslamicEventKind.eidAlFitr,
        'eid_al_adha' => IslamicEventKind.eidAlAdha,
        'day_of_arafah' => IslamicEventKind.dayOfArafah,
        'first_ten_dhul_hijjah' => IslamicEventKind.firstTenDhulHijjah,
        'ashura' => IslamicEventKind.ashura,
        'days_of_tashreeq' => IslamicEventKind.daysOfTashreeq,
        'white_days_fasting' => IslamicEventKind.whiteDaysFasting,
        'monday_thursday_fasting' => IslamicEventKind.mondayThursdayFasting,
        'white_days_monday_thursday_fasting' =>
          IslamicEventKind.whiteDaysMondayThursdayFasting,
        _ => null,
      };
}

enum EventVisualFamily {
  sacredSeason,
  celebration,
  pilgrimage,
  reflection,
  remembrance,
  voluntaryFasting,
  authoredFallback,
}

enum EventStructuralMotif {
  ramadanCrescentDates,
  lastTenPrayerMatTenNights,
  eidFitrZakatGrain,
  eidAdhaRamOffering,
  arafahMountainMarker,
  dhulHijjahTenDayCalendar,
  ashuraPartedSeaTenthDay,
  tashreeqThreeDayRemembrance,
  whiteDaysThreeFullMoons,
  mondayThursdayWeekCalendar,
  whiteDaysWeeklyConfluence,
  authoredCalendarCrescent,
}

enum EventStructuralRhythm {
  sacredUnfolding,
  nightConvergence,
  celebratoryOpening,
  devotionalInterweave,
  elevatedStillness,
  ascendingTenfold,
  reflectiveSymmetry,
  countedThreefold,
  lunarThreefold,
  weeklySevenBeat,
  lunarWeeklyConfluence,
  measuredFallback,
}

class EventVisualIdentity {
  const EventVisualIdentity._({
    required this.eventKey,
    required this.kind,
    required this.motif,
    required this.family,
    required this.rhythm,
    required this.structuralCount,
  });

  final String eventKey;
  final IslamicEventKind? kind;
  final EventStructuralMotif motif;
  final EventVisualFamily family;
  final EventStructuralRhythm rhythm;

  final int structuralCount;

  bool get isFallback => kind == null;

  static Iterable<EventVisualIdentity> get known => _known.values;

  static EventVisualIdentity resolve(String key) {
    final normalized = key.trim();
    return _known[normalized] ??
        EventVisualIdentity._(
          eventKey: normalized,
          kind: null,
          motif: EventStructuralMotif.authoredCalendarCrescent,
          family: EventVisualFamily.authoredFallback,
          rhythm: EventStructuralRhythm.measuredFallback,
          structuralCount: 4,
        );
  }

  static const Map<String, EventVisualIdentity> _known = {
    'ramadan': EventVisualIdentity._(
      eventKey: 'ramadan',
      kind: IslamicEventKind.ramadan,
      motif: EventStructuralMotif.ramadanCrescentDates,
      family: EventVisualFamily.sacredSeason,
      rhythm: EventStructuralRhythm.sacredUnfolding,
      structuralCount: 1,
    ),
    'last_ten_ramadan': EventVisualIdentity._(
      eventKey: 'last_ten_ramadan',
      kind: IslamicEventKind.lastTenRamadan,
      motif: EventStructuralMotif.lastTenPrayerMatTenNights,
      family: EventVisualFamily.sacredSeason,
      rhythm: EventStructuralRhythm.nightConvergence,
      structuralCount: 10,
    ),
    'eid_al_fitr': EventVisualIdentity._(
      eventKey: 'eid_al_fitr',
      kind: IslamicEventKind.eidAlFitr,
      motif: EventStructuralMotif.eidFitrZakatGrain,
      family: EventVisualFamily.celebration,
      rhythm: EventStructuralRhythm.celebratoryOpening,
      structuralCount: 2,
    ),
    'eid_al_adha': EventVisualIdentity._(
      eventKey: 'eid_al_adha',
      kind: IslamicEventKind.eidAlAdha,
      motif: EventStructuralMotif.eidAdhaRamOffering,
      family: EventVisualFamily.celebration,
      rhythm: EventStructuralRhythm.devotionalInterweave,
      structuralCount: 2,
    ),
    'day_of_arafah': EventVisualIdentity._(
      eventKey: 'day_of_arafah',
      kind: IslamicEventKind.dayOfArafah,
      motif: EventStructuralMotif.arafahMountainMarker,
      family: EventVisualFamily.pilgrimage,
      rhythm: EventStructuralRhythm.elevatedStillness,
      structuralCount: 1,
    ),
    'first_ten_dhul_hijjah': EventVisualIdentity._(
      eventKey: 'first_ten_dhul_hijjah',
      kind: IslamicEventKind.firstTenDhulHijjah,
      motif: EventStructuralMotif.dhulHijjahTenDayCalendar,
      family: EventVisualFamily.pilgrimage,
      rhythm: EventStructuralRhythm.ascendingTenfold,
      structuralCount: 10,
    ),
    'ashura': EventVisualIdentity._(
      eventKey: 'ashura',
      kind: IslamicEventKind.ashura,
      motif: EventStructuralMotif.ashuraPartedSeaTenthDay,
      family: EventVisualFamily.reflection,
      rhythm: EventStructuralRhythm.reflectiveSymmetry,
      structuralCount: 2,
    ),
    'days_of_tashreeq': EventVisualIdentity._(
      eventKey: 'days_of_tashreeq',
      kind: IslamicEventKind.daysOfTashreeq,
      motif: EventStructuralMotif.tashreeqThreeDayRemembrance,
      family: EventVisualFamily.remembrance,
      rhythm: EventStructuralRhythm.countedThreefold,
      structuralCount: 3,
    ),
    'white_days_fasting': EventVisualIdentity._(
      eventKey: 'white_days_fasting',
      kind: IslamicEventKind.whiteDaysFasting,
      motif: EventStructuralMotif.whiteDaysThreeFullMoons,
      family: EventVisualFamily.voluntaryFasting,
      rhythm: EventStructuralRhythm.lunarThreefold,
      structuralCount: 3,
    ),
    'monday_thursday_fasting': EventVisualIdentity._(
      eventKey: 'monday_thursday_fasting',
      kind: IslamicEventKind.mondayThursdayFasting,
      motif: EventStructuralMotif.mondayThursdayWeekCalendar,
      family: EventVisualFamily.voluntaryFasting,
      rhythm: EventStructuralRhythm.weeklySevenBeat,
      structuralCount: 2,
    ),
    'white_days_monday_thursday_fasting': EventVisualIdentity._(
      eventKey: 'white_days_monday_thursday_fasting',
      kind: IslamicEventKind.whiteDaysMondayThursdayFasting,
      motif: EventStructuralMotif.whiteDaysWeeklyConfluence,
      family: EventVisualFamily.voluntaryFasting,
      rhythm: EventStructuralRhythm.lunarWeeklyConfluence,
      structuralCount: 5,
    ),
  };
}
