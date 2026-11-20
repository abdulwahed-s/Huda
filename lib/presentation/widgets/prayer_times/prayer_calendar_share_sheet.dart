import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/core/services/prayer_calendar_data.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_exporter.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_calendar_pickers.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showPrayerCalendarShareSheet(BuildContext context) {
  return showHudaSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.prayerCalendarShare,
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
      // User cancelled the export; nothing to report.
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
    final isImage = _period == PrayerCalendarPeriod.day;
    final tokens = context.tokens;
    final space = tokens.space;

    return PopScope(
      canPop: !_busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (location != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: palette.muted,
                ),
                SizedBox(width: space.xxs),
                Expanded(
                  child: Text(
                    location,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.muted,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: space.md),
          ],
          _PeriodSelector(
            value: _period,
            enabled: !_busy,
            onChanged: (period) => setState(() => _period = period),
          ),
          SizedBox(height: space.md),
          HudaStateSwitcher(
            stateKey: _period,
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
                onChanged: (year) =>
                    setState(() => _selected = DateTime(year, _selected.month)),
              ),
            },
          ),
          SizedBox(height: space.sm),
          Row(
            children: [
              Icon(
                isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                size: 18,
                color: palette.muted,
              ),
              SizedBox(width: space.xs),
              Expanded(
                child: Text(
                  '${switch (_period) {
                    PrayerCalendarPeriod.day => DateFormat.yMMMMEEEEd(locale).format(_selected),
                    PrayerCalendarPeriod.month => DateFormat.yMMMM(locale).format(_selected),
                    PrayerCalendarPeriod.year => DateFormat.y(locale).format(_selected),
                  }} · ${isImage ? l10n.prayerCalendarFormatImage : l10n.prayerCalendarFormatPdf}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: tokens.motion.of(context, tokens.motion.medium),
            curve: tokens.motion.standard,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: EdgeInsets.only(top: space.md),
                    child: PrayerStatusLine(
                      status: HudaStatus.failed,
                      message: _error,
                    ),
                  ),
                if (_busy)
                  Padding(
                    padding: EdgeInsets.only(top: space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(
                          value: _pageCount > 0 ? _page / _pageCount : null,
                          borderRadius: BorderRadius.circular(tokens.radius.sm),
                        ),
                        SizedBox(height: space.xs),
                        Text(
                          l10n.prayerCalendarPreparing(_page, _pageCount),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.muted,
                          ),
                        ),
                        TextButton(onPressed: _close, child: Text(l10n.cancel)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: space.lg),
          FilledButton.icon(
            key: const ValueKey('prayer-calendar-generate'),
            onPressed: _busy ? null : _generate,
            icon: _busy
                ? const HudaLampSpinner(size: 18)
                : const Icon(Icons.ios_share_rounded, size: 20),
            label: Text(l10n.prayerCalendarGenerate),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
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
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<PrayerCalendarPeriod>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: PrayerCalendarPeriod.day,
          icon: const Icon(Icons.today_rounded),
          label: Text(l10n.prayerCalendarOneDay),
        ),
        ButtonSegment(
          value: PrayerCalendarPeriod.month,
          icon: const Icon(Icons.calendar_view_month_rounded),
          label: Text(l10n.prayerCalendarOneMonth),
        ),
        ButtonSegment(
          value: PrayerCalendarPeriod.year,
          icon: const Icon(Icons.date_range_rounded),
          label: Text(l10n.prayerCalendarWholeYear),
        ),
      ],
      selected: {value},
      onSelectionChanged: enabled ? (set) => onChanged(set.first) : null,
    );
  }
}
