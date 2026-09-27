import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/prayer_calendar_data.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_exporter.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_pickers.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showPrayerCalendarShareSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<PrayerTimesCubit>(),
      child: const _PrayerCalendarShareSheet(),
    ),
  );
}

class _PrayerCalendarShareSheet extends StatefulWidget {
  const _PrayerCalendarShareSheet();

  @override
  State<_PrayerCalendarShareSheet> createState() =>
      _PrayerCalendarShareSheetState();
}

class _PrayerCalendarShareSheetState extends State<_PrayerCalendarShareSheet> {
  PrayerCalendarPeriod _period = PrayerCalendarPeriod.day;
  late DateTime _selected;
  bool _busy = false;
  bool _cancelRequested = false;
  int _page = 0;
  int _pageCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final snapshot = context.read<PrayerTimesCubit>().verifiedExportSnapshot;
    _selected = snapshot == null
        ? DateTime.now()
        : PrayerCalendarData(snapshot).localToday(DateTime.now());
  }

  void _close() {
    _cancelRequested = true;
    Navigator.of(context).pop();
  }

  Future<void> _generate() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final snapshot = context.read<PrayerTimesCubit>().verifiedExportSnapshot;
    if (snapshot == null) {
      setState(() => _error = l10n.prayerCalendarUnavailable);
      return;
    }
    final data = PrayerCalendarData(snapshot);
    setState(() {
      _busy = true;
      _error = null;
      _page = 0;
      _pageCount = 0;
    });
    try {
      final result = await PrayerCalendarExporter.generate(
        context: context,
        data: data,
        period: _period,
        selectedDate: _selected,
        onProgress: (current, total) {
          if (mounted && !_cancelRequested) {
            setState(() {
              _page = current;
              _pageCount = total;
            });
          }
        },
        isCancelled: () => _cancelRequested || !mounted,
      );
      if (_cancelRequested || !mounted) return;
      final originSize = MediaQuery.sizeOf(context);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(result.bytes, mimeType: result.mimeType)],
          fileNameOverrides: [result.fileName],
          text:
              '${l10n.prayerCalendarShareText(result.title, PrayerCalendarExporter.locationLabel(data, l10n, locale))}\n\n${l10n.sharedViaHuda}',
          subject: result.title,
          sharePositionOrigin: Rect.fromLTWH(
            originSize.width / 2,
            originSize.height / 2,
            1,
            1,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on PrayerCalendarCancelled {
    } catch (_) {
      if (mounted && !_cancelRequested) {
        setState(() => _error = l10n.prayerCalendarError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final snapshot = context.read<PrayerTimesCubit>().verifiedExportSnapshot;
    final location = snapshot == null
        ? null
        : PrayerCalendarExporter.locationLabel(
            PrayerCalendarData(snapshot),
            l10n,
            locale,
          );
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom > media.viewPadding.bottom
        ? media.viewInsets.bottom
        : media.viewPadding.bottom;
    final isImage = _period == PrayerCalendarPeriod.day;

    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: palette.tint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.prayerCalendarShare,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                        ),
                      ),
                      if (location != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: palette.muted,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _close,
                  tooltip: l10n.cancel,
                  style: IconButton.styleFrom(
                    backgroundColor: palette.tint,
                    foregroundColor: palette.ink,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _PeriodSelector(
              value: _period,
              enabled: !_busy,
              onChanged: (period) => setState(() => _period = period),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: KeyedSubtree(
                key: ValueKey(_period),
                child: switch (_period) {
                  PrayerCalendarPeriod.day => PrayerDayPicker(
                    selected: _selected,
                    enabled: !_busy,
                    onChanged: (date) => setState(() => _selected = date),
                  ),
                  PrayerCalendarPeriod.month => PrayerMonthPicker(
                    selected: _selected,
                    enabled: !_busy,
                    onChanged: (date) => setState(() => _selected = date),
                  ),
                  PrayerCalendarPeriod.year => PrayerYearGrid(
                    selectedYear: _selected.year,
                    enabled: !_busy,
                    onChanged: (year) => setState(
                      () => _selected = DateTime(year, _selected.month),
                    ),
                  ),
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isImage
                      ? Icons.image_outlined
                      : Icons.picture_as_pdf_outlined,
                  size: 17,
                  color: palette.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${switch (_period) {
                      PrayerCalendarPeriod.day => DateFormat.yMMMMEEEEd(locale).format(_selected),
                      PrayerCalendarPeriod.month => DateFormat.yMMMM(locale).format(_selected),
                      PrayerCalendarPeriod.year => DateFormat.y(locale).format(_selected),
                    }} · ${isImage ? l10n.prayerCalendarFormatImage : l10n.prayerCalendarFormatPdf}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.muted,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: palette.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 19,
                            color: palette.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.ink,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_busy)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: palette.cardDecoration(radius: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: _pageCount > 0 ? _page / _pageCount : null,
                              color: palette.primary,
                              backgroundColor: palette.tint,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.prayerCalendarPreparing(_page, _pageCount),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: _busy
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.onPrimary,
                      ),
                    )
                  : const Icon(Icons.ios_share_rounded, size: 20),
              label: Text(l10n.prayerCalendarGenerate),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                disabledBackgroundColor: palette.primary.withValues(
                  alpha: 0.55,
                ),
                disabledForegroundColor: palette.onPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final PrayerCalendarPeriod value;
  final bool enabled;
  final ValueChanged<PrayerCalendarPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (
        PrayerCalendarPeriod.day,
        l10n.prayerCalendarOneDay,
        Icons.today_rounded,
      ),
      (
        PrayerCalendarPeriod.month,
        l10n.prayerCalendarOneMonth,
        Icons.calendar_view_month_rounded,
      ),
      (
        PrayerCalendarPeriod.year,
        l10n.prayerCalendarWholeYear,
        Icons.date_range_rounded,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: palette.cardDecoration(radius: 18),
      child: Row(
        children: [
          for (final (period, label, icon) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: period == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? () => onChanged(period) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: period == value ? palette.primary : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: period == value
                              ? palette.onPrimary
                              : palette.muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: period == value
                                ? palette.onPrimary
                                : palette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
