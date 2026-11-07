import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/services/color_to_int.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_time_picker.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_format.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:uuid/uuid.dart';

/// What the event sheet ended with.
sealed class EventSheetResult {
  const EventSheetResult();
}

class EventSaved extends EventSheetResult {
  const EventSaved(this.event);
  final HijriEvent event;
}

class EventDeleted extends EventSheetResult {
  const EventDeleted();
}

/// Adds an event to [dateLabel]'s day, or edits [event] (which can then
/// also be deleted). One sheet: title, notes, all day or a time range,
/// the reminder, and the color inline.
Future<EventSheetResult?> showEventSheet(
  BuildContext context, {
  required String dateLabel,
  HijriEvent? event,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<EventSheetResult>(
    context: context,
    title: event == null ? l10n.addEvent : l10n.editEvent,
    maxDialogWidth: 600,
    expand: true,
    builder: (_) => EventSheet(event: event, dateLabel: dateLabel),
  );
}

class EventSheet extends StatefulWidget {
  const EventSheet({super.key, this.event, required this.dateLabel});

  final HijriEvent? event;
  final String dateLabel;

  /// Event colors (the person's data, kept as they were).
  static const palette = <Color>[
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF2196F3),
    Color(0xFF039BE5),
    Color(0xFF00ACC1),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
    Color(0xFF6D4C41),
  ];

  @override
  State<EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<EventSheet> {
  late final _title = TextEditingController(text: widget.event?.title ?? '');
  late final _notes = TextEditingController(
    text: widget.event?.description ?? '',
  );
  late bool _allDay = widget.event?.isAllDay ?? true;
  late TimeOfDay? _start = widget.event?.startTime;
  late TimeOfDay? _end = widget.event?.endTime;
  late Color _color = widget.event != null
      ? Color(widget.event!.colorValue)
      : EventSheet.palette[5];
  late bool _notify = kIsWeb ? false : (widget.event?.notify ?? true);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Why the times can't be saved yet, if they can't.
  String? _timeProblem(AppLocalizations l10n) {
    if (_allDay) return null;
    if (_start == null) return l10n.startTimeRequired;
    if (_end == null) return l10n.endTimeRequired;
    final start = _start!.hour * 60 + _start!.minute;
    final end = _end!.hour * 60 + _end!.minute;
    if (end < start) return l10n.endTimeAfterStart;
    return null;
  }

  Future<void> _pick({required bool start}) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showHudaTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? _start ?? TimeOfDay.now(),
      title: start ? l10n.startTime : l10n.endTime,
    );
    if (picked == null || !mounted) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _setNotify(bool value) async {
    if (value &&
        !await PermissionHandlers.requestNotificationPermission(context)) {
      return;
    }
    if (!mounted) return;
    HudaHaptics.selection(context);
    setState(() => _notify = value);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    if (_notify &&
        !await PermissionHandlers.requestNotificationPermission(context)) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      EventSaved(
        HijriEvent(
          id: widget.event?.id ?? const Uuid().v4(),
          title: _title.text.trim(),
          description: _notes.text.trim(),
          startTime: _allDay ? null : _start,
          endTime: _allDay ? null : _end,
          isAllDay: _allDay,
          colorValue: colorToInt(_color),
          notify: _notify,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final format = CalendarFormat.of(context);
    final problem = _timeProblem(l10n);
    final canSave = _title.text.trim().isNotEmpty && problem == null;
    final editing = widget.event != null;
    final colors = [
      if (!EventSheet.palette.any((c) => c.toARGB32() == _color.toARGB32()))
        _color,
      ...EventSheet.palette,
    ];

    Widget timeButton({required bool start}) {
      final value = start ? _start : _end;
      final label = start ? l10n.startPrefix : l10n.endPrefix;
      return OutlinedButton.icon(
        key: ValueKey(start ? 'event-start' : 'event-end'),
        onPressed: () => _pick(start: start),
        icon: const Icon(Icons.schedule_rounded),
        label: Text(
          value == null
              ? (start ? l10n.startTime : l10n.endTime)
              : '$label · ${format.time(value)}',
        ),
      );
    }

    final insets = MediaQuery.paddingOf(context);
    final title = editing ? l10n.editEvent : l10n.addEvent;

    return Column(
      key: const ValueKey('calendar-event-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: what this is, for which day, and Close.
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            space.xl + insets.left,
            space.sm,
            space.xs + insets.right,
            space.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                    Text(
                      widget.dateLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              space.xl + insets.left,
              space.xs,
              space.xl + insets.right,
              space.lg,
            ),
            children: [
              TextField(
                key: const ValueKey('event-title'),
                controller: _title,
                autofocus: !editing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.eventTitle),
              ),
              SizedBox(height: space.sm),
              TextField(
                controller: _notes,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              SizedBox(height: space.sm),
              _SwitchRow(
                key: const ValueKey('event-all-day'),
                icon: Icons.wb_sunny_outlined,
                title: l10n.allDayEvent,
                value: _allDay,
                onChanged: (value) {
                  HudaHaptics.selection(context);
                  setState(() => _allDay = value);
                },
              ),
              HudaStateSwitcher(
                stateKey: _allDay,
                child: _allDay
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.only(bottom: space.xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: space.xs,
                              runSpacing: space.xs,
                              children: [
                                timeButton(start: true),
                                timeButton(start: false),
                              ],
                            ),
                            if (problem != null &&
                                (_start != null || _end != null))
                              Padding(
                                padding: EdgeInsets.only(top: space.xs),
                                child: Text(
                                  problem,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.error,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              if (!kIsWeb)
                _SwitchRow(
                  key: const ValueKey('event-notify'),
                  icon: Icons.notifications_none_rounded,
                  title: l10n.receiveNotification,
                  subtitle: l10n.getNotifiedAboutEvent,
                  value: _notify,
                  onChanged: _setNotify,
                ),
              SizedBox(height: space.sm),
              Text(l10n.calendarEventColor, style: theme.textTheme.titleSmall),
              SizedBox(height: space.xs),
              Wrap(
                spacing: space.xxs,
                runSpacing: space.xxs,
                children: [
                  for (final color in colors)
                    _Swatch(
                      color: color,
                      selected: color.toARGB32() == _color.toARGB32(),
                      onTap: () {
                        HudaHaptics.selection(context);
                        setState(() => _color = color);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        // Pinned: its surface reaches the edge, its buttons sit above the
        // navigation bar, so Save is always in reach.
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              space.md + insets.left,
              space.sm,
              space.md + insets.right,
              space.sm + insets.bottom,
            ),
            child: Row(
              children: [
                if (editing)
                  TextButton.icon(
                    key: const ValueKey('event-delete'),
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    onPressed: () =>
                        Navigator.of(context).pop(const EventDeleted()),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.delete),
                  ),
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('event-save'),
                  onPressed: canSave && !_saving ? _save : null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(editing ? l10n.saveChanges : l10n.saveEvent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: HudaSettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: AppLocalizations.of(context)!.calendarEventColor,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedContainer(
              duration: tokens.motion.of(context, tokens.motion.short),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.onSurface : Colors.transparent,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
