import 'dart:async';

import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_alerts/prayer_alerts.dart';
import 'package:huda/core/services/prayer_audio_library.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_labels.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_sheet.dart';
import 'package:huda/presentation/widgets/prayer_alerts/prayer_alert_widgets.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class PrayerAlertSoundPage extends StatefulWidget {
  const PrayerAlertSoundPage({super.key, this.prayer});

  final String? prayer;

  @override
  State<PrayerAlertSoundPage> createState() => _PrayerAlertSoundPageState();
}

class _PrayerAlertSoundPageState extends State<PrayerAlertSoundPage> {
  String? _pending;
  PrayerAudioLibrary? _library;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _library = PrayerAlertScope.of(context).library;
  }

  Future<void> _choose(String? id) async {
    final scope = PrayerAlertScope.of(context);
    final library = scope.library;
    if (id == null) {
      setState(() => _pending = null);
      scope.controller.edit(
        SetPrayerAlertReciter(null, 'v1', prayer: widget.prayer),
      );
      return;
    }
    final reciter = library.reciter(id);
    if (reciter == null) return;
    setState(() => _pending = id);
    if (!await library.download(id)) {
      if (mounted && _pending == id) setState(() => _pending = null);
      return;
    }
    if (!mounted || _pending != id) return;
    setState(() => _pending = null);
    scope.controller.edit(
      SetPrayerAlertReciter(
        id,
        library.versionFor(reciter),
        prayer: widget.prayer,
      ),
    );
  }

  Future<void> _preview(String id) async {
    final library = PrayerAlertScope.of(context).library;
    final settings = PrayerAlertScope.of(context).controller.settings;
    if (library.previewing == id) {
      await library.stopPreview();
      return;
    }
    try {
      await library.preview(id, volume: settings?.volume);
    } catch (_) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.prayerAlertDownloadNetwork,
        );
      }
    }
  }

  Future<void> _remove(PrayerAudioReciter reciter, Set<String> users) async {
    final l10n = AppLocalizations.of(context)!;
    if (users.isNotEmpty) {
      HudaSnackBar.show(
        context,
        message: l10n.prayerAlertSoundInUse(
          users.join(
            Directionality.of(context) == TextDirection.rtl ? '، ' : ', ',
          ),
        ),
        kind: HudaSnackBarKind.warning,
      );
      return;
    }
    await PrayerAlertScope.of(context).library.remove(reciter.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PrayerAlertPage(
      title: widget.prayer == null
          ? l10n.prayerAlertSoundTitle
          : '${l10n.prayerAlertSoundTitle} · ${l10n.prayerName(widget.prayer!)}',
      builder: (context, settings, capabilities) {
        final library = PrayerAlertScope.of(context).library;
        final palette = PrayerPalette.of(context);
        final own = widget.prayer == null
            ? null
            : settings.prayers[widget.prayer];
        final selected = own == null
            ? settings.reciterId
            : own.ownReciter
            ? own.reciterId
            : null;

        Set<String> users(String id) => {
          if (settings.reciterId == id) l10n.prayerAlertSameAsAll,
          for (final entry in settings.prayers.entries)
            if (entry.value.ownReciter && entry.value.reciterId == id)
              l10n.prayerName(entry.key),
        };

        if (library.catalog == null) {
          return [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: library.loading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          Text(
                            l10n.prayerAlertSoundListFailed,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () => library.load(refresh: true),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
              ),
            ),
          ];
        }
        return [
          if (library.catalogOutdated)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 18,
                    color: palette.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.prayerAlertSoundOutdated,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: () => library.load(refresh: true),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          if (own != null)
            PrayerAlertSection(
              title: l10n.prayerName(widget.prayer!),
              children: [
                PrayerChoiceRow(
                  key: const ValueKey('prayer-alert-sound-default'),
                  title: l10n.prayerAlertSameAsAll,
                  subtitle: l10n.reciterName(
                    library.reciter(settings.reciterId),
                    Localizations.localeOf(context).languageCode,
                  ),
                  selected: selected == null,
                  onTap: () => _choose(null),
                ),
              ],
            ),
          PrayerAlertSection(
            title: l10n.prayerAlertSoundTitle,
            footer: library.downloadedBytes > 0
                ? l10n.prayerAlertSoundDownloaded(
                    prayerAlertSize(context, library.downloadedBytes),
                  )
                : null,
            children: [
              for (final reciter in library.reciters)
                _ReciterRow(
                  key: ValueKey('prayer-alert-sound-${reciter.id}'),
                  reciter: reciter,
                  status: library.status(reciter.id),
                  selected: selected == reciter.id,
                  pending: _pending == reciter.id,
                  previewing: library.previewing == reciter.id,
                  onChoose: () => _choose(reciter.id),
                  onPreview: () => _preview(reciter.id),
                  onCancel: () {
                    library.cancel(reciter.id);
                    setState(() => _pending = null);
                  },
                  onRemove: () => _remove(reciter, users(reciter.id)),
                ),
            ],
          ),
        ];
      },
    );
  }

  @override
  void dispose() {
    unawaited(_library?.stopPreview());
    super.dispose();
  }
}

