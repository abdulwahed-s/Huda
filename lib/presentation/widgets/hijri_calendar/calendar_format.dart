import 'package:flutter/material.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// Dates in the app's language: Hijri month names from the ARB files,
/// Gregorian dates, weekdays and numerals from the locale.
class CalendarFormat {
  CalendarFormat.of(BuildContext context)
    : l10n = AppLocalizations.of(context)!,
      _locale = Localizations.localeOf(context).toLanguageTag(),
      _material = MaterialLocalizations.of(context),
      _always24 = MediaQuery.alwaysUse24HourFormatOf(context);

  final AppLocalizations l10n;
  final String _locale;
  final MaterialLocalizations _material;
  final bool _always24;

  /// Days and years: the locale's digits, never grouped ("1448").
  String number(int value) => (intl.NumberFormat.decimalPattern(
    _locale,
  )..turnOffGrouping()).format(value);

  String hijriMonth(int month) => [
    l10n.muharram,
    l10n.safar,
    l10n.rabiAlAwwal,
    l10n.rabiAlThani,
    l10n.jumadaAlAwwal,
    l10n.jumadaAlThani,
    l10n.rajab,
    l10n.shaban,
    l10n.ramadan,
    l10n.shawwal,
    l10n.dhuAlQidah,
    l10n.dhuAlHijjah,
  ][month - 1];

  /// "Jumada al-Awwal 1448".
  String hijriMonthYear(HijriDate date) =>
      '${hijriMonth(date.month)} ${number(date.year)}';

  /// "27 Jumada al-Awwal 1448".
  String hijriDate(HijriDate date) =>
      '${number(date.day)} ${hijriMonthYear(date)}';

  /// "7 November 2026" in the locale's order.
  String gregorianDate(DateTime date) =>
      intl.DateFormat.yMMMMd(_locale).format(date);

  /// "Saturday".
  String weekday(DateTime date) => intl.DateFormat.EEEE(_locale).format(date);

  /// "Sat".
  String weekdayShort(DateTime date) => intl.DateFormat.E(_locale).format(date);

  /// "18 Feb".
  String dayMonthShort(DateTime date) =>
      intl.DateFormat.MMMd(_locale).format(date);

  /// "November 2026", or "November – December 2026" for a Hijri month
  /// that spans two.
  String gregorianSpan(DateTime first, DateTime last) {
    final month = intl.DateFormat.MMMM(_locale);
    final year = intl.DateFormat.y(_locale);
    if (first.month == last.month && first.year == last.year) {
      return intl.DateFormat.yMMMM(_locale).format(first);
    }
    if (first.year == last.year) {
      return '${month.format(first)} – ${month.format(last)} '
          '${year.format(last)}';
    }
    return '${intl.DateFormat.yMMM(_locale).format(first)} – '
        '${intl.DateFormat.yMMM(_locale).format(last)}';
  }

  /// A time in the locale's 12 or 24 h form.
  String time(TimeOfDay time) =>
      _material.formatTimeOfDay(time, alwaysUse24HourFormat: _always24);

  String timeOf(DateTime date) => time(TimeOfDay.fromDateTime(date));

  /// The first weekday of the locale's week (0 = Sunday).
  int get firstDayOfWeek => _material.firstDayOfWeekIndex;
}
