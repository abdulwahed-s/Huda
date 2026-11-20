import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/notification_delivery_check.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_time_picker.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/notifications/reminder_row.dart';
import 'package:intl/intl.dart' as intl;

Future<int?> showReminderFrequencySheet(BuildContext context, int current) {
  return showHudaSheet<int>(
    context: context,
    title: AppLocalizations.of(context)!.athkarFrequency,
    maxDialogWidth: 480,
    builder: (context) => _FrequencySheet(current: current),
  );
}

class _FrequencySheet extends StatefulWidget {
  const _FrequencySheet({required this.current});

  final int current;

  @override
  State<_FrequencySheet> createState() => _FrequencySheetState();
}

class _FrequencySheetState extends State<_FrequencySheet> {
  static const _presets = [30, 60, 120, 180];
  late final _controller = TextEditingController(
    text: _presets.contains(widget.current) ? '' : '${widget.current}',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _choose(int minutes) {
    HudaHaptics.selection(context);
    Navigator.of(context).pop(minutes);
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 10 || value > 1440) {
      setState(() => _error = AppLocalizations.of(context)!.validNumberMinutes);
      return;
    }
    _choose(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digits = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.howOftenReceiveAthkar,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.md),
        Wrap(
          spacing: space.xs,
          runSpacing: space.xs,
          children: [
            for (final minutes in _presets)
              ChoiceChip(
                key: ValueKey('reminder-frequency-$minutes'),
                label: Text('${digits.format(minutes)} ${l10n.minutesUnit}'),
                selected: widget.current == minutes,
                onSelected: (_) => _choose(minutes),
              ),
          ],
        ),
        SizedBox(height: space.xs),
        Text(
          l10n.recommendedMinutes,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.lg),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l10n.minutes,
            hintText: l10n.minutesExample,
            errorText: _error,
            suffixText: l10n.minutesUnit,
            prefixIcon: const Icon(Icons.repeat_rounded),
          ),
        ),
        SizedBox(height: space.md),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(onPressed: _save, child: Text(l10n.save)),
        ),
      ],
    );
  }
}

Future<void> showSahurSheet(
  BuildContext context,
  NotificationsCubit cubit, {
  DateTime Function() clock = DateTime.now,
}) {
  final page = context;
  return showHudaSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.sahurAlarmTitle,
    maxDialogWidth: 520,
    builder: (context) => BlocProvider.value(
      value: cubit,
      child: _SahurSheet(page: page, clock: clock),
    ),
  );
}

class _SahurSheet extends StatefulWidget {
  const _SahurSheet({required this.page, required this.clock});

  final BuildContext page;
  final DateTime Function() clock;

  @override
  State<_SahurSheet> createState() => _SahurSheetState();
}

class _SahurSheetState extends State<_SahurSheet> {
  int? _dragging;

  TimeOfDay? _pending;
  Timer? _settle;

  bool _scheduling = false;

  int _wheels = 0;

