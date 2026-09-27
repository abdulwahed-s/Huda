import 'package:flutter/material.dart';
import 'package:huda/data/models/ayah_audio_range.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../l10n/app_localizations.dart';

class AudioSettingsWidget extends StatelessWidget {
  final bool loopEnabled;
  final bool autoplayEnabled;
  final ValueChanged<bool?> onLoopChanged;
  final ValueChanged<bool?> onAutoplayChanged;
  final AyahAudioRange? range;
  final int totalAyahs;
  final int initialIndex;
  final ValueChanged<AyahAudioRange?>? onRangeChanged;

  const AudioSettingsWidget({
    super.key,
    required this.loopEnabled,
    required this.autoplayEnabled,
    required this.onLoopChanged,
    required this.onAutoplayChanged,
    this.range,
    required this.totalAyahs,
    required this.initialIndex,
    this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? context.accentColor
        : context.primaryColor;
    final selection = range;
    final rangeEnabled = selection != null;

    Widget picker({
      required String label,
      required int value,
      required int first,
      required ValueChanged<int> onChanged,
    }) => Expanded(
      child: DropdownButtonFormField<int>(
        key: ValueKey('$label-$first-$value'),
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 280,
        borderRadius: BorderRadius.circular(16),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: accent.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent.withValues(alpha: 0.18)),
          ),
        ),
        items: List.generate(
          totalAyahs - first + 1,
          (i) =>
              DropdownMenuItem(value: first + i, child: Text('${first + i}')),
        ),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Divider(height: 1, color: accent.withValues(alpha: 0.12)),
        ),
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: rangeEnabled,
            maintainState: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            iconColor: accent,
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune_rounded, color: accent, size: 22),
            ),
            title: Text(
              l10n.audioSettings,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: selection == null
                ? null
                : Text(
                    '${l10n.audioFromAyah} ${selection.startIndex + 1} · '
                    '${l10n.audioToAyah} ${selection.endIndex + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(color: accent),
                  ),
            children: [
              if (onRangeChanged != null && totalAyahs > 0)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: accent,
                  title: Text(
                    l10n.ayahAudioRange,
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: rangeEnabled,
                  onChanged: (enabled) => onRangeChanged!(
                    enabled
                        ? AyahAudioRange(
                            startIndex: initialIndex,
                            endIndex: totalAyahs - 1,
                          )
                        : null,
                  ),
                ),
              if (selection != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    picker(
                      label: l10n.audioFromAyah,
                      value: selection.startIndex + 1,
                      first: 1,
                      onChanged: (value) => onRangeChanged!(
                        AyahAudioRange(
                          startIndex: value - 1,
                          endIndex: selection.endIndex < value - 1
                              ? value - 1
                              : selection.endIndex,
                          repeat: selection.repeat,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    picker(
                      label: l10n.audioToAyah,
                      value: selection.endIndex + 1,
                      first: selection.startIndex + 1,
                      onChanged: (value) => onRangeChanged!(
                        AyahAudioRange(
                          startIndex: selection.startIndex,
                          endIndex: value - 1,
                          repeat: selection.repeat,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: accent,
                  title: Text(
                    l10n.audioRepeatRange,
                    style: theme.textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    selection.repeat
                        ? l10n.audioRangeRepeatHint
                        : l10n.audioRangeEndHint,
                    style: theme.textTheme.bodySmall,
                  ),
                  value: selection.repeat,
                  onChanged: (value) => onRangeChanged!(
                    AyahAudioRange(
                      startIndex: selection.startIndex,
                      endIndex: selection.endIndex,
                      repeat: value,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: accent.withValues(alpha: 0.12)),
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: accent,
                title: Text(
                  l10n.loopThisAyah,
                  style: theme.textTheme.bodyMedium,
                ),
                value: !rangeEnabled && loopEnabled,
                onChanged: rangeEnabled ? null : onLoopChanged,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: accent,
                title: Text(
                  l10n.autoplayNextAyah,
                  style: theme.textTheme.bodyMedium,
                ),
                value: !rangeEnabled && autoplayEnabled,
                onChanged: rangeEnabled ? null : onAutoplayChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
