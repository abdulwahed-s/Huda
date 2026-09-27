import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/l10n/app_localizations.dart';

final UmmAlQuraCalendar _fallbackHijriCalendar = UmmAlQuraCalendar();

UmmAlQuraCalendar get activeHijriCalendar {
  if (getIt.isRegistered<HijriCalendarService>()) {
    return getIt<HijriCalendarService>().calendar;
  }
  return _fallbackHijriCalendar;
}

HijriDate hijriDateFromDateTime(DateTime date) =>
    activeHijriCalendar.toHijriDateTime(date).date;

String hijriMonthName(AppLocalizations l10n, int month) => [
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
