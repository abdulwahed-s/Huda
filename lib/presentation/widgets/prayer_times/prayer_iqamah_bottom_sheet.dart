import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/services/prayer_iqamah_settings.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
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
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: PrayerPalette.of(context).page,
    showDragHandle: true,
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

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final numbers = NumberFormat.decimalPattern(l10n.localeName);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.prayerIqamahTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.prayerIqamahExplanation,
              style: TextStyle(color: palette.muted),
            ),
            const SizedBox(height: 16),
            for (final entry in _minutes.entries)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 4, 8),
                decoration: palette.cardDecoration(radius: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizedPrayerName(
                          l10n,
                          Prayer.values.byName(entry.key),
                        ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey('${entry.key}-minus'),
                      tooltip:
                          '${localizedPrayerName(l10n, Prayer.values.byName(entry.key))} −',
                      onPressed: _saving || entry.value == 0
                          ? null
                          : () => setState(
                              () => _minutes[entry.key] = entry.value - 1,
                            ),
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Flexible(
                      child: Text(
                        entry.value == 0
                            ? l10n.prayerIqamahOff
                            : '\u2068${l10n.prayerIqamahMinutes(numbers.format(entry.value))}\u2069',
                        key: ValueKey('${entry.key}-value'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: ValueKey('${entry.key}-plus'),
                      tooltip:
                          '${localizedPrayerName(l10n, Prayer.values.byName(entry.key))} +',
                      onPressed:
                          _saving ||
                              entry.value == PrayerIqamahSettings.maxMinutes
                          ? null
                          : () => setState(
                              () => _minutes[entry.key] = entry.value + 1,
                            ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            TextButton(
              onPressed: _saving
                  ? null
                  : () => setState(
                      () => _minutes = Map.of(PrayerIqamahSettings.defaults),
                    ),
              child: Text(l10n.prayerIqamahReset),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.prayerIqamahSaveError,
                  style: TextStyle(color: palette.error),
                ),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? l10n.saving : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
