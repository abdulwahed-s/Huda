import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:intl/intl.dart' hide TextDirection;

const int prayerPickerFirstYear = 1900;
const int prayerPickerLastYear = 2100;

class PrayerDayPicker extends StatefulWidget {
  const PrayerDayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  @override
  State<PrayerDayPicker> createState() => _PrayerDayPickerState();
}

class _PrayerDayPickerState extends State<PrayerDayPicker> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);
  bool _choosingYear = false;

  void _moveMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.year < prayerPickerFirstYear || next.year > prayerPickerLastYear) {
      return;
    }
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return _PickerCard(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _choosingYear
            ? PrayerYearGrid(
                selectedYear: _month.year,
                enabled: widget.enabled,
                framed: false,
                onChanged: (year) => setState(() {
                  _month = DateTime(year, _month.month);
                  _choosingYear = false;
                }),
              )
            : Column(
                children: [
                  _PickerHeader(
                    title: DateFormat.yMMMM(locale).format(_month),
                    onTitleTap: widget.enabled
                        ? () => setState(() => _choosingYear = true)
                        : null,
                    onPrevious: widget.enabled ? () => _moveMonth(-1) : null,
                    onNext: widget.enabled ? () => _moveMonth(1) : null,
                  ),
                  const SizedBox(height: 4),
                  _DayGrid(
                    month: _month,
                    selected: widget.selected,
                    enabled: widget.enabled,
                    onChanged: widget.onChanged,
                  ),
                ],
              ),
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final DateTime month;
  final DateTime selected;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final material = MaterialLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final firstWeekday = material.firstDayOfWeekIndex;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leading =
        (DateTime(month.year, month.month).weekday % 7 - firstWeekday + 7) % 7;
    final today = DateUtils.dateOnly(DateTime.now());
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      material.narrowWeekdays[(firstWeekday + i) % 7],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.faint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = row * 7 + column - leading + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const SizedBox(height: 40);
                      }
                      final date = DateTime(month.year, month.month, day);
                      final isSelected = DateUtils.isSameDay(date, selected);
                      final isToday = DateUtils.isSameDay(date, today);
                      return _Cell(
                        label: NumberFormat.decimalPattern(locale).format(day),
                        semanticsLabel: material.formatFullDate(date),
                        selected: isSelected,
                        outlined: isToday && !isSelected,
                        height: 40,
                        circle: true,
                        onTap: enabled ? () => onChanged(date) : null,
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class PrayerMonthPicker extends StatelessWidget {
  const PrayerMonthPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final year = selected.year;
    void setYear(int value) => onChanged(DateTime(value, selected.month));

    return _PickerCard(
      child: Column(
        children: [
          _PickerHeader(
            title: DateFormat.y(locale).format(selected),
            onPrevious: enabled && year > prayerPickerFirstYear
                ? () => setYear(year - 1)
                : null,
            onNext: enabled && year < prayerPickerLastYear
                ? () => setYear(year + 1)
                : null,
          ),
          const SizedBox(height: 6),
          _Grid(
            columns: 4,
            children: [
              for (var month = 1; month <= 12; month++)
                _Cell(
                  label: DateFormat.MMM(locale).format(DateTime(year, month)),
                  semanticsLabel: DateFormat.yMMMM(
                    locale,
                  ).format(DateTime(year, month)),
                  selected: month == selected.month,
                  onTap: enabled
                      ? () => onChanged(DateTime(year, month))
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrayerYearGrid extends StatefulWidget {
  const PrayerYearGrid({
    super.key,
    required this.selectedYear,
    required this.onChanged,
    this.enabled = true,
    this.framed = true,
  });

  final int selectedYear;
  final ValueChanged<int> onChanged;
  final bool enabled;

  final bool framed;

  @override
  State<PrayerYearGrid> createState() => _PrayerYearGridState();
}

class _PrayerYearGridState extends State<PrayerYearGrid> {
  static const _page = 12;
  late int _start = _pageStart(widget.selectedYear);

  static int _pageStart(int year) =>
      year - (year - prayerPickerFirstYear) % _page;

  @override
  void didUpdateWidget(covariant PrayerYearGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear) {
      _start = _pageStart(widget.selectedYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.y(locale);
    final end = (_start + _page - 1).clamp(
      prayerPickerFirstYear,
      prayerPickerLastYear,
    );
    final grid = Column(
      children: [
        _PickerHeader(
          title:
              '${format.format(DateTime(_start))} – ${format.format(DateTime(end))}',
          onPrevious: widget.enabled && _start > prayerPickerFirstYear
              ? () => setState(() => _start -= _page)
              : null,
          onNext: widget.enabled && end < prayerPickerLastYear
              ? () => setState(() => _start += _page)
              : null,
        ),
        const SizedBox(height: 6),
        _Grid(
          columns: 4,
          children: [
            for (var year = _start; year <= end; year++)
              _Cell(
                label: format.format(DateTime(year)),
                selected: year == widget.selectedYear,
                outlined: year == DateTime.now().year,
                onTap: widget.enabled ? () => widget.onChanged(year) : null,
              ),
          ],
        ),
      ],
    );
    return widget.framed ? _PickerCard(child: grid) : grid;
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      decoration: PrayerPalette.of(context).cardDecoration(radius: 20),
      child: child,
    );
  }
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    this.onTitleTap,
  });

  final String title;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onTitleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final material = MaterialLocalizations.of(context);
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        color: palette.ink,
        fontWeight: FontWeight.w800,
      ),
    );
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: material.previousPageTooltip,
          color: palette.primary,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Center(
            child: onTitleTap == null
                ? titleText
                : TextButton.icon(
                    onPressed: onTitleTap,
                    style: TextButton.styleFrom(foregroundColor: palette.ink),
                    iconAlignment: IconAlignment.end,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: palette.muted,
                    ),
                    label: titleText,
                  ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: material.nextPageTooltip,
          color: palette.primary,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < children.length; start += columns)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                for (var i = start; i < start + columns; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: i < children.length
                          ? children[i]
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticsLabel,
    this.outlined = false,
    this.circle = false,
    this.height = 42,
  });

  final String label;
  final String? semanticsLabel;
  final bool selected;

  final bool outlined;
  final bool circle;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final shape = circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final child = SizedBox(
      height: height,
      width: circle ? height : double.infinity,
      child: Material(
        color: selected ? palette.primary : Colors.transparent,
        shape: outlined
            ? (circle
                  ? CircleBorder(side: BorderSide(color: palette.primary))
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: palette.primary),
                    ))
            : shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected
                    ? palette.onPrimary
                    : onTap == null
                    ? palette.faint
                    : palette.ink,
                fontWeight: selected || outlined
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel ?? label,
      excludeSemantics: true,
      child: circle ? Center(child: child) : child,
    );
  }
}
