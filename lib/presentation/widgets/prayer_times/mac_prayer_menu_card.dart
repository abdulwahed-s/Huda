import 'package:flutter/material.dart';
import 'package:huda/core/services/mac_prayer_menu_bridge.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class MacPrayerMenuCard extends StatefulWidget {
  const MacPrayerMenuCard({super.key});

  @override
  State<MacPrayerMenuCard> createState() => _MacPrayerMenuCardState();
}

class _MacPrayerMenuCardState extends State<MacPrayerMenuCard> {
  MacPrayerMenuPreferences? _preferences;
  Object? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await MacPrayerMenuBridge.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = preferences;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _save(MacPrayerMenuPreferences next) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MacPrayerMenuBridge.setPreferences(next);
      if (mounted) setState(() => _preferences = next);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _preview(MacPrayerMenuStyle style, AppLocalizations l10n) {
    final sample =
        '1${l10n.macPrayerMenuHourShort} '
        '20${l10n.macPrayerMenuMinuteShort}';
    return switch (style) {
      MacPrayerMenuStyle.iconOnly => '',
      MacPrayerMenuStyle.iconNameCountdown => l10n.macPrayerMenuNameCountdown(
        l10n.asr,
        sample,
      ),
      MacPrayerMenuStyle.iconNameClock => '${l10n.asr} 16:42',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final palette = PrayerPalette.of(context);
    final preferences = _preferences;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: palette.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.desktop_mac_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.macPrayerMenuTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (preferences == null && _error == null)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (preferences != null)
                Switch.adaptive(
                  value: preferences.enabled,
                  onChanged: _busy
                      ? null
                      : (value) => _save(preferences.copyWith(enabled: value)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.macPrayerMenuDescription,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          if (preferences != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.macPrayerMenuStyle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 5),
            DropdownButton<MacPrayerMenuStyle>(
              value: preferences.style,
              isExpanded: true,
              onChanged: _busy || !preferences.enabled
                  ? null
                  : (style) {
                      if (style != null) {
                        _save(preferences.copyWith(style: style));
                      }
                    },
              items: [
                for (final style in MacPrayerMenuStyle.values)
                  DropdownMenuItem(
                    value: style,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/huda.png',
                          width: 22,
                          height: 18,
                          fit: BoxFit.contain,
                          color: colors.primary,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _preview(style, l10n).isEmpty
                                ? l10n.macPrayerMenuIconOnly
                                : _preview(style, l10n),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (_error != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.macPrayerMenuError,
                    style: TextStyle(color: colors.error),
                  ),
                ),
                TextButton(onPressed: _load, child: Text(l10n.retry)),
              ],
            ),
        ],
      ),
    );
  }
}
