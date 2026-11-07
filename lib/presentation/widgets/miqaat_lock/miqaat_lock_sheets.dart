import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_state.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_search_field.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_time_picker.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_format.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_sections.dart';
import 'package:uuid/uuid.dart';

/// Cancel and the lit confirm, pinned under a sheet's content.
Widget _actions(
  BuildContext context, {
  required String confirm,
  required VoidCallback? onConfirm,
}) {
  final l10n = AppLocalizations.of(context)!;
  final space = context.tokens.space;
  return Wrap(
    alignment: WrapAlignment.end,
    spacing: space.sm,
    runSpacing: space.xs,
    children: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.cancel),
      ),
      FilledButton(onPressed: onConfirm, child: Text(confirm)),
    ],
  );
}

// ---------------------------------------------------------------- Apps

/// Chooses the apps to lock (Android). Returns the chosen apps, or null
/// when cancelled.
Future<List<LockedApp>?> showMiqaatAppsSheet(
  BuildContext context, {
  required MiqaatLockCubit cubit,
  required List<LockedApp> current,
}) {
  final state = cubit.state;
  if (state is MiqaatLockLoaded && state.installedApps.isEmpty) {
    cubit.loadInstalledApps();
  }
  final selected = ValueNotifier<Set<String>>({
    for (final app in current) app.packageId,
  });
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<List<LockedApp>>(
    context: context,
    title: l10n.selectApps,
    sideSheet: true,
    builder: (context) => BlocProvider.value(
      value: cubit,
      child: _AppsChooser(selected: selected),
    ),
    footer: (context) => ValueListenableBuilder<Set<String>>(
      valueListenable: selected,
      builder: (context, chosen, _) => _actions(
        context,
        confirm: l10n.done,
        onConfirm: () {
          final s = cubit.state;
          final installed = s is MiqaatLockLoaded ? s.installedApps : [];
          final apps = [
            // Keep the order apps were locked in, then the new ones.
            for (final app in current)
              if (chosen.contains(app.packageId)) app,
            for (final id in chosen)
              if (!current.any((a) => a.packageId == id))
                installed.cast<LockedApp>().firstWhere(
                  (a) => a.packageId == id,
                  orElse: () => LockedApp(packageId: id, appName: id),
                ),
          ];
          Navigator.of(context).pop(apps);
        },
      ),
    ),
  );
}

class _AppsChooser extends StatefulWidget {
  const _AppsChooser({required this.selected});

  final ValueNotifier<Set<String>> selected;

  @override
  State<_AppsChooser> createState() => _AppsChooserState();
}

