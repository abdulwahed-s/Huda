import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/core/services/prayer_iqamah_settings.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_timeline_card.dart';
import 'package:intl/intl.dart';
import 'package:prayer_time_plus/prayer_time_plus.dart';

String iqamahSummary(PrayerIqamahSettings settings, AppLocalizations l10n) {
  final numbers = NumberFormat.decimalPattern(l10n.localeName);
  return settings
      .toMap()
      .entries
      .map((entry) {
        final name = localizedPrayerName(l10n, Prayer.values.byName(entry.key));
        final value = entry.value == 0
            ? l10n.prayerIqamahOff
            : l10n.prayerIqamahMinutes(numbers.format(entry.value));
        return '$name \u2068$value\u2069';
      })
      .join(' · ');
}

Future<void> showPrayerIqamahSheet(BuildContext context) async {
  final cubit = context.read<PrayerTimesCubit>();
  await showHudaSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.prayerIqamahTitle,
    builder: (_) => PrayerIqamahBottomSheet(
      settings: cubit.iqamahSettings,
      onSave: cubit.saveIqamahSettings,
    ),
  );
}

class PrayerIqamahBottomSheet extends StatefulWidget {
  const PrayerIqamahBottomSheet({
    super.key,
    required this.settings,
    required this.onSave,
  });

  final PrayerIqamahSettings settings;
  final Future<void> Function(PrayerIqamahSettings) onSave;

  @override
  State<PrayerIqamahBottomSheet> createState() =>
      _PrayerIqamahBottomSheetState();
}

class _PrayerIqamahBottomSheetState extends State<PrayerIqamahBottomSheet> {
  late Map<String, int> _minutes = widget.settings.toMap();
  bool _saving = false;
  bool _failed = false;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(PrayerIqamahSettings.sanitize(_minutes));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _set(String key, int value) {
    HudaHaptics.selection(context);
    setState(() => _minutes[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    String name(String key) =>
        localizedPrayerName(l10n, Prayer.values.byName(key));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.prayerIqamahExplanation,
          style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
        SizedBox(height: space.md),
        Card(
          child: Column(
            children: [
              for (final (i, entry) in _minutes.entries.indexed) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    space.md,
                    space.xxs,
                    space.xs,
                    space.xxs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name(entry.key),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      IconButton.outlined(
                        key: ValueKey('${entry.key}-minus'),
                        tooltip: '${name(entry.key)} −',
                        onPressed: _saving || entry.value == 0
                            ? null
                            : () => _set(entry.key, entry.value - 1),
                        icon: const Icon(Icons.remove_rounded, size: 20),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 88),
                        child: Text(
                          entry.value == 0
                              ? l10n.prayerIqamahOff
                              : '\u2068${l10n.prayerIqamahMinutes(numbers.format(entry.value))}\u2069',
                          key: ValueKey('${entry.key}-value'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: entry.value == 0
                                ? palette.muted
                                : palette.primary,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        key: ValueKey('${entry.key}-plus'),
                        tooltip: '${name(entry.key)} +',
                        onPressed:
                            _saving ||
                                entry.value == PrayerIqamahSettings.maxMinutes
                            ? null
                            : () => _set(entry.key, entry.value + 1),
                        icon: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: space.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _saving
                ? null
                : () => setState(
                    () => _minutes = Map.of(PrayerIqamahSettings.defaults),
                  ),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(l10n.prayerIqamahReset),
          ),
        ),
        if (_failed)
          Padding(
            padding: EdgeInsets.only(bottom: space.sm),
            child: PrayerStatusLine(
              status: HudaStatus.failed,
              message: l10n.prayerIqamahSaveError,
            ),
          ),
        SizedBox(height: space.xs),
        FilledButton(
          key: const ValueKey('prayer-iqamah-save'),
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(_saving ? l10n.saving : l10n.save),
        ),
      ],
    );
  }
}
