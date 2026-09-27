import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_calendar_data.dart';
import 'package:huda/core/services/prayer_country_names.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_method_label.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';
import 'package:intl/intl.dart';
import 'package:pdf_document/pdf_document.dart';

enum PrayerCalendarPeriod { day, month, year }

class PrayerCalendarExport {
  const PrayerCalendarExport(
    this.bytes,
    this.fileName,
    this.mimeType,
    this.title,
  );
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String title;
}

class PrayerCalendarExporter {
  static const _a4Width = 595.28;
  static const _rowsPerPage = 17;

  static Future<PrayerCalendarExport> generate({
    required BuildContext context,
    required PrayerCalendarData data,
    required PrayerCalendarPeriod period,
    required DateTime selectedDate,
    required void Function(int current, int total) onProgress,
    required bool Function() isCancelled,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final palette = ShareImagePalette.of(context);
    final location = locationLabel(data, l10n, locale);
    final title = switch (period) {
      PrayerCalendarPeriod.day => DateFormat.yMMMMEEEEd(
        locale,
      ).format(selectedDate),
      PrayerCalendarPeriod.month => DateFormat.yMMMM(
        locale,
      ).format(selectedDate),
      PrayerCalendarPeriod.year => DateFormat.y(locale).format(selectedDate),
    };
    final slug = _safeFilePart(location);
    final dateSlug = switch (period) {
      PrayerCalendarPeriod.day => DateFormat('yyyy-MM-dd').format(selectedDate),
      PrayerCalendarPeriod.month => DateFormat('yyyy-MM').format(selectedDate),
      PrayerCalendarPeriod.year => DateFormat('yyyy').format(selectedDate),
    };
    final baseName = 'huda_prayer_times_${dateSlug}_$slug';
    if (period == PrayerCalendarPeriod.day) {
      onProgress(1, 1);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      _checkCancelled(isCancelled);
      if (!context.mounted) throw const PrayerCalendarCancelled();
      final bytes = await ShareImageCapture.capturePng(
        context: context,
        card: _PrayerDayCard(
          data: data,
          date: selectedDate,
          palette: palette,
          locale: locale,
          l10n: l10n,
          location: location,
        ),
      );
      _checkCancelled(isCancelled);
      return PrayerCalendarExport(bytes, '$baseName.png', 'image/png', title);
    }

    final months = period == PrayerCalendarPeriod.month
        ? [selectedDate.month]
        : List.generate(12, (index) => index + 1);
    final pages = <({int month, List<DateTime> dates})>[];
    for (final month in months) {
      final dates = PrayerCalendarData.monthDates(selectedDate.year, month);
      for (var start = 0; start < dates.length; start += _rowsPerPage) {
        pages.add((
          month: month,
          dates: dates.skip(start).take(_rowsPerPage).toList(growable: false),
        ));
      }
    }
    final total = pages.length + 1;
    final pageImages = <Uint8List>[];
    for (var index = 0; index < total; index++) {
      _checkCancelled(isCancelled);
      onProgress(index + 1, total);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      _checkCancelled(isCancelled);
      if (!context.mounted) throw const PrayerCalendarCancelled();
      final page = index == 0
          ? _PrayerPdfCover(
              data: data,
              palette: palette,
              l10n: l10n,
              locale: locale,
              location: location,
              title: title,
              generatedAt: data.localToday(DateTime.now()),
            )
          : _PrayerPdfTablePage(
              data: data,
              palette: palette,
              l10n: l10n,
              locale: locale,
              location: location,
              year: selectedDate.year,
              month: pages[index - 1].month,
              dates: pages[index - 1].dates,
              page: index + 1,
              total: total,
            );
      pageImages.add(
        await ShareImageCapture.capturePng(
          context: context,
          card: page,
          width: _a4Width,
          pixelRatio: 2.25,
        ),
      );
    }
    _checkCancelled(isCancelled);
    final pdf = PdfImageDocument.fromImageBytes(
      pageImages,
      pageSize: PdfPageSize.a4,
      fit: PdfImageFit.fill,
    );
    _checkCancelled(isCancelled);
    return PrayerCalendarExport(pdf, '$baseName.pdf', 'application/pdf', title);
  }

  static void _checkCancelled(bool Function() cancelled) {
    if (cancelled()) throw const PrayerCalendarCancelled();
  }

  static String locationLabel(
    PrayerCalendarData data,
    AppLocalizations l10n,
    String locale,
  ) {
    final country =
        PrayerCountryNames.localized(data.countryCode, locale) ??
        data.countryName;
    final parts = [
      data.locality?.trim(),
      country?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).toSet().toList();
    return parts.isEmpty ? l10n.unknown : parts.join(', ');
  }

  static String _safeFilePart(String value) {
    final safe = value
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return safe.isEmpty
        ? 'location'
        : safe.substring(0, safe.length.clamp(0, 48));
  }
}

class PrayerCalendarCancelled implements Exception {
  const PrayerCalendarCancelled();
}

bool _rtl(String locale) => locale.startsWith('ar') || locale.startsWith('ur');

TextStyle _style(
  String locale,
  double size,
  Color color, {
  bool bold = false,
}) => TextStyle(
  fontFamily: _rtl(locale) ? 'Amiri' : null,
  fontSize: size,
  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
  color: color,
  height: _rtl(locale) ? 1.35 : 1.2,
);

const _keys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

List<String> _labels(AppLocalizations l10n) => [
  l10n.fajr,
  l10n.sunrise,
  l10n.dhuhr,
  l10n.asr,
  l10n.maghrib,
  l10n.isha,
];

String _formattedTime(DateTime? adjusted, DateFormat formatter) =>
    adjusted == null ? '--:--' : formatter.format(adjusted);

class _PrayerDayCard extends StatelessWidget {
  const _PrayerDayCard({
    required this.data,
    required this.date,
    required this.palette,
    required this.locale,
    required this.l10n,
    required this.location,
  });
  final PrayerCalendarData data;
  final DateTime date;
  final ShareImagePalette palette;
  final String locale;
  final AppLocalizations l10n;
  final String location;

