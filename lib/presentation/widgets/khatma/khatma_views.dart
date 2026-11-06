import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:huda/core/quran/quran.dart' as quran;
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/services/khatma_service.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/khatma/khatma_identity.dart';

/// The Khatma's views inside its sheet: setup (choose a pace and where to
/// start), today's portion with the road, the completed khatma, and the
/// schedule of every portion. `KhatmaPage` holds the state and switches
/// between them.

/// The paces a khatma can take, in days, shortest first. "By meaning" and
/// "by juz" were two lists of the same plans (the service divides the 604
/// pages evenly), so they are one choice now.
const khatmaPaces = [3, 6, 7, 10, 15, 20, 29, 30, 40, 60, 80, 120, 240];

/// The suggested pace: a month.
const khatmaSuggestedPace = 29;

/// The portion a pace reads each day, in the words people know it by.
String khatmaPortionLabel(AppLocalizations l10n, int days, int pagesPerDay) =>
    switch (days) {
      3 => l10n.khatmaDailyWird10Juz,
      6 => l10n.khatmaDailyWird5Juz,
      10 => l10n.khatmaDailyWird3Juz,
      15 => l10n.khatmaDailyWirdTwoJuz,
      20 => l10n.khatmaDailyWirdJuzAndHalf,
      30 => l10n.khatmaDailyWirdJuz,
      40 => l10n.khatmaDailyWirdHizbAndHalf,
      60 => l10n.khatmaDailyWirdHizb,
      80 => l10n.khatmaDailyWird3Rubu,
      120 => l10n.khatmaDailyWirdTwoRubu,
      240 => l10n.khatmaDailyWirdRubu,
      _ => l10n.khatmaDailyWirdPages(pagesPerDay),
    };

/// "From Al-Baqarah: 142" in the app's language.
String khatmaFrom(BuildContext context, int surah, int verse) =>
    AppLocalizations.of(
      context,
    )!.khatmaFromSurah(_surah(context, surah), verse);

/// "To Al-Baqarah: 202" in the app's language.
String khatmaTo(BuildContext context, int surah, int verse) =>
    AppLocalizations.of(context)!.khatmaToSurah(_surah(context, surah), verse);

String _surah(BuildContext context, int surah) => quran.getSurahNameLocalized(
  surah,
  Localizations.localeOf(context).languageCode,
);

/// A step's heading inside the sheet, under the sheet's "Khatma": Back
/// and the step's title.
class KhatmaStepHeader extends StatelessWidget {
  const KhatmaStepHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.message,
  });

  final String title;
  final VoidCallback onBack;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final message = this.message;
    return Padding(
      padding: EdgeInsets.only(bottom: space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('khatma-back'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              SizedBox(width: space.xs),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          if (message != null)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: space.xxs,
                top: space.xxs,
              ),
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Layout --------------------------------------------------------------------

/// Whether a view splits into two columns: in the wide dialog (from 760),
/// or side by side on a short window (phone landscape, the Duo closed in
/// landscape) so the main action stays in view.
bool _twoColumns(BuildContext context, double width) =>
    width >= 760 || (_short(context) && width >= 460);

bool _short(BuildContext context) => MediaQuery.sizeOf(context).height < 480;

/// A view's parts in one column, or in two: [lead] always leads; [middle]
/// follows it in the wide dialog but opens the second column on a short
/// window (so today's portion is in view next to the road); [rest] fills
/// the second column.
class _KhatmaColumns extends StatelessWidget {
  const _KhatmaColumns({
    required this.lead,
    this.middle = const [],
    required this.rest,
    this.wide = true,
  });

  /// Whether the wide dialog splits too (not only a short window).
  final bool wide;
  final List<Widget> lead;
  final List<Widget> middle;
  final List<Widget> rest;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    Widget column(List<Widget> parts, [int from = 0]) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, part) in parts.indexed) ...[
          if (i > 0) SizedBox(height: space.lg),
          HudaReveal(index: from + i, child: part),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final split = wide
            ? _twoColumns(context, width)
            : _short(context) && width >= 460;
        if (!split) {
          return column([...lead, ...middle, ...rest]);
        }
        final short = _short(context) && constraints.maxWidth < 760;
        final first = short ? lead : [...lead, ...middle];
        final second = short ? [...middle, ...rest] : rest;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: column(first)),
            SizedBox(width: space.lg),
            Expanded(flex: 6, child: column(second, first.length)),
          ],
        );
      },
    );
  }
}