class _AppsChooserState extends State<_AppsChooser> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    final next = {...widget.selected.value};
    next.contains(id) ? next.remove(id) : next.add(id);
    widget.selected.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final state = context.watch<MiqaatLockCubit>().state;
    final loaded = state is MiqaatLockLoaded ? state : null;

    final Widget body;
    if (loaded == null || loaded.isLoadingApps) {
      body = HudaSkeleton(
        label: l10n.loadingApps,
        child: Column(
          children: [
            for (var i = 0; i < 6; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: space.xs),
                child: Row(
                  children: [
                    const HudaSkeletonBlock(width: 38, height: 38),
                    SizedBox(width: space.md),
                    const Expanded(child: HudaSkeletonLines(lines: 1)),
                  ],
                ),
              ),
          ],
        ),
      );
    } else if (loaded.installedApps.isEmpty) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: space.xl),
        child: Column(
          children: [
            const HudaLamp(child: Icon(Icons.apps_rounded)),
            SizedBox(height: space.md),
            Text(
              l10n.noAppsFound,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: space.md),
            HudaRetryButton(
              onRetry: () =>
                  context.read<MiqaatLockCubit>().loadInstalledApps(),
              filled: false,
            ),
          ],
        ),
      );
    } else {
      final q = _query.toLowerCase();
      final apps = loaded.installedApps
          .where(
            (a) =>
                a.appName.toLowerCase().contains(q) ||
                a.packageId.toLowerCase().contains(q),
          )
          .toList();
      body = ValueListenableBuilder<Set<String>>(
        valueListenable: widget.selected,
        builder: (context, chosen, _) => Column(
          children: [
            for (final app in apps)
              MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                child: CheckboxListTile(
                  key: ValueKey('miqaat-choose-${app.packageId}'),
                  value: chosen.contains(app.packageId),
                  onChanged: (_) => _toggle(app.packageId),
                  secondary: MiqaatAppIcon(app),
                  title: Text(app.appName),
                  subtitle: Text(
                    app.packageId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loaded != null && loaded.installedApps.isNotEmpty) ...[
          HudaSearchField(
            controller: _search,
            hintText: l10n.searchApps,
            onChanged: (v) => setState(() => _query = v),
          ),
          SizedBox(height: space.sm),
        ],
        HudaStateSwitcher(
          stateKey: loaded == null || loaded.isLoadingApps
              ? 'loading'
              : loaded.installedApps.isEmpty
              ? 'empty'
              : 'apps',
          child: body,
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- Window

/// Adds or edits a time window. Returns the window, or null when
/// cancelled.
Future<TimeSlot?> showMiqaatWindowSheet(
  BuildContext context, {
  TimeSlot? existing,
}) {
  final l10n = AppLocalizations.of(context)!;
  final draft = _WindowDraft(existing);
  return showHudaSheet<TimeSlot>(
    context: context,
    title: existing == null ? l10n.addTimeSlot : l10n.editTimeSlot,
    builder: (context) => _WindowEditor(draft: draft),
    footer: (context) => _actions(
      context,
      confirm: l10n.save,
      onConfirm: () => Navigator.of(context).pop(draft.build()),
    ),
  );
}

class _WindowDraft extends ChangeNotifier {
  _WindowDraft(this.existing)
    : start = existing?.startTime ?? const TimeOfDay(hour: 5, minute: 0),
      end = existing?.endTime ?? const TimeOfDay(hour: 6, minute: 0),
      weekdays = {...?existing?.weekdays},
      label = TextEditingController(text: existing?.label ?? '');

  final TimeSlot? existing;
  TimeOfDay start;
  TimeOfDay end;
  final Set<int> weekdays;
  final TextEditingController label;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  TimeSlot build() => TimeSlot(
    id: existing?.id ?? const Uuid().v4(),
    startTime: start,
    endTime: end,
    weekdays: weekdays.toList()..sort(),
    label: label.text.trim().isEmpty ? null : label.text.trim(),
  );
}

class _WindowEditor extends StatelessWidget {
  const _WindowEditor({required this.draft});

  final _WindowDraft draft;

  Future<void> _pick(BuildContext context, {required bool start}) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showHudaTimePicker(
      context: context,
      initialTime: start ? draft.start : draft.end,
      title: start ? l10n.startTime : l10n.endTime,
    );
    if (picked == null) return;
    draft.update(() => start ? draft.start = picked : draft.end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget time(String key, String label, TimeOfDay value, bool start) =>
        HudaCard(
          key: ValueKey('miqaat-window-$key'),
          onTap: () => _pick(context, start: start),
          padding: EdgeInsets.all(space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: space.xxs),
              Text(miqaatTime(context, value), style: text.headlineSmall),
            ],
          ),
        );

    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: draft.label,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.label,
              hintText: l10n.labelHint,
            ),
          ),
          SizedBox(height: space.lg),
          HudaEyebrow(l10n.timeRange),
          SizedBox(height: space.xs),
          LayoutBuilder(
            builder: (context, c) {
              final a = time('start', l10n.startTime, draft.start, true);
              final b = time('end', l10n.endTime, draft.end, false);
              if (c.maxWidth <
                  300 * MediaQuery.textScalerOf(context).scale(1)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    a,
                    SizedBox(height: space.xs),
                    b,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: a),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: space.xs),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(child: b),
                ],
              );
            },
          ),
          SizedBox(height: space.lg),
          HudaEyebrow(l10n.repeatOn),
          SizedBox(height: space.xxs),
          Text(
            l10n.leaveEmptyForEveryday,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: space.sm),
          Wrap(
            spacing: space.xs,
            runSpacing: space.xs,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  key: ValueKey('miqaat-day-$d'),
                  label: Text(miqaatWeekday(context, d)),
                  selected: draft.weekdays.contains(d),
                  showCheckmark: false,
                  onSelected: (on) {
                    HudaHaptics.selection(context);
                    draft.update(
                      () =>
                          on ? draft.weekdays.add(d) : draft.weekdays.remove(d),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Goal

/// Any goal from 1 to 120 minutes. Returns the minutes, or null.
Future<int?> showMiqaatGoalSheet(BuildContext context, {required int current}) {
  final l10n = AppLocalizations.of(context)!;
  final value = ValueNotifier<int>(current);
  return showHudaSheet<int>(
    context: context,
    title: l10n.customDuration,
    builder: (context) => ValueListenableBuilder<int>(
      valueListenable: value,
      builder: (context, minutes, _) {
        final space = context.tokens.space;
        final text = Theme.of(context).textTheme;
        return Column(
          children: [
            HudaNumberRoll(
              value: minutes,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Text(l10n.minutes, style: text.labelLarge),
            SizedBox(height: space.md),
            Slider(
              value: minutes.toDouble(),
              min: MiqaatLockSettings.minCustomDuration.toDouble(),
              max: MiqaatLockSettings.maxCustomDuration.toDouble(),
              divisions:
                  MiqaatLockSettings.maxCustomDuration -
                  MiqaatLockSettings.minCustomDuration,
              label: l10n.miqaatMinutesShort(minutes),
              onChanged: (v) {
                if (v.round() != value.value) HudaHaptics.selection(context);
                value.value = v.round();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.miqaatMinutesShort(MiqaatLockSettings.minCustomDuration),
                  style: text.bodySmall,
                ),
                Text(
                  l10n.miqaatMinutesShort(MiqaatLockSettings.maxCustomDuration),
                  style: text.bodySmall,
                ),
              ],
            ),
          ],
        );
      },
    ),
    footer: (context) => _actions(
      context,
      confirm: l10n.confirm,
      onConfirm: () => Navigator.of(context).pop(value.value),
    ),
  );
}

// ------------------------------------------------------- Accessibility

/// Explains the accessibility service before Android's settings open.
/// True when the person agrees.
Future<bool?> showMiqaatAccessibilitySheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<bool>(
    context: context,
    title: l10n.accessibilityServiceRequiredDialogTitle,
    builder: (context) {
      final space = context.tokens.space;
      final text = Theme.of(context).textTheme;
      final scheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: HudaLamp(child: Icon(Icons.accessibility_new_rounded)),
          ),
          SizedBox(height: space.md),
          Text(
            l10n.accessibilityServiceRequiredDialogDesc,
            style: text.bodyLarge,
          ),
          SizedBox(height: space.md),
          HudaCard(
            padding: EdgeInsets.all(space.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: scheme.primary),
                SizedBox(width: space.sm),
                Expanded(
                  child: Text(
                    l10n.accessibilityServiceRequiredDialogPrivacy,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
    footer: (context) => _actions(
      context,
      confirm: l10n.agree,
      onConfirm: () => Navigator.of(context).pop(true),
    ),
  );
}
