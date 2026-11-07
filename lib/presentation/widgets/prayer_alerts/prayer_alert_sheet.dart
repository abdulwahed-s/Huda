import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/services/prayer_audio_library.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_home_page.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_prayer_page.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';

/// Opens the adhan and alert settings, on [prayer]'s page when given. Edits
/// save as they are made; anything still pending is saved on close.
Future<void> showPrayerAlertSheet(
  BuildContext context, {
  String? prayer,
  String? nextPrayer,
  PrayerAlertController<Object?>? controller,
  PrayerAudioLibrary? library,
}) async {
  final alerts = controller ?? PrayerAlerts.shared;
  final sounds = library ?? PrayerAudioLibrary.shared;
  unawaited(alerts.refresh());
  unawaited(sounds.load(refresh: true));
  await showHudaSheet<void>(
    context: context,
    title: AppLocalizations.of(context)!.prayerAlertTitle,
    expand: true,
    sideSheet: true,
    maxDialogWidth: 600,
    builder: (_) => PrayerAlertSheet(
      controller: alerts,
      library: sounds,
      initialPrayer: prayer,
      nextPrayer: nextPrayer,
    ),
  );
  await sounds.stopPreview();
  await alerts.flush();
}

/// What every page of the sheet needs.
class PrayerAlertScope extends InheritedWidget {
  const PrayerAlertScope({
    super.key,
    required this.controller,
    required this.library,
    required this.navigator,
    required this.close,
    required this.nextPrayer,
    required super.child,
  });

  final PrayerAlertController<Object?> controller;
  final PrayerAudioLibrary library;
  final GlobalKey<NavigatorState> navigator;
  final VoidCallback close;
  final String? nextPrayer;

  static PrayerAlertScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrayerAlertScope>()!;

  /// Slides a page in from the reading side.
  void push(Widget page) => navigator.currentState?.push(
    PageRouteBuilder<void>(
      pageBuilder: (context, _, _) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, _, child) {
        final rtl = Directionality.of(context) == TextDirection.rtl;
        if (MediaQuery.disableAnimationsOf(context)) return child;
        return SlideTransition(
          position: Tween(begin: Offset(rtl ? -1 : 1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    ),
  );

  @override
  bool updateShouldNotify(PrayerAlertScope oldWidget) =>
      controller != oldWidget.controller || library != oldWidget.library;
}

class PrayerAlertSheet extends StatefulWidget {
  const PrayerAlertSheet({
    super.key,
    required this.controller,
    required this.library,
    this.initialPrayer,
    this.nextPrayer,
  });

  final PrayerAlertController<Object?> controller;
  final PrayerAudioLibrary library;
  final String? initialPrayer;
  final String? nextPrayer;

  @override
  State<PrayerAlertSheet> createState() => _PrayerAlertSheetState();
}

class _PrayerAlertSheetState extends State<PrayerAlertSheet> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PrayerAlertScope(
      controller: widget.controller,
      library: widget.library,
      navigator: _navigator,
      nextPrayer: widget.nextPrayer,
      close: () => Navigator.of(context).maybePop(),
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _navigator.currentState?.maybePop(),
        child: Navigator(
          key: _navigator,
          onGenerateInitialRoutes: (_, _) => [
            MaterialPageRoute<void>(
              builder: (_) => const PrayerAlertHomePage(),
            ),
            if (widget.initialPrayer != null)
              MaterialPageRoute<void>(
                builder: (_) =>
                    PrayerAlertPrayerPage(prayer: widget.initialPrayer!),
              ),
          ],
        ),
      ),
    );
  }
}

/// A page of the sheet: header with back, title, save status and close,
/// over a scrolling list that rebuilds as settings change.
class PrayerAlertPage extends StatelessWidget {
  const PrayerAlertPage({
    super.key,
    required this.title,
    required this.builder,
  });

  final String title;
  final List<Widget> Function(
    BuildContext context,
    PrayerAlertSettings settings,
    PrayerAlertCapabilities capabilities,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final scope = PrayerAlertScope.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final tokens = context.tokens;
    // The sheet's own surface, so a page sliding in covers the one below.
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: ListenableBuilder(
        listenable: Listenable.merge([scope.controller, scope.library]),
        builder: (context, _) {
          final settings = scope.controller.settings;
          final capabilities = scope.controller.capabilities;
          return Column(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  tokens.space.xs,
                  tokens.space.xs,
                  tokens.space.xs,
                  tokens.space.xxs,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: canPop
                          ? IconButton(
                              tooltip: l10n.prayerAlertBack,
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const BackButtonIcon(),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: palette.ink,
                            ),
                          ),
                          SizedBox(
                            height: 18,
                            child: PrayerSaveStatus(
                              controller: scope.controller,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        key: const ValueKey('prayer-alert-close'),
                        tooltip: l10n.prayerAlertClose,
                        onPressed: scope.close,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: settings == null || capabilities == null
                    ? const Center(child: HudaLampSpinner(size: 32))
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          tokens.space.md,
                          tokens.space.xs,
                          tokens.space.md,
                          tokens.space.xxl + MediaQuery.paddingOf(context).bottom,
                        ),
                        children: [
                          PrayerSaveFailureBanner(controller: scope.controller),
                          ...builder(context, settings, capabilities),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
