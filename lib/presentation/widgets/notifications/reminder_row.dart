import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// What a reminder row is doing besides being on or off.
enum ReminderRowStatus {
  idle,

  /// The cubit is scheduling it (a switch or a time change).
  scheduling,

  /// Scheduling again after the person tapped Retry.
  retrying,

  /// Scheduling failed; the switch is back off.
  failed,
}

/// One reminder: its mark, title and what it does, the switch, and the
/// schedule as chips that change it in place. Below, a status line while
/// it's being scheduled, or after it failed with Retry.
class ReminderRow extends StatelessWidget {
  const ReminderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.schedule,
    this.status = ReminderRowStatus.idle,
    this.onRetry,
    this.failure,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// The time chips (or a frequency chip).
  final List<Widget> schedule;
  final ReminderRowStatus status;
  final VoidCallback? onRetry;

  /// Why it failed and what fixes it ("Alarms are off…", "Open Settings"),
  /// in place of "Couldn't schedule" and Retry; [onRetry] runs the fix.
  final (String message, String action)? failure;

  /// A platform note under the description (Sahur on older iOS).
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy =
        status == ReminderRowStatus.scheduling ||
        status == ReminderRowStatus.retrying;
    final footnote = this.footnote;
    return HudaCard(
      padding: EdgeInsetsDirectional.fromSTEB(space.md, space.sm, space.xs, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: space.xxs),
                child: HudaIconMark(icon),
              ),
              SizedBox(width: space.sm),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: space.xxs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      SizedBox(height: space.xxs),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (footnote != null) ...[
                        SizedBox(height: space.xxs),
                        Text(
                          footnote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(width: space.xxs),
              Semantics(
                label: title,
                child: Switch(value: value, onChanged: busy ? null : onChanged),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: 38 + space.sm - space.xxs,
              end: space.xs,
            ),
            child: Wrap(spacing: space.xs, children: schedule),
          ),
          // A cross-fade whose outgoing line takes no room: rows sit in
          // equal-height grid rows sized from the current line only.
          AnimatedSwitcher(
            duration: tokens.motion.of(context, tokens.motion.medium),
            switchInCurve: tokens.motion.standard,
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topStart,
              clipBehavior: Clip.hardEdge,
              children: [
                for (final child in previous) Positioned.fill(child: child),
                ?current,
              ],
            ),
            child: KeyedSubtree(
              key: ValueKey(status),
              child: status == ReminderRowStatus.idle
                  ? SizedBox(height: space.xs)
                  : Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: 38 + space.sm,
                        end: space.xs,
                        bottom: space.xs,
                      ),
                      child: _StatusLine(
                        status: status,
                        onRetry: onRetry,
                        failure: failure,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status, this.onRetry, this.failure});

  final ReminderRowStatus status;
  final VoidCallback? onRetry;
  final (String, String)? failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final failed = status == ReminderRowStatus.failed;
    final failure = this.failure;
    final text = switch (status) {
      ReminderRowStatus.retrying => l10n.stateRetrying,
      ReminderRowStatus.failed =>
        failure?.$1 ?? l10n.notificationScheduleFailed,
      _ => l10n.remindersScheduling,
    };
    final onRetry = this.onRetry;
    final mark = failed
        ? HudaKhatamMark(color: scheme.error, size: 16)
        : HudaLampSpinner(
            size: 16,
            color: status == ReminderRowStatus.retrying
                ? tokens.ornament
                : scheme.primary,
          );
    final message = Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: failed ? scheme.error : scheme.onSurfaceVariant,
      ),
    );
    final action = failed && onRetry != null
        ? TextButton(onPressed: onRetry, child: Text(failure?.$2 ?? l10n.retry))
        : null;
    return Semantics(
      liveRegion: true,
      container: true,
      // A known cause is a sentence or two: its fix goes under it, so the
      // message keeps the row's width.
      child: failed && failure != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: mark,
                    ),
                    SizedBox(width: tokens.space.xs),
                    Expanded(child: message),
                  ],
                ),
                ?action,
              ],
            )
          : Row(
              children: [
                mark,
                SizedBox(width: tokens.space.xs),
                Expanded(child: message),
                ?action,
              ],
            ),
    );
  }
}

/// A reminder's schedule as a chip: tapping it changes that time (or the
/// interval) in place.
class ReminderTimeChip extends StatelessWidget {
  const ReminderTimeChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.schedule_rounded,
    this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The chip keeps its own button semantics (and tap action); only the
    // spoken label says what it changes.
    return ActionChip(
      avatar: Icon(icon, size: 18, color: scheme.primary),
      label: Text(label, semanticsLabel: semanticLabel),
      onPressed: onPressed,
    );
  }
}

/// "HH:mm" as saved by the cubit.
TimeOfDay parseReminderTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.tryParse(parts.first) ?? 0,
    minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
  );
}

String formatReminderTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// A saved time in the person's locale and 12/24-hour setting.
String localReminderTime(BuildContext context, String value) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      parseReminderTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
