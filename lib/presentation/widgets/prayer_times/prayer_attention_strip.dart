import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_country_names.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_sky.dart';

class PrayerAttentionStrip extends StatelessWidget {
  const PrayerAttentionStrip({
    super.key,
    required this.items,
    this.onChooseCountry,
    this.onDismissCountry,
  });

  final List<PrayerAttentionItem> items;
  final Future<void> Function(String countryCode)? onChooseCountry;
  final VoidCallback? onDismissCountry;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, item) in items.indexed) ...[
          if (i > 0) SizedBox(height: space.sm),
          PrayerNotice(
            item: item,
            onChooseCountry: onChooseCountry,
            onDismissCountry: onDismissCountry,
          ),
        ],
      ],
    );
  }
}

Color attentionAccent(PrayerPalette palette, PrayerAttentionTone tone) =>
    switch (tone) {
      PrayerAttentionTone.error => palette.error,
      PrayerAttentionTone.warning => palette.warning,
      PrayerAttentionTone.info => palette.primary,
    };

class PrayerNotice extends StatelessWidget {
  const PrayerNotice({
    super.key,
    required this.item,
    this.onChooseCountry,
    this.onDismissCountry,
  });

  final PrayerAttentionItem item;
  final Future<void> Function(String countryCode)? onChooseCountry;
  final VoidCallback? onDismissCountry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final l10n = AppLocalizations.of(context)!;
    final askCountry =
        item.countryCandidates.isNotEmpty && onChooseCountry != null;
    final primary = item.primary;
    final secondary = item.secondary;

