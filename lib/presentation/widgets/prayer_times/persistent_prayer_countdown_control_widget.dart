import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/core/services/android_prayer_countdown.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/notifications/permission_handlers.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

/// The Android prayer countdown card in "On this device". The countdown itself
/// runs natively; this card saves the user's choices and shows what Android
/// reports, including problems only the user can fix.
class PersistentPrayerCountdownControlWidget extends StatefulWidget {
  const PersistentPrayerCountdownControlWidget({super.key});

  @override
  State<PersistentPrayerCountdownControlWidget> createState() =>
      _PersistentPrayerCountdownControlWidgetState();
}

class _PersistentPrayerCountdownControlWidgetState
    extends State<PersistentPrayerCountdownControlWidget>
    with WidgetsBindingObserver {
  PrayerCountdownSettings? _settings;
  PrayerCountdownStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have changed notification settings in Android.
    if (state == AppLifecycleState.resumed) unawaited(_refreshStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await AndroidPrayerCountdown.load();
    if (mounted) setState(() => _settings = settings);
    await _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await AndroidPrayerCountdown.status();
      if (mounted) setState(() => _status = status);
    } catch (error) {
      debugPrint('Prayer countdown status failed: $error');
    }
  }

  Future<void> _save(PrayerCountdownSettings next) async {
    final previous = _settings;
    if (previous == null || _busy) return;
    if (next.enabled &&
        !previous.enabled &&
        !await PermissionHandlers.requestNotificationPermission(context)) {
      return;
    }
    setState(() {
      _settings = next;
      _busy = true;
    });
    try {
      final status = await AndroidPrayerCountdown.save(next);
      if (mounted) setState(() => _status = status);
    } catch (error) {
      debugPrint('Prayer countdown save failed: $error');
      if (!mounted) return;
      setState(() => _settings = previous);
      HudaSnackBar.error(
        context,
        message: AppLocalizations.of(context)!.prayerCountdownSaveFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final palette = PrayerPalette.of(context);
    final settings = _settings;
    final enabled = settings?.enabled ?? false;
    final problem = enabled ? _problem(l10n) : null;

    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const HudaIconMark(Icons.timer_outlined),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.prayerCountdownTitle,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusText(l10n, enabled),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: !enabled
                              ? palette.muted
                              : problem != null
                              ? palette.warning
                              : colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: settings == null || _busy
                      ? null
                      : (value) => _save(settings.copyWith(enabled: value)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.prayerCountdownDescription,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            if (problem != null) ...[
              const SizedBox(height: 10),
              _ProblemBanner(
                problem: problem,
                onOpenSettings: problem.target == null
                    ? null
                    : () =>
                          AndroidPrayerCountdown.openSettings(problem.target!),
              ),
            ],
            if (settings != null && enabled) ...[
              const SizedBox(height: 14),
              Text(
                l10n.prayerCountdownStyle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final style in PrayerCountdownStyle.values) ...[
                    if (style != PrayerCountdownStyle.values.first)
                      const SizedBox(width: 8),
                    Expanded(
                      child: _StyleChoice(
                        style: style,
                        label: _styleLabel(l10n, style),
                        selected: settings.style == style,
                        onTap: _busy || settings.style == style
                            ? null
                            : () => _save(settings.copyWith(style: style)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              _option(
                l10n.prayerCountdownLockScreen,
                settings.lockScreen,
                (value) => _save(settings.copyWith(lockScreen: value)),
              ),
              if (settings.style == PrayerCountdownStyle.timetable)
                _option(
                  l10n.prayerCountdownShowSunrise,
                  settings.showSunrise,
                  (value) => _save(settings.copyWith(showSunrise: value)),
                )
              else if (_status?.liveUpdateSupported ?? false)
                _option(
                  l10n.prayerCountdownLiveUpdate,
                  settings.liveUpdate,
                  (value) => _save(settings.copyWith(liveUpdate: value)),
                  subtitle: l10n.prayerCountdownLiveUpdateHint,
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText(AppLocalizations l10n, bool enabled) {
    if (!enabled) return l10n.prayerCountdownOff;
    if (_status?.posted ?? false) return l10n.prayerCountdownShowing;
    return l10n.prayerCountdownNotShowing;
  }

  /// The first thing stopping the countdown from showing as the user chose.
  _CountdownProblem? _problem(AppLocalizations l10n) {
    final status = _status;
    final settings = _settings;
    if (status == null || settings == null) return null;
    if (!status.notificationsAllowed) {
      return _CountdownProblem(
        l10n.prayerCountdownNotificationsOff,
        PrayerCountdownSettingsTarget.app,
      );
    }
    if (status.channelBlocked) {
      return _CountdownProblem(
        l10n.prayerCountdownChannelOff,
        PrayerCountdownSettingsTarget.channel,
      );
    }
    if (!status.hasLocation) {
      return _CountdownProblem(l10n.prayerCountdownNeedsLocation, null);
    }
    if (settings.style != PrayerCountdownStyle.timetable &&
        settings.liveUpdate &&
        status.liveUpdateSupported &&
        !status.liveUpdateAllowed) {
      return _CountdownProblem(
        l10n.prayerCountdownLiveUpdateOff,
        PrayerCountdownSettingsTarget.liveUpdate,
      );
    }
    return null;
  }

  String _styleLabel(AppLocalizations l10n, PrayerCountdownStyle style) =>
      switch (style) {
        PrayerCountdownStyle.progress => l10n.prayerCountdownStyleProgress,
        PrayerCountdownStyle.timetable => l10n.prayerCountdownStyleTimetable,
        PrayerCountdownStyle.minimal => l10n.prayerCountdownStyleMinimal,
      };

  Widget _option(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    subtitle: subtitle == null
        ? null
        : Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PrayerPalette.of(context).muted,
            ),
          ),
    value: value,
    onChanged: _busy ? null : onChanged,
  );
}

class _CountdownProblem {
  const _CountdownProblem(this.message, this.target);

  final String message;
  final PrayerCountdownSettingsTarget? target;
}

class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.problem, required this.onOpenSettings});

  final _CountdownProblem problem;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: palette.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              problem.message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
          ),
          if (onOpenSettings != null)
            TextButton(
              onPressed: onOpenSettings,
              child: Text(AppLocalizations.of(context)!.openSettings),
            ),
        ],
      ),
    );
  }
}

