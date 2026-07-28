import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/service_locator.dart';

final UmmAlQuraCalendar _fallbackHijriCalendar = UmmAlQuraCalendar();

UmmAlQuraCalendar get activeHijriCalendar {
  if (getIt.isRegistered<HijriCalendarService>()) {
    return getIt<HijriCalendarService>().calendar;
  }
  return _fallbackHijriCalendar;
}

HijriDate hijriDateFromDateTime(DateTime date) =>
    activeHijriCalendar.toHijriDateTime(date).date;