  @override
  Widget build(BuildContext context) {
    final times = data.calculate(date);
    final labels = _labels(l10n);
    return BrandedShareFrame(
      palette: palette,
      sectionLabel: l10n.prayerTimes,
      sectionIcon: Icons.calendar_month_rounded,
      title: DateFormat.yMMMMd(locale).format(date),
      subtitle: DateFormat.EEEE(locale).format(date),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            location,
            textAlign: TextAlign.center,
            style: _style(locale, 17, palette.ink, bold: true),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _keys.length; index++) ...[
            if (index > 0)
              Divider(
                color: palette.inkMuted.withValues(alpha: .18),
                height: 1,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labels[index],
                      style: _style(locale, 16, palette.ink),
                    ),
                  ),
                  Text(
                    data.adjusted(times, _keys[index]) == null
                        ? '--:--'
                        : DateFormat.jm(
                            locale,
                          ).format(data.adjusted(times, _keys[index])!),
                    style: _style(locale, 16, palette.accentInk, bold: true),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _Metadata(
            data: data,
            l10n: l10n,
            locale: locale,
            palette: palette,
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({
    required this.data,
    required this.l10n,
    required this.locale,
    required this.palette,
    this.compact = false,
  });
  final PrayerCalendarData data;
  final AppLocalizations l10n;
  final String locale;
  final ShareImagePalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final entries = [
      (
        l10n.prayerCalculationMethod,
        prayerCalendarMethodLabel(l10n, data.resolvedMethod.name),
      ),
      (
        l10n.prayerAsrMethod,
        data.madhabToken == 'hanafi'
            ? l10n.prayerMadhabHanafi
            : l10n.prayerMadhabShafi,
      ),
      (l10n.prayerCalendarTimeZone, data.timeZoneId),
    ];
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    '${entry.$1}: ${entry.$2}',
                    style: _style(locale, 11.5, palette.inkMuted),
                  ),
                ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in entries)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.$1,
                          style: _style(locale, 10, palette.inkMuted),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          entry.$2,
                          style: _style(locale, 12, palette.ink, bold: true),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
  }
}

class _PdfCanvas extends StatelessWidget {
  const _PdfCanvas({required this.child, required this.palette});
  final Widget child;
  final ShareImagePalette palette;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: SizedBox(width: 595.28, height: 841.89, child: child),
  );
}

class _PrayerPdfCover extends StatelessWidget {
  const _PrayerPdfCover({
    required this.data,
    required this.palette,
    required this.l10n,
    required this.locale,
    required this.location,
    required this.title,
    required this.generatedAt,
  });
  final PrayerCalendarData data;
  final ShareImagePalette palette;
  final AppLocalizations l10n;
  final String locale;
  final String location;
  final String title;
  final DateTime generatedAt;

