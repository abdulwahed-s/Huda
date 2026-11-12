import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool?> showLinuxPrayerTraySetup(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => const LinuxPrayerTraySetupSheet(),
  );
}

class LinuxPrayerTraySetupSheet extends StatefulWidget {
  const LinuxPrayerTraySetupSheet({super.key});

  @override
  State<LinuxPrayerTraySetupSheet> createState() =>
      _LinuxPrayerTraySetupSheetState();
}

class _LinuxPrayerTraySetupSheetState extends State<LinuxPrayerTraySetupSheet> {
  static final _downloads = Uri.parse(
    'https://github.com/abdulwahed-s/Huda/releases/latest',
  );
  late final String _extensionState;
  String? _command;
  String? _copied;
  bool _loading = true;
  bool _checking = false;
  bool _notReady = false;
  bool _showDownloadLink = false;

  bool get _enableOnly => _extensionState == 'disabled';

  @override
  void initState() {
    super.initState();
    _extensionState = LinuxPrayerTrayBridge.status.value.extensionState;
    if (_enableOnly) {
      _loading = false;
    } else {
      unawaited(_loadCommand());
    }
  }

  Future<void> _loadCommand() async {
    final command = await LinuxPrayerTrayBridge.installationCommand();
    if (mounted) {
      setState(() {
        _command = command;
        _loading = false;
      });
    }
  }

  Future<void> _copy(String command, String action) async {
    await Clipboard.setData(ClipboardData(text: command));
    if (mounted) setState(() => _copied = action);
  }

  Future<void> _openDownloads() async {
    try {
      if (await launchUrl(_downloads, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // Keep the link usable when the browser/desktop portal is unavailable.
    }
    if (mounted) setState(() => _showDownloadLink = true);
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _notReady = false;
    });
    await LinuxPrayerTrayBridge.refreshStatus();
    if (!mounted) return;
    if (LinuxPrayerTrayBridge.status.value.extensionState == 'enabled') {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _checking = false;
        _notReady = true;
      });
    }
  }

  Widget _step(int number, String title, List<Widget> children) {
    final palette = PrayerPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: palette.tint,
            foregroundColor: palette.primary,
            child: Text('$number'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copyCommand(String command, String action, String label) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          key: ValueKey('linux-tray-copy-$action'),
          onPressed: () => _copy(command, action),
          icon: Icon(_copied == action ? Icons.check : Icons.copy_rounded),
          label: Text(label),
        ),
        if (_copied == action && (_command != null || _enableOnly)) ...[
          const SizedBox(height: 6),
          Text(
            l10n.linuxPrayerTrayCommandCopied,
            style: TextStyle(color: PrayerPalette.of(context).success),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: SelectableText(
            command,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: PrayerPalette.of(context).muted,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        maxWidth: 560,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.linuxPrayerTrayInstall,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (!_enableOnly && (_command != null || _loading))
                Text(l10n.linuxPrayerTraySetupIntro),
              if (_extensionState == 'incompatible')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.linuxPrayerTrayUpdateStep,
                    style: TextStyle(color: palette.warning),
                  ),
                ),
              if (!_enableOnly)
                _step(1, l10n.linuxPrayerTrayInstallStepTitle, [
                  if (_loading)
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_command != null) ...[
                    Text(l10n.linuxPrayerTrayInstallStep),
                    _copyCommand(
                      _command!,
                      'install',
                      l10n.linuxPrayerTrayCopyCommand,
                    ),
                  ] else ...[
                    Text(l10n.linuxPrayerTrayDownloadStep),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: _openDownloads,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(l10n.linuxPrayerTrayDownloads),
                    ),
                    if (_showDownloadLink) ...[
                      SelectableText(
                        _downloads.toString(),
                        textDirection: TextDirection.ltr,
                      ),
                      TextButton.icon(
                        onPressed: () => _copy(_downloads.toString(), 'link'),
                        icon: Icon(
                          _copied == 'link' ? Icons.check : Icons.copy_rounded,
                        ),
                        label: Text(l10n.copyText),
                      ),
                    ],
                    _copyCommand(
                      'gnome-extensions install --force ',
                      'install',
                      l10n.linuxPrayerTrayCopyCommand,
                    ),
                  ],
                ]),
              _step(_enableOnly ? 1 : 2, l10n.linuxPrayerTrayEnableStepTitle, [
                Text(l10n.linuxPrayerTrayEnableStep),
                if (_enableOnly)
                  _copyCommand(
                    'gnome-extensions enable prayer-tray@huda',
                    'enable',
                    l10n.linuxPrayerTrayCopyCommand,
                  ),
                const SizedBox(height: 8),
                Text(
                  l10n.linuxPrayerTrayLoginHint,
                  style: TextStyle(color: palette.muted),
                ),
              ]),
              _step(_enableOnly ? 2 : 3, l10n.linuxPrayerTrayFinishStepTitle, [
                Text(l10n.linuxPrayerTrayFinishStep),
              ]),
              const SizedBox(height: 20),
              if (_notReady) ...[
                Text(
                  l10n.linuxPrayerTraySetupNotReady,
                  key: const ValueKey('linux-tray-setup-not-ready'),
                  style: TextStyle(color: palette.warning),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                key: const ValueKey('linux-tray-check-setup'),
                onPressed: _checking ? null : _check,
                icon: _checking
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(l10n.linuxPrayerTrayCheckSetup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
