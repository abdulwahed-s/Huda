import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/linux_prayer_panel_setup.dart';

/// Panel setup from Prayer Times, for people who skipped it in onboarding.
/// Closes with true by itself once the panel connects.
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
  final _setup = LinuxPrayerPanelSetupController();
  Timer? _close;

  @override
  void initState() {
    super.initState();
    _setup.addListener(_onChange);
  }

  void _onChange() {
    if (_setup.ready && _close == null) {
      // A moment to see the confirmation before the sheet closes.
      _close = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  @override
  void dispose() {
    _close?.cancel();
    _setup
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(_setup.ready),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                l10n.linuxPanelIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              LinuxPrayerPanelSetupView(controller: _setup),
            ],
          ),
        ),
      ),
    );
  }
}