/// A style choice with a small sketch of how the notification looks.
class _StyleChoice extends StatelessWidget {
  const _StyleChoice({
    required this.style,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final PrayerCountdownStyle style;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = PrayerPalette.of(context);
    final line = palette.muted.withValues(alpha: 0.35);

    Widget bar(double widthFactor, {Color? color, double height = 4}) =>
        FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: widthFactor,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color ?? line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );

    final sketch = switch (style) {
      PrayerCountdownStyle.minimal => [
        bar(0.75, color: palette.ink.withValues(alpha: 0.55)),
        const SizedBox(height: 5),
        bar(0.4),
      ],
      PrayerCountdownStyle.progress => [
        bar(0.7, color: palette.ink.withValues(alpha: 0.55)),
        const SizedBox(height: 5),
        bar(0.45),
        const SizedBox(height: 7),
        Stack(
          children: [
            bar(1, height: 5),
            bar(0.35, color: colors.primary, height: 5),
          ],
        ),
      ],
      PrayerCountdownStyle.timetable => [
        Row(
          children: [
            Expanded(child: bar(0.8, color: colors.primary)),
            const SizedBox(width: 6),
            Expanded(child: bar(0.6)),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: i == 1 ? colors.primary : line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    };

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.10)
            : palette.cardRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.primary : palette.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 34,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: sketch,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? colors.primary : palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
