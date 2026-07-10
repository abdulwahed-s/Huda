# ``PrayerTimePlus``

Compute Islamic prayer times numerically, with no third-party dependencies.

## Overview

`PrayerTimePlus` computes the daily prayer times — Fajr, Sunrise, Dhuhr, Asr,
Maghrib and Isha — for any location and date using a classic solar model. The API
mirrors the ergonomics of the Adhan Swift library, while the angles, offsets and
"Auto" method resolution match a specific reference engine to the minute.

```swift
var parameters = CalculationMethod.oman.parameters
parameters.madhab = .shafi

let times = PrayerTimes(
    coordinates: Coordinates(latitude: 24.3486, longitude: 56.6953, altitude: 5),
    date: DateComponents(year: 2026, month: 6, day: 28),
    calculationParameters: parameters,
    utcOffset: 4 * 3600,
    countryCode: "OM",
    cityName: "sohar"
)

let formatter = DateFormatter()
formatter.dateFormat = "HH:mm"
formatter.timeZone = TimeZone(secondsFromGMT: 4 * 3600)
times.maghrib.map { formatter.string(from: $0) }   // "19:10"
```

Each time is a true UTC `Date` (or `nil` when the sun never reaches the required
angle). Format it with a `DateFormatter` whose `timeZone` you set.

## Topics

### Inputs

- ``Coordinates``
- ``CalculationMethod``
- ``CalculationParameters``
- ``PrayerAdjustments``
- ``Madhab``
- ``HighLatitudeRule``

### Computing times

- ``PrayerTimes``
- ``Prayer``
- ``SunnahTimes``

### Auto resolution

- ``AutoMethod``