/// An eyebrow on the plate. Arabic script keeps its letters and digits
/// together (no tracking).
class _PlateEyebrow extends StatelessWidget {
  const _PlateEyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final arabicScript = Directionality.of(context) == TextDirection.rtl;
    return Text(
      arabicScript ? text : text.toUpperCase(),
      style: context.type.eyebrow.copyWith(
        color: tokens.gilt,
        letterSpacing: arabicScript ? 0 : null,
      ),
    );
  }
}

// Setup ---------------------------------------------------------------------

/// No plan yet (or a new one after a khatma): the empty road, the paces,
/// and where to start.
class KhatmaSetupView extends StatelessWidget {
  const KhatmaSetupView({
    super.key,
    required this.days,
    required this.pagesPerDay,
    required this.onDays,
    required this.onFromBeginning,
    required this.onChooseDay,
    this.onBack,
  });

  final int days;
  final int Function(int days) pagesPerDay;
  final ValueChanged<int> onDays;
  final VoidCallback onFromBeginning;
  final VoidCallback onChooseDay;

  /// Set when a finished khatma led here.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final onBack = this.onBack;
    final suggested = days == khatmaSuggestedPace;
    // Small phones keep "Start from Al-Fatihah" in view: no description.
    final roomy = MediaQuery.sizeOf(context).height >= 700;
    final finish = DateFormat.MMMEd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(DateTime.now().add(Duration(days: days - 1)));
    // The plan as chosen: its days, its daily portion and when it ends.
    // It follows the pace tiles as they change.
    final plate = KhatmaPlate(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: space.sm,
                  runSpacing: space.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _PlateEyebrow(l10n.khatmaTitle),
                    if (suggested)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: tokens.gilt,
                          ),
                          SizedBox(width: space.xxs),
                          Text(
                            l10n.khatmaSuggested,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: tokens.gilt,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: space.xs),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: HudaNumberRoll(
                          value: days,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: tokens.onChrome,
                            height: 1.1,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: ' ${l10n.khatmaPaceUnit(days)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: tokens.onChrome,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: space.xxs),
                HudaStateSwitcher(
                  stateKey: days,
                  sequential: true,
                  alignment: AlignmentDirectional.topStart,
                  child: Column(
                    key: const ValueKey('khatma-pace-summary'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        khatmaPortionLabel(l10n, days, pagesPerDay(days)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.onChromeMuted,
                        ),
                      ),
                      SizedBox(height: space.xxs),
                      Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 16,
                            color: tokens.gilt,
                          ),
                          SizedBox(width: space.xxs),
                          Flexible(
                            child: Text(
                              l10n.khatmaFinishOn(finish),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.onChrome,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: space.md),
          // The khatm star the plan ends at.
          Ornament(
            size: Size.square(_short(context) ? 48 : 72),
            painter: KhatmMedallionPainter(color: tokens.gilt),
          ),
        ],
      ),
    );
    final paces = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // What a khatma is, where there's room for it.
        if (roomy) ...[
          Text(
            l10n.khatmaDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: space.md),
        ],
        HudaSectionHeader(l10n.khatmaChoosePace),
        _Paces(days: days, pagesPerDay: pagesPerDay, onDays: onDays),
      ],
    );
    final start = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey('khatma-start'),
          onPressed: onFromBeginning,
          icon: const Icon(Icons.flag_rounded),
          label: Text(l10n.khatmaFromBeginningSubtitle),
        ),
        SizedBox(height: space.xs),
        OutlinedButton.icon(
          key: const ValueKey('khatma-choose-day'),
          onPressed: onChooseDay,
          icon: const Icon(Icons.format_list_numbered_rounded),
          label: Text(l10n.khatmaStartFromDay),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onBack != null)
          KhatmaStepHeader(title: l10n.khatmaNewTitle, onBack: onBack),
        // The paces want the whole width of a wide dialog (a grid of 7 and
        // 6); only a short window sets them beside the road.
        _KhatmaColumns(lead: [plate], rest: [paces, start], wide: false),
      ],
    );
  }
}

