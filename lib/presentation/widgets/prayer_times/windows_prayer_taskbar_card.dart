import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/services/windows_prayer_taskbar_bridge.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class WindowsPrayerTaskbarCard extends StatefulWidget {
  const WindowsPrayerTaskbarCard({super.key});

  @override
  State<WindowsPrayerTaskbarCard> createState() =>
      _WindowsPrayerTaskbarCardState();
}

class _WindowsPrayerTaskbarCardState extends State<WindowsPrayerTaskbarCard>
    with WidgetsBindingObserver {
  WindowsPrayerTaskbarPreferences? _preferences;
  bool _busy = false;
  bool _failed = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_busy) {
        unawaited(WindowsPrayerTaskbarBridge.refreshStatus());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_load());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final value = await WindowsPrayerTaskbarBridge.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = value;
          _failed = false;
        });
      }
      await WindowsPrayerTaskbarBridge.refreshStatus();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _save(WindowsPrayerTaskbarPreferences value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await WindowsPrayerTaskbarBridge.setPreferences(value);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      final saved = await WindowsPrayerTaskbarBridge.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = saved;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final preferences = _preferences;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: palette.cardDecoration(radius: 22),
      child: Material(
        type: MaterialType.transparency,
        child: ValueListenableBuilder<WindowsPrayerTaskbarStatus>(
          valueListenable: WindowsPrayerTaskbarBridge.status,
          builder: (context, status, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.desktop_windows_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.windowsPrayerTaskbarTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (preferences == null && !_failed)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.windowsPrayerTaskbarDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
              if (preferences != null) ...[
                const SizedBox(height: 8),
                _switch(
                  'windowsPrayerTaskbar',
                  l10n.windowsPrayerShowTaskbar,
                  preferences.showTaskbarCountdown,
                  (value) =>
                      _save(preferences.copyWith(showTaskbarCountdown: value)),
                ),
                _switch(
                  'windowsPrayerStartup',
                  l10n.windowsPrayerStartup,
                  preferences.startWithWindows,
                  (value) =>
                      _save(preferences.copyWith(startWithWindows: value)),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 4,
                    bottom: 8,
                  ),
                  child: Text(
                    status.startupBlocked
                        ? l10n.windowsPrayerStartupDisabled
                        : status.startupEnabled
                        ? l10n.windowsPrayerStartupEffectiveEnabled
                        : l10n.windowsPrayerStartupEffectiveDisabled,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
                ),
                if (status.startupBlocked)
                  TextButton(
                    onPressed: WindowsPrayerTaskbarBridge.openStartupSettings,
                    child: Text(l10n.windowsPrayerOpenStartupSettings),
                  ),
                if (preferences.showTaskbarCountdown)
                  _appearance(preferences, l10n),
                if (!status.helperAvailable)
                  _message(l10n.windowsPrayerHelperUnavailable),
                if (preferences.showTaskbarCountdown &&
                    status.taskbarPlacement == 'unavailable')
                  _message(l10n.windowsPrayerPlacementUnavailable),
              ],
              if (_failed || status.error != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.windowsPrayerError,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              if (_preferences != null) {
                                await _save(_preferences!);
                              }
                              await _load();
                            },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );

  Widget _appearance(
    WindowsPrayerTaskbarPreferences preferences,
    AppLocalizations l10n,
  ) {
    final iconOnly = preferences.style == WindowsPrayerTaskbarStyle.iconOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.windowsPrayerPreview,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _preview(preferences, l10n, dark: false)),
            const SizedBox(width: 8),
            Expanded(child: _preview(preferences, l10n, dark: true)),
          ],
        ),
        const SizedBox(height: 16),
        _choice(
          'windowsPrayerStyle',
          l10n.windowsPrayerStyle,
          preferences.style,
          {
            WindowsPrayerTaskbarStyle.iconOnly: l10n.macPrayerMenuIconOnly,
            WindowsPrayerTaskbarStyle.iconNameCountdown:
                l10n.windowsPrayerStyleCountdown,
            WindowsPrayerTaskbarStyle.iconNameClock:
                l10n.windowsPrayerStyleClock,
          },
          (style) => _save(preferences.copyWith(style: style)),
        ),
        _switch(
          'windowsPrayerSeconds',
          l10n.windowsPrayerSeconds,
          preferences.showSeconds,
          (value) => _save(preferences.copyWith(showSeconds: value)),
          enabled:
              preferences.style == WindowsPrayerTaskbarStyle.iconNameCountdown,
        ),
        _switch(
          'windowsPrayerTransparentBackground',
          l10n.windowsPrayerTransparentBackground,
          preferences.transparentBackground,
          (value) => _save(preferences.copyWith(transparentBackground: value)),
        ),
        _switch(
          'windowsPrayerShowIcon',
          l10n.windowsPrayerShowIcon,
          iconOnly || preferences.showIcon,
          (value) => _save(preferences.copyWith(showIcon: value)),
          enabled: !iconOnly,
        ),
        const SizedBox(height: 8),
        _choice(
          'windowsPrayerTextColor',
          l10n.windowsPrayerTextColor,
          preferences.textColor,
          {
            WindowsPrayerTaskbarTextColor.automatic:
                l10n.windowsPrayerTextColorAutomatic,
            WindowsPrayerTaskbarTextColor.light:
                l10n.windowsPrayerTextColorLight,
            WindowsPrayerTaskbarTextColor.dark: l10n.windowsPrayerTextColorDark,
            WindowsPrayerTaskbarTextColor.appColor:
                l10n.windowsPrayerTextColorApp,
          },
          (color) => _save(preferences.copyWith(textColor: color)),
        ),
        const SizedBox(height: 12),
        _choice(
          'windowsPrayerTextSize',
          l10n.windowsPrayerTextSize,
          preferences.textSize,
          {
            WindowsPrayerTaskbarTextSize.small: l10n.windowsPrayerTextSizeSmall,
            WindowsPrayerTaskbarTextSize.medium:
                l10n.windowsPrayerTextSizeMedium,
            WindowsPrayerTaskbarTextSize.large: l10n.windowsPrayerTextSizeLarge,
          },
          (size) => _save(preferences.copyWith(textSize: size)),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: const Key('windowsPrayerResetAppearance'),
            onPressed: _busy
                ? null
                : () => _save(
                    preferences.copyWith(
                      style: WindowsPrayerTaskbarStyle.iconNameCountdown,
                      showSeconds: true,
                      transparentBackground: true,
                      textColor: WindowsPrayerTaskbarTextColor.automatic,
                      textSize: WindowsPrayerTaskbarTextSize.medium,
                      showIcon: true,
                    ),
                  ),
            child: Text(l10n.windowsPrayerResetAppearance),
          ),
        ),
      ],
    );
  }

  Widget _preview(
    WindowsPrayerTaskbarPreferences preferences,
    AppLocalizations l10n, {
    required bool dark,
  }) {
    final foreground = switch (preferences.textColor) {
      WindowsPrayerTaskbarTextColor.automatic =>
        dark ? const Color(0xFFF5F5F5) : const Color(0xFF202020),
      WindowsPrayerTaskbarTextColor.light => const Color(0xFFF5F5F5),
      WindowsPrayerTaskbarTextColor.dark => const Color(0xFF202020),
      WindowsPrayerTaskbarTextColor.appColor => Theme.of(
        context,
      ).colorScheme.primary,
    };
    final caption = switch (preferences.style) {
      WindowsPrayerTaskbarStyle.iconOnly => '',
      WindowsPrayerTaskbarStyle.iconNameCountdown =>
        '${l10n.asr} · ${preferences.showSeconds ? '00:42:18' : '00:42'}',
      WindowsPrayerTaskbarStyle.iconNameClock => '${l10n.asr} · 16:42',
    };
    final fontSize = switch (preferences.textSize) {
      WindowsPrayerTaskbarTextSize.small => 11.0,
      WindowsPrayerTaskbarTextSize.medium => 13.0,
      WindowsPrayerTaskbarTextSize.large => 15.0,
    };
    return Container(
      key: Key(dark ? 'windowsPrayerPreviewDark' : 'windowsPrayerPreviewLight'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF252525) : const Color(0xFFE3E3E3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: preferences.transparentBackground
              ? Colors.transparent
              : dark
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (preferences.showIcon ||
                preferences.style == WindowsPrayerTaskbarStyle.iconOnly) ...[
              Image.asset(
                'assets/images/huda.png',
                width: 18,
                height: 18,
                color: foreground,
                excludeFromSemantics: true,
              ),
              if (caption.isNotEmpty) const SizedBox(width: 7),
            ],
            if (caption.isNotEmpty)
              Flexible(
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: foreground, fontSize: fontSize),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _choice<T>(
    String key,
    String label,
    T value,
    Map<T, String> choices,
    ValueChanged<T> onChanged,
  ) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      enabled: !_busy,
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: Key(key),
        value: value,
        isExpanded: true,
        onChanged: _busy
            ? null
            : (next) {
                if (next != null) onChanged(next);
              },
        items: [
          for (final entry in choices.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    ),
  );

  Widget _switch(
    String key,
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool enabled = true,
  }) => SwitchListTile.adaptive(
    key: Key(key),
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    value: value,
    onChanged: _busy || _preferences == null || !enabled ? null : onChanged,
  );
}