  @override
  Widget build(BuildContext context) => _PdfCanvas(
    palette: palette,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(46, 55, 46, 40),
      child: Column(
        children: [
          Image.asset(
            BrandedShareFrame.logoAsset,
            width: 76,
            height: 76,
            color: palette.accentInk,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appTitle,
            style: _style(locale, 18, palette.accentInk, bold: true),
          ),
          const SizedBox(height: 98),
          Container(width: 74, height: 4, color: palette.accentInk),
          const SizedBox(height: 54),
          Text(
            title,
            textAlign: TextAlign.center,
            style: _style(locale, 42, palette.accentInk, bold: true),
          ),
          const SizedBox(height: 13),
          Text(
            l10n.prayerCalendarTitle,
            textAlign: TextAlign.center,
            style: _style(locale, 22, palette.inkMuted),
          ),
          const SizedBox(height: 53),
          Text(
            location,
            textAlign: TextAlign.center,
            style: _style(locale, 17, palette.ink),
          ),
          const Spacer(),
          Divider(color: palette.inkMuted.withValues(alpha: .3)),
          const SizedBox(height: 16),
          _Metadata(data: data, l10n: l10n, locale: locale, palette: palette),
          const SizedBox(height: 16),
          Divider(color: palette.inkMuted.withValues(alpha: .3)),
          const SizedBox(height: 52),
          Text(
            l10n.appTitle,
            style: _style(locale, 17, palette.accentInk, bold: true),
          ),
          Text(
            l10n.shareImageTagline,
            style: _style(locale, 11, palette.inkMuted),
          ),
          const SizedBox(height: 9),
          Text(
            l10n.prayerCalendarGenerated(
              DateFormat.yMMMd(locale).format(generatedAt),
            ),
            style: _style(locale, 10, palette.inkMuted),
          ),
        ],
      ),
    ),
  );
}

class _PrayerPdfTablePage extends StatelessWidget {
  const _PrayerPdfTablePage({
    required this.data,
    required this.palette,
    required this.l10n,
    required this.locale,
    required this.location,
    required this.year,
    required this.month,
    required this.dates,
    required this.page,
    required this.total,
  });
  final PrayerCalendarData data;
  final ShareImagePalette palette;
  final AppLocalizations l10n;
  final String locale;
  final String location;
  final int year;
  final int month;
  final List<DateTime> dates;
  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final labels = [
      l10n.prayerCalendarDate,
      l10n.prayerCalendarDay,
      l10n.fajr,
      l10n.prayerCalendarSunriseColumn,
      l10n.dhuhr,
      l10n.asr,
      l10n.maghrib,
      l10n.isha,
    ];
    final timeFormat = DateFormat.jm(locale);
    final rows = dates
        .map((date) {
          final times = data.calculate(date);
          return <String>[
            DateFormat.d(locale).format(date),
            DateFormat.E(locale).format(date),
            for (final key in _keys)
              _formattedTime(data.adjusted(times, key), timeFormat),
          ];
        })
        .toList(growable: false);
    return _PdfCanvas(
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(29, 32, 29, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset(
                  BrandedShareFrame.logoAsset,
                  width: 27,
                  height: 27,
                  color: palette.accentInk,
                ),
                const SizedBox(width: 9),
                Text(
                  l10n.appTitle,
                  style: _style(locale, 15, palette.accentInk, bold: true),
                ),
                const Spacer(),
                Text(
                  l10n.prayerCalendarTitle,
                  style: _style(locale, 10, palette.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              DateFormat.yMMMM(locale).format(DateTime(year, month)),
              style: _style(locale, 25, palette.accentInk, bold: true),
            ),
            const SizedBox(height: 3),
            Text(
              location,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _style(locale, 12, palette.inkMuted),
            ),
            const SizedBox(height: 22),
            Container(
              height: 44,
              color: palette.accentInk,
              child: _TableRowContent(
                cells: labels,
                locale: locale,
                color: Colors.white,
                bold: true,
                header: true,
              ),
            ),
            for (var index = 0; index < rows.length; index++)
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: index.isEven ? const Color(0xFFF4F8F6) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: palette.inkMuted.withValues(alpha: .12),
                    ),
                  ),
                ),
                child: _TableRowContent(
                  cells: rows[index],
                  locale: locale,
                  color: palette.ink,
                ),
              ),
            const Spacer(),
            Divider(color: palette.inkMuted.withValues(alpha: .3)),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.timeZoneId,
                    style: _style(locale, 10, palette.inkMuted),
                  ),
                ),
                Text(
                  l10n.prayerCalendarPage(page, total),
                  style: _style(locale, 10, palette.inkMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableRowContent extends StatelessWidget {
  const _TableRowContent({
    required this.cells,
    required this.locale,
    required this.color,
    this.bold = false,
    this.header = false,
  });
  final List<String> cells;
  final String locale;
  final Color color;
  final bool bold;
  final bool header;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 43, child: _cell(cells[0], 10.5)),
      SizedBox(width: 57, child: _cell(cells[1], 9.5)),
      for (var index = 2; index < cells.length; index++)
        Expanded(child: _cell(cells[index], header ? 9 : 10.3)),
    ],
  );

  Widget _cell(String value, double size) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: header
        ? FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: _style(locale, size, color, bold: bold),
            ),
          )
        : Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _style(locale, size, color, bold: bold),
          ),
  );
}