/// The paces: one row that scrolls sideways where the room is narrow
/// (phones, a column), a grid where there's room. The chosen one is lit.
class _Paces extends StatefulWidget {
  const _Paces({
    required this.days,
    required this.pagesPerDay,
    required this.onDays,
  });

  final int days;
  final int Function(int days) pagesPerDay;
  final ValueChanged<int> onDays;

  @override
  State<_Paces> createState() => _PacesState();
}

class _PacesState extends State<_Paces> {
  ScrollController? _row;

  @override
  void dispose() {
    _row?.dispose();
    super.dispose();
  }

  Widget _tile(int days) => _PaceTile(
    days: days,
    pages: widget.pagesPerDay(days),
    selected: days == widget.days,
    onTap: () => widget.onDays(days),
  );

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final gap = space.xs;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 480) {
          // One row, the chosen pace centered when it first shows.
          // Large text still shows more than one pace, so the row reads as
          // a row.
          final tile = math.min(104 * scale, (width - gap) / 2.3);
          final index = khatmaPaces.indexOf(widget.days);
          final extent = khatmaPaces.length * (tile + gap) - gap;
          _row ??= ScrollController(
            initialScrollOffset: (index * (tile + gap) - (width - tile) / 2)
                .clamp(0.0, math.max(0.0, extent - width)),
          );
          // Mouse and trackpad drag it too (a narrow desktop window).
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            child: SingleChildScrollView(
              key: const ValueKey('khatma-paces'),
              controller: _row,
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, days) in khatmaPaces.indexed) ...[
                      if (i > 0) SizedBox(width: gap),
                      SizedBox(width: tile, child: _tile(days)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        // A grid whose last row isn't a lone tile: the most columns that
        // fit, stepping down while the last row would be under half full.
        // Across a vertical fold, an even count (8 + 5) puts a gap on the
        // crease when one works.
        final fit = ((width + gap) / (96 * scale + gap)).floor();
        int? pick(int most, int step) {
          for (var c = most; c >= 2; c -= step) {
            final last = khatmaPaces.length % c;
            if (last == 0 || last * 2 >= c) return c;
          }
          return null;
        }

        final fold = context.fold;
        int? columns;
        if (fold.hasFold && fold.splitsHorizontally) {
          final even = math.min(fit, 8);
          final c = pick(even.isOdd ? even - 1 : even, 2);
          if (c != null && c >= 4) columns = c;
        }
        columns ??= pick(fit.clamp(2, 7), 1) ?? 2;
        final tileWidth = (width - gap * (columns - 1)) / columns;
        return Column(
          children: [
            for (var i = 0; i < khatmaPaces.length; i += columns)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                child: IntrinsicHeight(
                  child: Row(
                    // A short last row sits in the middle.
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (c, days)
                          in khatmaPaces
                              .sublist(
                                i,
                                math.min(i + columns, khatmaPaces.length),
                              )
                              .indexed) ...[
                        if (c > 0) SizedBox(width: gap),
                        SizedBox(width: tileWidth, child: _tile(days)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PaceTile extends StatelessWidget {
  const _PaceTile({
    required this.days,
    required this.pages,
    required this.selected,
    required this.onTap,
  });

  final int days;
  final int pages;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final motion = tokens.motion;
    final radius = BorderRadius.circular(tokens.radius.md);
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: HudaPressable(
        // The fill and the text change together, so the tile never loses
        // its contrast mid-change.
        child: TweenAnimationBuilder<double>(
          key: ValueKey('khatma-pace-$days'),
          tween: Tween(end: selected ? 1 : 0),
          duration: motion.of(context, motion.short),
          curve: motion.standard,
          builder: (context, lit, _) {
            final ink = Color.lerp(scheme.onSurface, tokens.onChrome, lit)!;
            final muted = Color.lerp(
              scheme.onSurfaceVariant,
              tokens.onChromeMuted,
              lit,
            )!;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(scheme.surface, tokens.lit, lit),
                borderRadius: radius,
                border: Border.all(
                  color: Color.lerp(scheme.outline, tokens.lit, lit)!,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: EdgeInsets.all(space.xs),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$days',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: ink,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: l10n.khatmaPaceUnit(days),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: ink,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            l10n.khatmaPagesADay(pages),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Schedule ------------------------------------------------------------------

/// Every portion of a plan, day by day. While setting up, a tap starts the
/// plan from that day; otherwise the days read are ticked and today's is
/// lit (and scrolled to).
class KhatmaScheduleView extends StatefulWidget {
  const KhatmaScheduleView({
    super.key,
    required this.service,
    required this.days,
    required this.currentDay,
    required this.title,
    required this.onBack,
    this.message,
    this.onDay,
  });

  final KhatmaService service;
  final int days;

  /// Today's portion, or -1 while setting up.
  final int currentDay;
  final String title;
  final String? message;
  final VoidCallback onBack;
  final ValueChanged<int>? onDay;

  @override
  State<KhatmaScheduleView> createState() => _KhatmaScheduleViewState();
}

class _KhatmaScheduleViewState extends State<KhatmaScheduleView> {
  final _current = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.currentDay > 0) {
      // After the step has switched in (the sheet's height eases while it
      // does), bring today's row into view.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final motion = context.tokens.motion;
        final settle = motion.of(context, motion.medium);
        if (settle > Duration.zero) {
          await Future<void>.delayed(settle + const Duration(milliseconds: 50));
        }
        final target = _current.currentContext;
        if (!mounted || target == null || !target.mounted) return;
        await Scrollable.ensureVisible(
          target,
          alignment: 0.3,
          duration: motion.of(context, motion.long),
          curve: motion.emphasized,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KhatmaStepHeader(
          title: widget.title,
          message: widget.message,
          onBack: widget.onBack,
        ),
        SizedBox(height: space.xs),
        HudaCard(
          padding: EdgeInsets.symmetric(vertical: space.xxs),
          child: Column(
            children: [
              for (var day = 0; day < widget.days; day++)
                _ScheduleRow(
                  key: day == widget.currentDay ? _current : null,
                  day: day,
                  range: widget.service.rangeDetailsForDay(day, widget.days),
                  done: widget.currentDay >= 0 && day < widget.currentDay,
                  current: day == widget.currentDay,
                  onTap: widget.onDay == null ? null : () => widget.onDay!(day),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    super.key,
    required this.day,
    required this.range,
    required this.done,
    required this.current,
    this.onTap,
  });

  final int day;
  final ({
    int startPage,
    int endPage,
    int startSurah,
    int startVerse,
    String startSurahName,
    int endSurah,
    int endVerse,
    String endSurahName,
  })
  range;
  final bool done;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final Widget mark = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: current
            ? tokens.lit
            : done
            ? scheme.primary.withValues(alpha: 0.12)
            : null,
        border: current || done ? null : Border.all(color: scheme.outline),
      ),
      child: done
          ? Icon(Icons.check_rounded, size: 18, color: scheme.primary)
          : Text(
              '${day + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: current ? tokens.onChrome : scheme.onSurfaceVariant,
              ),
            ),
    );
    return Semantics(
      selected: current,
      child: Material(
        color: current
            ? scheme.secondaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: space.md,
              vertical: space.sm,
            ),
            child: Row(
              children: [
                mark,
                SizedBox(width: space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.khatmaDailyWirdOf(day + 1),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${khatmaFrom(context, range.startSurah, range.startVerse)}'
                        ' · '
                        '${khatmaTo(context, range.endSurah, range.endVerse)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Progress ------------------------------------------------------------------

/// A khatma under way: the road with today's portion on it, the portion
/// itself (open it at its start or end, mark it done), the numbers, the
/// reminder and the plan.
class KhatmaActiveView extends StatelessWidget {
  const KhatmaActiveView({
    super.key,
    required this.service,
    required this.trailFrom,
    required this.relativeDay,
    required this.reminder,
    required this.plan,
    required this.onOpen,
    required this.onMarkDone,
  });

  final KhatmaService service;
  final double trailFrom;
  final String relativeDay;
  final Widget reminder;
  final Widget plan;

  /// Opens the reader at a surah and ayah.
  final void Function(int surah, int verse) onOpen;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final days = service.planDays;
    final dayIndex = service.currentDayIndex;
    final day = (dayIndex + 1).clamp(1, days);
    final range = service.rangeDetailsForDay(dayIndex, days);
    final percent = (service.percentTotal * 100).toInt();
    final walked = KhatmaJourney.position(service.totalPagesRead);
    final todayEnd = KhatmaJourney.position(range.endPage);
    final dayOf = l10n.khatmaDayOf(day, days);

    final plate = KhatmaPlate(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: HudaEyebrow(dayOf, color: tokens.gilt)),
              SizedBox(width: space.sm),
              HudaNumberRoll(
                value: percent,
                format: (v) => '$v%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tokens.onChrome,
                ),
              ),
            ],
          ),
          SizedBox(height: space.xs),
          KhatmaTrail(
            key: const ValueKey('khatma-trail'),
            walked: walked,
            todayEnd: todayEnd,
            from: trailFrom,
            semanticLabel: '$dayOf, $percent%',
          ),
        ],
      ),
    );
    final today = HudaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              space.md,
              space.md,
              space.md,
              space.xxs,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: space.sm,
              runSpacing: space.xxs,
              children: [
                HudaEyebrow(l10n.khatmaDailyWirdOf(day), header: true),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    SizedBox(width: space.xxs),
                    Text(
                      relativeDay,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RangeRow(
            key: const ValueKey('khatma-open-start'),
            end: false,
            label: khatmaFrom(context, range.startSurah, range.startVerse),
            onTap: () => onOpen(range.startSurah, range.startVerse),
          ),
          _RangeRow(
            key: const ValueKey('khatma-open-end'),
            end: true,
            label: khatmaTo(context, range.endSurah, range.endVerse),
            onTap: () => onOpen(range.endSurah, range.endVerse),
          ),
          Padding(
            padding: EdgeInsets.all(space.md),
            child: FilledButton.icon(
              key: const ValueKey('khatma-mark-done'),
              onPressed: onMarkDone,
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.khatmaMarkDone),
            ),
          ),
        ],
      ),
    );
    return _KhatmaColumns(
      lead: [plate],
      middle: [today],
      rest: [
        _Stats(service: service),
        reminder,
        plan,
      ],
    );
  }
}

/// Where today's portion starts or ends; a tap opens the reader there. Its
/// mark is the road's: the walker for the start, a waymark for the end.
class _RangeRow extends StatelessWidget {
  const _RangeRow({
    super.key,
    required this.end,
    required this.label,
    required this.onTap,
  });

  final bool end;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: space.md,
            vertical: space.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(
                  painter: _RangeMark(end: end, color: scheme.primary),
                ),
              ),
              SizedBox(width: space.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeMark extends CustomPainter {
  const _RangeMark({required this.end, required this.color});

  final bool end;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    if (end) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 7)
          ..lineTo(c.dx + 5, c.dy)
          ..lineTo(c.dx, c.dy + 7)
          ..lineTo(c.dx - 5, c.dy)
          ..close(),
        stroke,
      );
    } else {
      canvas
        ..drawCircle(c, 7, stroke)
        ..drawCircle(c, 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RangeMark old) => old.end != end || old.color != color;
}

/// The numbers: pages read and left, days left, and how well the reading
/// keeps to the plan.
class _Stats extends StatelessWidget {
  const _Stats({required this.service});

  final KhatmaService service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final items = [
      (service.totalPagesRead, l10n.khatmaPagesRead, ''),
      (service.pagesRemaining, l10n.khatmaPagesRemaining, ''),
      (service.daysRemaining, l10n.khatmaDaysRemaining, ''),
      ((service.percentPacing * 100).toInt(), l10n.khatmaCommitment, '%'),
    ];
    return HudaCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final four = constraints.maxWidth >= 4 * 104 * scale;
          Widget stat(int i) => _Stat(
            value: items[i].$1,
            suffix: items[i].$3,
            label: items[i].$2,
          );
          final divider = VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          );
          Widget row(List<int> indices) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (n, i) in indices.indexed) ...[
                  if (n > 0) divider,
                  Expanded(child: stat(i)),
                ],
              ],
            ),
          );
          if (four) return row([0, 1, 2, 3]);
          return Column(
            children: [
              row([0, 1]),
              const Divider(height: 1),
              row([2, 3]),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.suffix, required this.label});

  final int value;
  final String suffix;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return Semantics(
      container: true,
      label: '$label: $value$suffix',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: space.sm,
            vertical: space.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HudaNumberRoll(
                value: value,
                format: (v) => '$v$suffix',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: space.xxs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A finished khatma: a celebration. The khatm medallion draws itself in
/// over the plate, a light runs once along the whole road that was walked,
/// and the journey is counted up (30 juz, 604 pages, the days it took).
/// Then: read it again, or begin another.
class KhatmaCompletedView extends StatelessWidget {
  const KhatmaCompletedView({
    super.key,
    required this.trailFrom,
    required this.days,
    required this.reminder,
    required this.plan,
    required this.onRepeat,
    required this.onStartNew,
  });

  final double trailFrom;

  /// The days the khatma took.
  final int days;
  final Widget reminder;
  final Widget plan;
  final VoidCallback onRepeat;
  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey('khatma-repeat'),
          onPressed: onRepeat,
          icon: const Icon(Icons.autorenew_rounded),
          label: Text(l10n.khatmaRepeat),
        ),
        SizedBox(height: space.xs),
        OutlinedButton.icon(
          key: const ValueKey('khatma-new'),
          onPressed: onStartNew,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.khatmaStartNew),
        ),
      ],
    );
    return _KhatmaColumns(
      lead: [_CompletionHero(trailFrom: trailFrom, days: days)],
      middle: [actions],
      rest: [reminder, plan],
    );
  }
}

