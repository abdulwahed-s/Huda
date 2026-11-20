import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';

class QiblahLocationOffView extends StatelessWidget {
  const QiblahLocationOffView({
    super.key,
    required this.onOpenSettings,
    required this.onRetry,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaPermissionState(
      icon: Icons.location_off_rounded,
      title: l10n.qiblahLocationOffTitle,
      explanation: l10n.qiblahLocationOffMessage,
      allowLabel: l10n.qiblahTurnOnLocation,
      onAllow: onOpenSettings,
      secondaryLabel: l10n.retry,
      onSecondary: onRetry,
    );
  }
}

class QiblahAllowLocationView extends StatelessWidget {
  const QiblahAllowLocationView({super.key, required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaPermissionState(
      icon: Icons.near_me_rounded,
      title: l10n.qiblahAllowTitle,
      explanation: l10n.qiblahAllowMessage,
      allowLabel: l10n.qiblahAllowLocation,
      onAllow: onAllow,
    );
  }
}

class QiblahLocationBlockedView extends StatelessWidget {
  const QiblahLocationBlockedView({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaPermissionState(
      icon: Icons.location_disabled_rounded,
      title: l10n.qiblahBlockedTitle,
      explanation: l10n.qiblahBlockedMessage,
      allowLabel: l10n.openSettings,
      onAllow: onOpenSettings,
    );
  }
}

class QiblahErrorView extends StatelessWidget {
  const QiblahErrorView({
    super.key,
    required this.onRetry,
    required this.retrying,
  });

  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaErrorState(
      title: l10n.qiblahErrorTitle,
      message: l10n.qiblahErrorMessage,
      onRetry: onRetry,
      retrying: retrying,
    );
  }
}
