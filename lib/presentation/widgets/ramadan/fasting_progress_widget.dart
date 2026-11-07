import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_time_picker.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';

/// Today's fast on the Ramadan plate: Imsaak and Iftar at the ends of a
/// gilt bar that fills toward the next one, and how long until it.
/// Between Iftar and the next Imsaak it shows the night the same way.
class RamadanFast extends StatefulWidget {
  const RamadanFast({
    super.key,
    required this.fajrTime,
    required this.maghribTime,
    this.clock,
    this.isRamadan = true,
  });

  /// Outside Ramadan the same times are today's, for a voluntary fast.
  final bool isRamadan;
  final DateTime fajrTime;
  final DateTime maghribTime;
  final DateTime Function()? clock;

  @override
  State<RamadanFast> createState() => _RamadanFastState();
}

class _RamadanFastState extends State<RamadanFast> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Minutes are what's shown: refresh a few times a minute.
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final space = tokens.space;
    final format = CalendarFormat.of(context);
    final now = widget.clock?.call() ?? DateTime.now();
    final fajr = widget.fajrTime;
    final maghrib = widget.maghribTime;

    final fasting = now.isAfter(fajr) && now.isBefore(maghrib);
    final DateTime from;
    final DateTime to;
    if (fasting) {
      from = fajr;
      to = maghrib;
    } else if (now.isAfter(maghrib)) {
      from = maghrib;
      to = fajr.add(const Duration(days: 1));
    } else {
      from = maghrib.subtract(const Duration(days: 1));
      to = fajr;
    }
    final total = to.difference(from);
    final progress = total.inSeconds <= 0
        ? 0.0
        : (now.difference(from).inSeconds / total.inSeconds).clamp(0.0, 1.0);
    final left = (to.difference(now).inSeconds / 60).ceil().clamp(0, 24 * 60);
    final when = hudaTimeUntil(context, left);

    Widget end(String label, DateTime time, {required bool next}) => Column(
      crossAxisAlignment: next
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: next ? tokens.gilt : tokens.onChromeMuted,
          ),
        ),
        Text(
          format.timeOf(time),
          style: theme.textTheme.titleLarge?.copyWith(
            color: tokens.onChrome,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          (widget.isRamadan ? l10n.ramadanTodaysFast : l10n.today)
              .toUpperCase(),
          style: context.type.eyebrow.copyWith(color: tokens.gilt),
        ),
        SizedBox(height: space.sm),
        // Side by side; stacked when large text leaves no room.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: space.lg,
          runSpacing: space.xs,
          children: [
            end(
              fasting ? l10n.imsaakLabel : l10n.iftarLabel,
              fasting ? fajr : maghrib,
              next: false,
            ),
            end(
              fasting ? l10n.iftarLabel : l10n.imsaakLabel,
              fasting ? maghrib : fajr,
              next: true,
            ),
          ],
        ),
        SizedBox(height: space.sm),
        Semantics(
          value: '${(progress * 100).round()}%',
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: tokens.motion.of(context, tokens.motion.long),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: const Size(double.infinity, 8),
              painter: _FastBar(
                value: value,
                track: tokens.onChrome.withValues(alpha: 0.14),
                fill: tokens.gilt,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
        ),
        SizedBox(height: space.sm),
        HudaStateSwitcher(
          stateKey: fasting,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            fasting ? l10n.ramadanIftarIn(when) : l10n.ramadanImsakIn(when),
            style: theme.textTheme.titleSmall?.copyWith(color: tokens.onChrome),
          ),
        ),
        Text(
          fasting
              ? l10n.durationOfFasting(total.inHours, total.inMinutes % 60)
              : l10n.durationOfIftar(total.inHours, total.inMinutes % 60),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.onChromeMuted,
          ),
        ),
      ],
    );
  }
}

class _FastBar extends CustomPainter {
  const _FastBar({
    required this.value,
    required this.track,
    required this.fill,
    required this.rtl,
  });

  final double value;
  final Color track;
  final Color fill;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    if (value <= 0) return;
    final width = (size.width * value).clamp(size.height, size.width);
    final rect = rtl
        ? Rect.fromLTWH(size.width - width, 0, width, size.height)
        : Rect.fromLTWH(0, 0, width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = fill,
    );
    // Where now is: a bright bead at the bar's leading end.
    final x = rtl ? rect.left + size.height / 2 : rect.right - size.height / 2;
    canvas.drawCircle(
      Offset(x, size.height / 2),
      size.height * 0.9,
      Paint()..color = fill,
    );
  }

  @override
  bool shouldRepaint(_FastBar old) =>
      old.value != value ||
      old.track != track ||
      old.fill != fill ||
      old.rtl != rtl;
}