class _CompletionHero extends StatefulWidget {
  const _CompletionHero({required this.trailFrom, required this.days});

  final double trailFrom;
  final int days;

  @override
  State<_CompletionHero> createState() => _CompletionHeroState();
}

class _CompletionHeroState extends State<_CompletionHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _celebration.value = 1;
    } else {
      _celebration.forward();
    }
  }

  @override
  void dispose() {
    _celebration.dispose();
    super.dispose();
  }

  Animation<double> _phase(double from, double to, [Curve? curve]) =>
      CurvedAnimation(
        parent: _celebration,
        curve: Interval(from, to, curve: curve ?? Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final short = _short(context);
    final medallion = _phase(0, 0.8, Curves.easeInOut);
    final words = _phase(0.3, 0.65);
    final count = _phase(0.45, 0.95);
    // Rises a little as it fades in.
    Widget arrive(Animation<double> a, Widget child) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
    final stats = [
      (KhatmaJourney.juzCount, l10n.khatmaStatJuz(KhatmaJourney.juzCount)),
      (
        KhatmaJourney.totalPages,
        l10n.khatmaStatPages(KhatmaJourney.totalPages),
      ),
      (widget.days, l10n.khatmaPaceUnit(widget.days)),
    ];
    return KhatmaPlate(
      child: Column(
        children: [
          SizedBox(height: space.xs),
          AnimatedBuilder(
            animation: medallion,
            builder: (context, _) => Ornament(
              size: Size.square(short ? 72 : 112),
              painter: KhatmMedallionPainter(
                color: tokens.gilt,
                progress: medallion.value,
              ),
            ),
          ),
          SizedBox(height: space.md),
          arrive(
            words,
            Column(
              children: [
                Text(
                  l10n.khatmaCongrats,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: tokens.onChrome,
                  ),
                ),
                SizedBox(height: space.xxs),
                Text(
                  l10n.khatmaCompletedMsg,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.onChromeMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: space.md),
          // The journey, counted up.
          FadeTransition(
            opacity: count,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  for (final (i, (value, label)) in stats.indexed) ...[
                    if (i > 0)
                      VerticalDivider(
                        width: space.md,
                        color: tokens.gilt.withValues(alpha: 0.3),
                      ),
                    Expanded(
                      child: Semantics(
                        label: '$value $label',
                        child: ExcludeSemantics(
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: count,
                                builder: (context, _) => Text(
                                  '${(value * count.value).round()}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: tokens.gilt,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              Text(
                                label,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: tokens.onChromeMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: space.sm),
          KhatmaTrail(
            key: const ValueKey('khatma-trail'),
            walked: 30,
            from: widget.trailFrom,
            flat: true,
            glint: _phase(0.2, 1, Curves.easeInOut),
            semanticLabel: l10n.khatmaCompletedMsg,
          ),
        ],
      ),
    );
  }
}

// Reminder and plan ---------------------------------------------------------

/// The daily reminder: what notifications still need, the switch and the
/// time.
class KhatmaReminderSection extends StatelessWidget {
  const KhatmaReminderSection({
    super.key,
    required this.enabled,
    required this.time,
    required this.requirements,
    required this.onToggle,
    required this.onPickTime,
  });

  final bool enabled;
  final String time;
  final Widget requirements;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HudaSectionHeader(l10n.khatmaDailyReminderSection),
        requirements,
        HudaCard(
          padding: EdgeInsets.symmetric(vertical: space.xxs),
          child: Column(
            children: [
              MergeSemantics(
                child: HudaSettingsRow(
                  key: const ValueKey('khatma-reminder'),
                  icon: Icons.notifications_rounded,
                  title: l10n.khatmaDailyWirdTitle,
                  onTap: () => onToggle(!enabled),
                  trailing: Switch(value: enabled, onChanged: onToggle),
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
              HudaSettingsRow(
                key: const ValueKey('khatma-reminder-time'),
                icon: Icons.schedule_rounded,
                title: l10n.khatmaReminderTime,
                onTap: onPickTime,
                trailing: Text(
                  time,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The plan's rarer actions: every portion, and deleting it.
class KhatmaPlanSection extends StatelessWidget {
  const KhatmaPlanSection({
    super.key,
    required this.onSchedule,
    required this.onDelete,
  });

  final VoidCallback onSchedule;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final space = context.tokens.space;
    return HudaCard(
      padding: EdgeInsets.symmetric(vertical: space.xxs),
      child: Column(
        children: [
          HudaSettingsRow(
            key: const ValueKey('khatma-schedule'),
            icon: Icons.format_list_numbered_rounded,
            title: l10n.khatmaAllWirds,
            onTap: onSchedule,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: ListTile(
              key: const ValueKey('khatma-delete'),
              leading: HudaIconMark(
                Icons.delete_outline_rounded,
                accent: scheme.error,
              ),
              title: Text(
                l10n.khatmaDeleteTitle,
                style: TextStyle(color: scheme.error),
              ),
              subtitle: Text(l10n.khatmaDeleteSubtitle),
              onTap: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