    return Semantics(
      liveRegion: true,
      container: true,
      child: AnimatedContainer(
        duration: tokens.motion.of(context, tokens.motion.medium),
        curve: tokens.motion.standard,
        padding: EdgeInsetsDirectional.fromSTEB(
          space.md,
          space.md,
          space.md,
          space.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(tokens.radius.lg),
          border: Border.all(
            color: switch (item.tone) {
              PrayerAttentionTone.error => scheme.error.withValues(alpha: 0.45),
              PrayerAttentionTone.warning => PrayerPalette.of(
                context,
              ).warning.withValues(alpha: 0.45),
              PrayerAttentionTone.info => scheme.outlineVariant,
            },
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrayerNoticeLamp(tone: item.tone, busy: item.busy),
            SizedBox(width: space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: space.xs,
                    runSpacing: space.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      if (item.offline) _OfflineMark(label: l10n.youreOffline),
                    ],
                  ),
                  SizedBox(height: space.xxs),
                  Text(
                    item.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.details.isNotEmpty) ...[
                    SizedBox(height: space.xs),
                    for (final detail in item.details)
                      _Detail(text: detail.text),
                  ],
                  if (askCountry) ...[
                    SizedBox(height: space.sm),
                    _CountryQuestion(
                      question: l10n.prayerCountryQuestion,
                      notSure: l10n.prayerCountryNotSure,
                      countryCodes: item.countryCandidates,
                      localeCode: Localizations.localeOf(context).languageCode,
                      enabled: !item.busy,
                      onChoose: onChooseCountry!,
                      onDismiss: onDismissCountry,
                    ),
                  ],
                  if (primary != null || secondary != null) ...[
                    SizedBox(height: space.sm),
                    Wrap(
                      spacing: space.xs,
                      runSpacing: space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (primary != null)
                          FilledButton.icon(
                            onPressed: primary.onPressed,
                            icon: Icon(primary.icon, size: 18),
                            label: Text(primary.label),
                          ),
                        if (secondary != null)
                          TextButton.icon(
                            onPressed: secondary.onPressed,
                            icon: Icon(secondary.icon, size: 18),
                            label: Text(secondary.label),
                          ),
                      ],
                    ),
                  ],
                  if (primary == null && secondary == null && !askCountry)
                    SizedBox(height: space.xs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerNoticeLamp extends StatelessWidget {
  const PrayerNoticeLamp({
    super.key,
    required this.tone,
    this.busy = false,
    this.size = 44,
  });

  final PrayerAttentionTone tone;
  final bool busy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final palette = PrayerPalette.of(context);
    final mark = switch (tone) {
      PrayerAttentionTone.error => Color.lerp(
        scheme.error,
        tokens.onChrome,
        0.35,
      )!,
      PrayerAttentionTone.warning => Color.lerp(
        palette.warning,
        tokens.onChrome,
        0.3,
      )!,
      PrayerAttentionTone.info => tokens.gilt,
    };
    final size = math.max(this.size, 36.0);
    final inner = size - 4;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.chrome,
        border: Border.all(
          color: tone == PrayerAttentionTone.error
              ? mark.withValues(alpha: 0.75)
              : tokens.gilt.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PrayerSkyDisc(size: inner),
          AnimatedSwitcher(
            duration: tokens.motion.of(context, tokens.motion.short),
            child: busy
                ? HudaLampSpinner(
                    key: const ValueKey('busy'),
                    size: size / 2,
                    color: tokens.onChrome,
                  )
                : Ornament(
                    key: ValueKey(tone),
                    size: Size.square(inner),
                    painter: _SkyMarkPainter(
                      tone: tone,
                      at: prayerSkyDiscSun(context, inner),
                      mark: mark,
                      chrome: tokens.chrome,
                      light: tokens.onChrome,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SkyMarkPainter extends CustomPainter {
  _SkyMarkPainter({
    required this.tone,
    required this.at,
    required this.mark,
    required this.chrome,
    required this.light,
  });

  final PrayerAttentionTone tone;
  final Offset at;
  final Color mark;
  final Color chrome;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.2;
    final c = Offset(
      at.dx.clamp(r * 1.6, size.width - r * 1.6),
      at.dy.clamp(r * 1.6, size.height - r * 1.6),
    );
    switch (tone) {
      case PrayerAttentionTone.error:
        canvas.drawCircle(c, r + 1, Paint()..color = chrome);
        canvas.drawCircle(
          c,
          r + 1,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = mark,
        );
        final x = Paint()
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..color = mark;
        final k = r * 0.55;
        canvas.drawLine(c + Offset(-k, -k), c + Offset(k, k), x);
        canvas.drawLine(c + Offset(k, -k), c + Offset(-k, k), x);
      case PrayerAttentionTone.warning:
        canvas.drawCircle(c, r * 0.55, Paint()..color = light);
        for (final (k, w) in [(1.0, 1.8), (1.5, 1.2)]) {
          canvas.drawCircle(
            c,
            r * k,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = w
              ..color = mark,
          );
        }
      case PrayerAttentionTone.info:
        canvas.drawCircle(
          c,
          r * 1.4,
          Paint()..color = mark.withValues(alpha: 0.28),
        );
        canvas.drawCircle(
          c,
          r * 0.6,
          Paint()..color = Color.lerp(mark, light, 0.5)!,
        );
        final ray = Paint()
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(mark, light, 0.3)!;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(
            c + d * r * 0.95,
            c + d * r * (i.isEven ? 1.55 : 1.25),
            ray,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyMarkPainter old) =>
      old.tone != tone || old.at != at || old.mark != mark;
}

class _Detail extends StatelessWidget {
  const _Detail({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    final lineHeight =
        (style?.fontSize ?? 15) *
        (style?.height ?? 1.5) *
        MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            height: lineHeight,
            child: Center(
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: tokens.ornament,
                    width: tokens.stroke.fine,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: tokens.space.xs),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _CountryQuestion extends StatelessWidget {
  const _CountryQuestion({
    required this.question,
    required this.notSure,
    required this.countryCodes,
    required this.localeCode,
    required this.enabled,
    required this.onChoose,
    this.onDismiss,
  });
  final String question;
  final String notSure;
  final List<String> countryCodes;
  final String localeCode;
  final bool enabled;
  final Future<void> Function(String countryCode) onChoose;
  final VoidCallback? onDismiss;

  static String _flag(String code) => String.fromCharCodes(
    code.toUpperCase().codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: theme.textTheme.titleSmall),
        SizedBox(height: space.xs),
        Wrap(
          spacing: space.xs,
          runSpacing: space.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final code in countryCodes)
              OutlinedButton(
                onPressed: enabled ? () => onChoose(code) : null,
                child: Text(
                  '${_flag(code)}  '
                  '${PrayerCountryNames.localized(code, localeCode) ?? code}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (onDismiss != null)
              TextButton(
                onPressed: enabled ? onDismiss : null,
                child: Text(notSure),
              ),
          ],
        ),
      ],
    );
  }
}

class _OfflineMark extends StatelessWidget {
  const _OfflineMark({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off_rounded, size: 16, color: muted),
        SizedBox(width: tokens.space.xxs),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

class PrayerStatusLine extends StatelessWidget {
  const PrayerStatusLine({
    super.key,
    required this.status,
    this.message,
    this.onRetry,
  });

  final HudaStatus status;

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final l10n = AppLocalizations.of(context)!;
    final failed = status == HudaStatus.failed;
    final text = switch (status) {
      HudaStatus.updating => l10n.stateUpdating,
      HudaStatus.retrying => l10n.stateRetrying,
      HudaStatus.failed => message ?? l10n.somethingWentWrong,
    };
    final onRetry = this.onRetry;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrayerNoticeLamp(
            size: 36,
            busy: !failed,
            tone: failed ? PrayerAttentionTone.error : PrayerAttentionTone.info,
          ),
          SizedBox(width: space.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: space.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: failed
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (failed && onRetry != null) ...[
                    SizedBox(height: space.xs),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.retry),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
