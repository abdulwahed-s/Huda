import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class PrayerAlertStatusCard extends StatelessWidget {
  const PrayerAlertStatusCard({super.key, required this.status});

  final PrayerAlertStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final accent = switch (status.tone) {
      PrayerAlertTone.ready => palette.success,
      PrayerAlertTone.info => palette.primary,
      PrayerAlertTone.warning => palette.warning,
      PrayerAlertTone.error => palette.error,
    };
    final action = status.action;
    final highlight = status.highlight;

    return Semantics(
      container: true,
      liveRegion: status.tone != PrayerAlertTone.ready,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: palette.cardDecoration(radius: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: status.busy
                    ? SizedBox.square(
                        key: const ValueKey('busy'),
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          strokeCap: StrokeCap.round,
                          color: accent,
                        ),
                      )
                    : Icon(
                        status.icon,
                        key: ValueKey(status.icon),
                        color: accent,
                        size: 21,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: palette.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (highlight != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      highlight,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    status.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.muted,
                      height: 1.4,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: action.onPressed,
                      icon: Icon(action.icon, size: 18),
                      label: Text(action.label),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent.withValues(alpha: 0.14),
                        foregroundColor: accent,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
