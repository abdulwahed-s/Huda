import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// Installs the panel when Huda has no bundled installer (builds outside
/// the Snap): the script downloads the panel from Huda's latest release.
const linuxPrayerPanelGithubCommand =
    'curl -fsSL https://github.com/abdulwahed-s/Huda/releases/latest/download/'
    'install-huda-prayer-panel.sh | bash';

enum LinuxPrayerPanelPhase { loading, install, waiting, ready, incompatible }

/// One-time panel setup: copy one command, run it in Terminal, and Huda
/// notices by itself when the panel connects (no "Check setup" button).
/// Shared by the onboarding step and the Prayer Times sheet.
class LinuxPrayerPanelSetupController extends ChangeNotifier {
  LinuxPrayerPanelSetupController({
    Future<String?> Function()? loadCommand,
    Future<void> Function()? refresh,
    ValueListenable<LinuxPrayerTrayStatus>? status,
    this.poll = const Duration(seconds: 2),
    this.patience = const Duration(seconds: 30),
  }) : _loadCommand = loadCommand ?? LinuxPrayerTrayBridge.installationCommand,
       _refresh = refresh ?? LinuxPrayerTrayBridge.refreshStatus,
       _status = status ?? LinuxPrayerTrayBridge.status {
    _status.addListener(_onStatus);
    _onStatus();
    unawaited(_load());
    _timer = Timer.periodic(poll, (_) => _tick());
  }

  final Future<String?> Function() _loadCommand;
  final Future<void> Function() _refresh;
  final ValueListenable<LinuxPrayerTrayStatus> _status;
  final Duration poll, patience;

  Timer? _timer;
  DateTime? _copiedAt;
  bool _refreshing = false, _disposed = false, _loaded = false;
  String _command = linuxPrayerPanelGithubCommand;

  /// The command the person copies: the Snap's bundled installer, or the
  /// GitHub one-liner.
  String get command => _command;

  bool get copied => _copiedAt != null;

  bool get ready => _status.value.extensionState == 'enabled';

  /// Copied a while ago and still not connected: on Wayland GNOME loads a
  /// new extension only at the next login.
  bool get waitedLong =>
      _copiedAt != null &&
      DateTime.now().difference(_copiedAt!) >= patience &&
      !ready;

  LinuxPrayerPanelPhase get phase {
    if (ready) return LinuxPrayerPanelPhase.ready;
    if (_status.value.extensionState == 'incompatible') {
      return LinuxPrayerPanelPhase.incompatible;
    }
    if (!_loaded) return LinuxPrayerPanelPhase.loading;
    return copied ? LinuxPrayerPanelPhase.waiting : LinuxPrayerPanelPhase.install;
  }

  Future<void> _load() async {
    String? bundled;
    try {
      bundled = await _loadCommand();
    } catch (_) {}
    if (_disposed) return;
    if (bundled != null) _command = bundled;
    _loaded = true;
    notifyListeners();
  }

  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: _command));
    if (_disposed) return;
    _copiedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> _tick() async {
    if (_refreshing || ready) return;
    _refreshing = true;
    final wasLong = waitedLong;
    try {
      await _refresh();
    } catch (_) {
    } finally {
      _refreshing = false;
    }
    if (!_disposed && waitedLong != wasLong) notifyListeners();
  }

  void _onStatus() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _status.removeListener(_onStatus);
    super.dispose();
  }
}

/// The setup body: the steps, the copy button and the live state.
class LinuxPrayerPanelSetupView extends StatelessWidget {
  const LinuxPrayerPanelSetupView({
    super.key,
    required this.controller,
    this.showCopyButton = true,
  });

  final LinuxPrayerPanelSetupController controller;

  /// Off where the surrounding screen puts "Copy" in its own action bar.
  final bool showCopyButton;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final space = context.tokens.space;
        final muted = theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        );
        switch (controller.phase) {
          case LinuxPrayerPanelPhase.ready:
            return HudaCard(
              key: const ValueKey('linux-panel-ready'),
              child: Row(
                children: [
                  HudaIconMark(Icons.check_rounded, accent: scheme.primary),
                  SizedBox(width: space.md),
                  Expanded(
                    child: Text(
                      l10n.linuxPanelReady,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            );
          case LinuxPrayerPanelPhase.incompatible:
            return HudaCard(
              child: Text(
                l10n.linuxPrayerTrayUpdateStep,
                style: TextStyle(color: scheme.error),
              ),
            );
          case LinuxPrayerPanelPhase.loading:
            return const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          case LinuxPrayerPanelPhase.install:
          case LinuxPrayerPanelPhase.waiting:
            break;
        }
        final copied = controller.copied;
        Widget step(int number, String text, {Widget? below}) => Padding(
          padding: EdgeInsets.only(bottom: space.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: scheme.primary,
                child: Text(
                  '$number',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(text, style: theme.textTheme.bodyMedium),
                    ),
                    if (below != null) below,
                  ],
                ),
              ),
            ],
          ),
        );
        return HudaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              step(
                1,
                l10n.linuxPanelCopyStep,
                below: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showCopyButton) ...[
                      SizedBox(height: space.xs),
                      FilledButton.icon(
                        key: const ValueKey('linux-panel-copy'),
                        onPressed: controller.copy,
                        icon: Icon(
                          copied ? Icons.check_rounded : Icons.copy_rounded,
                        ),
                        label: Text(l10n.linuxPrayerTrayCopyCommand),
                      ),
                    ],
                    SizedBox(height: space.xs),
                    Container(
                      padding: EdgeInsets.all(space.xs),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        controller.command,
                        textDirection: TextDirection.ltr,
                        style: muted?.copyWith(fontFamily: 'monospace'),
                      ),
                    ),
                    if (copied) ...[
                      SizedBox(height: space.xxs),
                      Text(
                        l10n.linuxPrayerTrayCommandCopied,
                        style: muted?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ],
                ),
              ),
              step(2, l10n.linuxPanelTerminalStep),
              step(3, l10n.linuxPanelAutoStep),
              if (copied) ...[
                const Divider(height: 1),
                SizedBox(height: space.sm),
                Row(
                  key: const ValueKey('linux-panel-waiting'),
                  children: [
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: space.sm),
                    Expanded(child: Text(l10n.linuxPanelWaiting, style: muted)),
                  ],
                ),
                if (controller.waitedLong) ...[
                  SizedBox(height: space.xs),
                  Text(
                    l10n.linuxPanelLogoutHint,
                    key: const ValueKey('linux-panel-logout-hint'),
                    style: muted,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