class PrayerChoiceRow extends StatelessWidget {
  const PrayerChoiceRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    return Semantics(
      selected: selected,
      child: PrayerSettingRow(
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        trailing: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: selected ? palette.primary : palette.faint,
        ),
      ),
    );
  }
}

class _ReciterRow extends StatelessWidget {
  const _ReciterRow({
    super.key,
    required this.reciter,
    required this.status,
    required this.selected,
    required this.pending,
    required this.previewing,
    required this.onChoose,
    required this.onPreview,
    required this.onCancel,
    required this.onRemove,
  });

  final PrayerAudioReciter reciter;
  final PrayerSoundStatus status;
  final bool selected, pending, previewing;
  final VoidCallback onChoose, onPreview, onCancel, onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final size = prayerAlertSize(
      context,
      reciter.full.bytes + reciter.short.bytes,
    );
    final downloading = status.state == PrayerSoundState.downloading;
    final (String line, Color color) = switch (status.state) {
      PrayerSoundState.builtIn => (l10n.prayerAlertSoundBuiltIn, palette.muted),
      PrayerSoundState.ready => (l10n.prayerAlertSoundReady, palette.success),
      PrayerSoundState.downloading => (
        [
          l10n.prayerAlertSoundDownloading(
            ((status.progress ?? 0) * 100).round(),
          ),
          if (pending) l10n.prayerAlertSoundSelectAfter,
        ].join(' · '),
        palette.primary,
      ),
      PrayerSoundState.failed => (
        l10n.downloadFailure(status.failure),
        palette.error,
      ),
      PrayerSoundState.notDownloaded => (
        l10n.prayerAlertSoundSize(size),
        palette.muted,
      ),
    };
    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: downloading ? null : onChoose,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: previewing
                    ? l10n.prayerAlertSoundStop
                    : l10n.prayerAlertSoundPlay,
                onPressed: onPreview,
                icon: Icon(
                  previewing
                      ? Icons.stop_circle_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 34,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.reciterName(reciter, locale)!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      line,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        height: 1.35,
                      ),
                    ),
                    if (downloading) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: status.progress,
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (downloading)
                IconButton(
                  tooltip: l10n.prayerAlertSoundCancel,
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                )
              else if (status.state == PrayerSoundState.notDownloaded ||
                  status.state == PrayerSoundState.failed)
                IconButton(
                  tooltip: status.state == PrayerSoundState.failed
                      ? l10n.retry
                      : l10n.prayerAlertSoundDownload,
                  onPressed: onChoose,
                  icon: Icon(
                    status.state == PrayerSoundState.failed
                        ? Icons.refresh_rounded
                        : Icons.download_rounded,
                    color: palette.primary,
                  ),
                )
              else if (status.state == PrayerSoundState.ready)
                PopupMenuButton<void>(
                  icon: Icon(Icons.more_vert_rounded, color: palette.faint),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: onRemove,
                      child: Text(l10n.prayerAlertSoundRemove),
                    ),
                  ],
                ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? palette.primary : palette.faint,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
