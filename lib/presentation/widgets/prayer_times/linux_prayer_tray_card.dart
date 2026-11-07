import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_strip.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/presentation/widgets/prayer_times/linux_prayer_tray_setup_sheet.dart';

class LinuxPrayerTrayCard extends StatefulWidget {
  const LinuxPrayerTrayCard({super.key});
  @override
  State<LinuxPrayerTrayCard> createState() => _LinuxPrayerTrayCardState();
}

class _LinuxPrayerTrayCardState extends State<LinuxPrayerTrayCard> {
  Timer? _poll;
  bool _busy = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    unawaited(LinuxPrayerTrayBridge.refreshStatus());
    _poll = Timer.periodic(
      const Duration(seconds: 10),
      (_) => LinuxPrayerTrayBridge.refreshStatus(),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _save(LinuxPrayerTrayPreferences next) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await LinuxPrayerTrayBridge.setPreferences(next);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setup() async {
    if (await showLinuxPrayerTraySetup(context) == true && mounted) {
      await _save(
        LinuxPrayerTrayBridge.preferences.value.copyWith(enabled: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    return ValueListenableBuilder<LinuxPrayerTrayPreferences>(
      valueListenable: LinuxPrayerTrayBridge.preferences,
      builder: (context, preferences, _) =>
          ValueListenableBuilder<LinuxPrayerTrayStatus>(
            valueListenable: LinuxPrayerTrayBridge.status,
            builder: (context, status, _) {
              final extensionReady = status.extensionState == 'enabled';
              final message = switch (status.extensionState) {
                'missing' => l10n.linuxPrayerTrayExtensionMissing,
                'disabled' => l10n.linuxPrayerTrayExtensionDisabled,
                'unknown' => l10n.linuxPrayerTrayInstallHelp,
                'incompatible' => l10n.linuxPrayerTrayExtensionIncompatible,
                _ => switch (status.state) {
                  'calculationUnavailable' =>
                    l10n.linuxPrayerTrayCalculationUnavailable,
                  'needsSetup' => l10n.macPrayerMenuNeedsSetup,
                  'disabled' || 'stopped' => l10n.linuxPrayerTrayStopped,
                  _ =>
                    status.serviceAvailable
                        ? l10n.linuxPrayerTrayAvailable
                        : l10n.linuxPrayerTrayServiceUnavailable,
                },
              };
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: palette.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.desktop_windows_rounded,
                          color: palette.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.linuxPrayerTrayTitle,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Semantics(
                          label: l10n.linuxPrayerTrayTitle,
                          child: Switch.adaptive(
                            value: extensionReady && preferences.enabled,
                            onChanged: _busy
                                ? null
                                : (value) => extensionReady
                                      ? _save(
                                          preferences.copyWith(enabled: value),
                                        )
                                      : _setup(),
                          ),
                        ),
                      ],
                    ),
                    Text(l10n.linuxPrayerTrayDescription),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      key: const ValueKey('linux-tray-status'),
                      style: TextStyle(
                        color:
                            status.serviceAvailable &&
                                status.extensionState == 'enabled'
                            ? palette.muted
                            : palette.warning,
                      ),
                    ),
                    if (!extensionReady) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('linux-tray-setup'),
                        onPressed: _busy ? null : _setup,
                        icon: const Icon(Icons.extension_outlined),
                        label: Text(l10n.linuxPrayerTrayInstall),
                      ),
                    ],
                    // Reminders need the service at login even without the
                    // panel, so this switch doesn't wait for the extension.
                    Row(
                      children: [
                        Expanded(child: Text(l10n.linuxPrayerTrayStartAtLogin)),
                        Semantics(
                          label: l10n.linuxPrayerTrayStartAtLogin,
                          child: Switch.adaptive(
                            value: preferences.startAtLogin,
                            onChanged: _busy
                                ? null
                                : (value) => _save(
                                    preferences.copyWith(startAtLogin: value),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (preferences.startAtLogin != status.startupEnabled)
                      Text(
                        l10n.linuxPrayerTrayError,
                        style: TextStyle(color: palette.warning),
                      ),
                    if (extensionReady) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LinuxPrayerTrayStyle>(
                        initialValue: preferences.style,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.macPrayerMenuStyle,
                        ),
                        onChanged: _busy
                            ? null
                            : (style) {
                                if (style != null) {
                                  _save(preferences.copyWith(style: style));
                                }
                              },
                        items: [
                          DropdownMenuItem(
                            value: LinuxPrayerTrayStyle.iconOnly,
                            child: Text(l10n.macPrayerMenuIconOnly),
                          ),
                          DropdownMenuItem(
                            value: LinuxPrayerTrayStyle.iconNameCountdown,
                            child: Text(
                              l10n.macPrayerMenuNameCountdown(
                                l10n.asr,
                                '1${l10n.macPrayerMenuHourShort} 20${l10n.macPrayerMenuMinuteShort}',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: LinuxPrayerTrayStyle.iconNameClock,
                            child: Text('${l10n.asr} 16:42'),
                          ),
                        ],
                      ),
                      if (_failed || status.error != null)
                        PrayerStatusLine(
                          status: HudaStatus.failed,
                          message: l10n.linuxPrayerTrayError,
                          onRetry: _busy
                              ? null
                              : LinuxPrayerTrayBridge.refreshStatus,
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (!status.serviceAvailable && preferences.enabled)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _save(preferences),
                              child: Text(l10n.linuxPrayerTrayRestart),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
    );
  }
}
