import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/services/prayer_audio_library.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sound_page.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class PrayerSoundSection extends StatelessWidget {
  const PrayerSoundSection({
    super.key,
    required this.settings,
    required this.capabilities,
    this.prayer,
  });

  final PrayerAlertSettings settings;
  final PrayerAlertCapabilities capabilities;
  final String? prayer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = PrayerAlertScope.of(context);
    final palette = PrayerPalette.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final own = prayer == null ? null : settings.prayers[prayer];
    final reciterId = own?.reciterId ?? settings.reciterId;
    final reciter = scope.library.reciter(reciterId);
    final status = scope.library.status(reciterId);
    final tuning = own?.tuning ?? const <String, Object?>{};
    final ownVolume = tuning['volumeGain'] as num?;
    final ownOpening = tuning['opening'] == true;
    final ownLength = tuning.containsKey('stopAfterSeconds') || ownOpening;
    final opening = own?.openingOnly ?? settings.openingOnly;
    final volume = (ownVolume ?? settings.volume).toDouble();
    final length = ownLength
        ? (tuning['stopAfterSeconds'] as num?)?.toInt()
        : settings.stopAfterSeconds;
    final tuningHere = prayer == null || capabilities.perPrayerTuning;
    final lengthHere =
        capabilities.length &&
        (prayer == null || capabilities.perPrayerLength) &&
        PrayerAlertCapabilities.playsForLength(
          own?.style ?? settings.style,
          focusAudio: settings.focusAudio,
        );
    String number(int value) => prayerAlertNumber(context, value);
    return PrayerAlertSection(
      title: l10n.prayerAlertSectionSound,
      children: [
        PrayerSettingRow(
          key: const ValueKey('prayer-alert-recording'),
          icon: Icons.graphic_eq_rounded,
          title: l10n.prayerAlertRecording,
          subtitle: [
            reciter?.name(locale) ?? '…',
            if (own != null && !own.ownReciter) l10n.prayerAlertSameAsAll,
            if (status.state == PrayerSoundState.downloading)
              l10n.prayerAlertSoundDownloading(
                ((status.progress ?? 0) * 100).round(),
              ),
          ].join(' · '),
          subtitleColor: own?.ownReciter == true ? palette.primary : null,
          onTap: () => scope.push(PrayerAlertSoundPage(prayer: prayer)),
        ),
        if (capabilities.volume && tuningHere)
          PrayerVolumeRow(
            value: volume,
            inherited: prayer != null && ownVolume == null,
            onChanged: (value) => scope.controller.edit(
              SetPrayerAlertVolume(value, prayer: prayer),
            ),
            onInherit: prayer == null
                ? null
                : () => scope.controller.edit(
                    SetPrayerAlertVolume(null, prayer: prayer),
                  ),
          ),
        if (lengthHere)
          PrayerControlRow(
            title: l10n.prayerAlertLength,
            child: PrayerSegmented<Object?>(
              key: const ValueKey('prayer-alert-length'),
              options: [
                if (prayer != null) const _Inherit(),
                if (capabilities.lengthOpening) const _Opening(),
                ...capabilities.lengths,
                if (!capabilities.lengths.contains(length) &&
                    length != null &&
                    length < 3600)
                  length,
              ],
              selected: prayer != null && !ownLength
                  ? const _Inherit()
                  : opening
                  ? const _Opening()
                  : (length != null && length >= 3600 ? null : length),
              label: (option) => switch (option) {
                _Inherit() => l10n.prayerAlertDefault,
                _Opening() => l10n.prayerAlertLengthOpening,
                _ => l10n.alertLength(option as int?, number),
              },
              onSelected: (option) => scope.controller.edit(switch (option) {
                _Inherit() => SetPrayerAlertLength(
                  null,
                  prayer: prayer,
                  inherit: true,
                ),
                _Opening() => SetPrayerAlertLength(
                  null,
                  prayer: prayer,
                  opening: true,
                ),
                _ => SetPrayerAlertLength(option as int?, prayer: prayer),
              }),
            ),
          ),
      ],
    );
  }
}

class _Inherit {
  const _Inherit();

  @override
  bool operator ==(Object other) => other is _Inherit;

  @override
  int get hashCode => 0;
}

class _Opening {
  const _Opening();

  @override
  bool operator ==(Object other) => other is _Opening;

  @override
  int get hashCode => 1;
}

class PrayerVolumeRow extends StatefulWidget {
  const PrayerVolumeRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.inherited = false,
    this.onInherit,
  });

  final double value;
  final bool inherited;
  final ValueChanged<double> onChanged;
  final VoidCallback? onInherit;

  @override
  State<PrayerVolumeRow> createState() => _PrayerVolumeRowState();
}

class _PrayerVolumeRowState extends State<PrayerVolumeRow> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final library = PrayerAlertScope.of(context).library;
    final value = _dragging ?? widget.value;
    final percent = prayerAlertNumber(context, (value * 100).round());
    return PrayerControlRow(
      title: l10n.prayerAlertVolume,
      value: widget.inherited ? l10n.prayerAlertDefault : '$percent%',
      child: Row(
        children: [
          const Icon(Icons.volume_down_rounded, size: 20),
          Expanded(
            child: Slider.adaptive(
              key: const ValueKey('prayer-alert-volume'),
              value: value.clamp(0, 1),
              divisions: 20,
              label: '$percent%',
              onChanged: (next) {
                setState(() => _dragging = next);
                library.setPreviewVolume(next);
              },
              onChangeEnd: (next) {
                setState(() => _dragging = null);
                widget.onChanged(next);
              },
            ),
          ),
          const Icon(Icons.volume_up_rounded, size: 20),
          if (widget.onInherit != null && !widget.inherited)
            IconButton(
              tooltip: l10n.prayerAlertDefault,
              onPressed: widget.onInherit,
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
            ),
        ],
      ),
    );
  }
}
