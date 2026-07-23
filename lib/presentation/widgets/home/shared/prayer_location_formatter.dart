import 'package:flutter/material.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:locale_names/locale_names.dart';

String? prayerLocationLabel(
  BuildContext context,
  PrayerTimesLoaded state,
) {
  if (state.placemarks.isEmpty) return null;
  final placemark = state.placemarks.first;
  final locality = (placemark.locality ?? '').trim();
  final countryCode = (placemark.isoCountryCode ?? '').trim().toUpperCase();
  var country = (placemark.country ?? '').trim();

  if (countryCode.length == 2 &&
      (country.isEmpty || country.toUpperCase() == countryCode)) {
    final localized = Locale.fromSubtags(
      languageCode: 'und',
      countryCode: countryCode,
    ).displayCountryIn(Localizations.localeOf(context));
    if (localized.trim().isNotEmpty) country = localized.trim();
  }

  final parts = <String>[
    if (locality.isNotEmpty) locality,
    if (country.isNotEmpty && country != locality) country,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