  late final NotificationsCubit _cubit;
  late String _failed;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<NotificationsCubit>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _failed = AppLocalizations.of(context)!.notificationScheduleFailed;
  }

  @override
  void dispose() {
    _settle?.cancel();
    final pending = _pending;
    if (pending != null) {
      _save(() => _cubit.setSahurExactTime(formatReminderTime(pending)));
    }
    super.dispose();
  }

  Future<bool> _save(Future<void> Function() save) async {
    try {
      await save();
      return true;
    } on NotificationNotScheduledException {
      final page = widget.page;
      if (page.mounted) {
        showHudaToast(page, message: _failed, kind: HudaToastKind.failed);
      }
      return false;
    }
  }

  void _exactChanged(TimeOfDay time) {
    _pending = time;
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 600), _saveExact);
  }

  Future<void> _saveExact() async {
    _settle?.cancel();
    final time = _pending;
    if (time == null) return;
    _pending = null;
    setState(() => _scheduling = true);
    final saved = await _save(
      () => _cubit.setSahurExactTime(formatReminderTime(time)),
    );
    if (!mounted) return;
    setState(() {
      _scheduling = false;
      if (!saved) _wheels++;
    });
  }

  Future<void> _done() async {
    if (_pending != null) await _saveExact();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final cubit = context.read<NotificationsCubit>();
    final state = context.watch<NotificationsCubit>().state;
    if (state is! NotificationPreferencesLoaded) return const SizedBox();
    final exact = state.sahurAlarmType == 0;
    final minutes =
        _dragging ?? state.sahurMinutesBeforeFajr.clamp(10, 150).toInt();
    final digits = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final saved = parseReminderTime(state.sahurExactTime);
    final short = MediaQuery.sizeOf(context).height < 560;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.sahurNotificationOnly
              ? l10n.sahurNotificationOnlyDescription
              : l10n.sahurAlarmDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.md),
        _ChoiceTile(
          key: const ValueKey('sahur-exact'),
          selected: exact,
          title: l10n.exactTime,
          onTap: () {
            if (exact) return;
            HudaHaptics.selection(context);
            _save(() => cubit.setSahurAlarmType(0));
          },
          child: exact
              ? _ExactTime(
                  key: ValueKey('sahur-wheels-$_wheels'),
                  initialTime: _pending ?? saved,
                  clock: widget.clock,
                  scheduling: _scheduling,
                  short: short,
                  onChanged: _exactChanged,
                )
              : null,
        ),
        SizedBox(height: space.xs),
        _ChoiceTile(
          key: const ValueKey('sahur-before-fajr'),
          selected: !exact,
          title: l10n.minutesBeforeFajr,
          trailing: exact
              ? null
              : Text(
                  '${digits.format(minutes)} ${l10n.minutesUnit}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
          onTap: () {
            if (!exact) return;
            HudaHaptics.selection(context);
            _save(() => cubit.setSahurAlarmType(1));
          },
          child: exact
              ? null
              : Slider(
                  value: minutes.toDouble(),
                  min: 10,
                  max: 150,
                  divisions: 28,
                  label: '${digits.format(minutes)} ${l10n.minutesUnit}',
                  onChanged: (value) {
                    if (value.round() != minutes) {
                      HudaHaptics.selection(context);
                    }
                    setState(() => _dragging = value.round());
                  },
                  onChangeEnd: (value) async {
                    await _save(
                      () => cubit.setSahurMinutesBeforeFajr(value.round()),
                    );
                    if (mounted) setState(() => _dragging = null);
                  },
                ),
        ),
        SizedBox(height: space.lg),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(onPressed: _done, child: Text(l10n.done)),
        ),
      ],
    );
  }
}

class _ExactTime extends StatefulWidget {
  const _ExactTime({
    super.key,
    required this.initialTime,
    required this.clock,
    required this.scheduling,
    required this.short,
    required this.onChanged,
  });

  final TimeOfDay initialTime;
  final DateTime Function() clock;
  final bool scheduling;
  final bool short;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<_ExactTime> createState() => _ExactTimeState();
}

class _ExactTimeState extends State<_ExactTime> {
  late TimeOfDay _time = widget.initialTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final status = widget.scheduling
        ? Semantics(
            key: const ValueKey('scheduling'),
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HudaLampSpinner(size: 16, color: theme.colorScheme.primary),
                SizedBox(width: space.xs),
                Flexible(
                  child: Text(
                    l10n.remindersScheduling,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        : HudaNextTime(
            key: const ValueKey('next'),
            time: _time,
            clock: widget.clock,
            textAlign: TextAlign.center,
          );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        end: 20 + space.sm - space.xs,
        top: space.xs,
        bottom: space.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.short) ...[
            HudaDayPath(time: _time, height: 36),
            SizedBox(height: space.xs),
          ],
          HudaTimePicker(
            initialTime: widget.initialTime,
            visibleItems: 3,
            onChanged: (time) {
              setState(() => _time = time);
              widget.onChanged(time);
            },
          ),
          SizedBox(height: space.sm),
          HudaStateSwitcher(
            stateKey: widget.scheduling,
            sequential: true,
            child: status,
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.selected,
    required this.title,
    required this.onTap,
    this.trailing,
    this.child,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(tokens.radius.md);
    final trailing = this.trailing;
    final child = this.child;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: tokens.motion.of(context, tokens.motion.short),
        curve: tokens.motion.standard,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: selected
              ? scheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? tokens.stroke.fine : tokens.stroke.hairline,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: space.sm,
                  vertical: space.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        SizedBox(width: space.sm),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: space.xs),
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        if (trailing != null) ...[
                          SizedBox(width: space.xs),
                          trailing,
                        ],
                      ],
                    ),
                    if (child != null)
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 20 + space.sm - space.xs,
                        ),
                        child: child,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
