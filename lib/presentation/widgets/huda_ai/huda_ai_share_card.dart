import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/counseling_response_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_identity.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_text.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

class HudaAiShareCard extends StatelessWidget {
  const HudaAiShareCard({super.key, required this.messageText, this.question});

  final String messageText;

  final String? question;

  static const double width = BrandedShareFrame.width;

  static double cardRatio({required String answer, String? question}) {
    final text =
        _lines(answer, 15) * 15 * 1.55 +
        (question == null ? 0 : _lines(question, 17) * 17 * 1.35 + 40);
    return math.max(width, _chrome + text) / width;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final question = this.question;
    return _NoorPage(
      eyebrow: l10n.hudaAI,
      asked: question == null || question.trim().isEmpty
          ? null
          : (l10n.hudaAiYouAsked, question.trim()),
      sections: [
        Builder(
          builder: (context) => HudaAiMarkdown(
            messageText,
            selectable: false,
            key: const ValueKey('huda_ai_share_answer'),
            body: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
        ),
      ],
    );
  }
}

class CounselingShareCard extends StatelessWidget {
  const CounselingShareCard({super.key, required this.response, this.feeling});

  final CounselingResponse response;
  final String? feeling;

  static const double width = BrandedShareFrame.width;

  static double cardRatio(CounselingResponse response, {String? feeling}) {
    double arabic(String s) => s.isEmpty ? 0 : _lines(s, 20) * 20 * 2 + 40;
    double latin(String s) => s.isEmpty ? 0 : _lines(s, 15) * 15 * 1.55 + 20;
    final text =
        latin(response.counselingText) +
        arabic(response.ayah) +
        latin(response.ayahTranslation) +
        arabic(response.duaa) +
        latin(response.duaaTranslation) +
        (feeling == null ? 0 : _lines(feeling, 17) * 17 * 1.35 + 40) +
        3 * 70;
    return math.max(width, _chrome + text) / width;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feeling = this.feeling;
    final r = response;
    return _NoorPage(
      eyebrow: '${l10n.hudaAI} · ${l10n.counseling}',
      asked: feeling == null || feeling.trim().isEmpty
          ? null
          : (l10n.hudaAiYouShared, feeling.trim()),
      sections: [
        if (r.counselingText.trim().isNotEmpty)
          _Section(
            title: l10n.guidance,
            children: [_Latin(r.counselingText.trim())],
          ),
        if (r.ayah.trim().isNotEmpty)
          _Section(
            title: l10n.quranicWisdom,
            children: [
              _Arabic(r.ayah.trim()),
              if (r.ayahTranslation.trim().isNotEmpty)
                _Latin(r.ayahTranslation.trim(), centered: true),
              if (r.ayahReference.trim().isNotEmpty)
                _Reference(r.ayahReference.trim()),
            ],
          ),
        if (r.duaa.trim().isNotEmpty)
          _Section(
            title: l10n.duaa,
            children: [
              _Arabic(r.duaa.trim()),
              if (r.duaaTranslation.trim().isNotEmpty)
                _Latin(r.duaaTranslation.trim(), centered: true),
            ],
          ),
      ],
    );
  }
}

const double _margin = 28;
const double _chrome = 250;

int _lines(String text, double size) {
  const room = BrandedShareFrame.width - 2 * _margin;
  return math.max(1, (text.length * 0.5 * size / room).ceil()) +
      '\n'.allMatches(text).length;
}

class _NoorPage extends StatelessWidget {
  const _NoorPage({
    required this.eyebrow,
    required this.asked,
    required this.sections,
  });

  final String eyebrow;
  final (String, String)? asked;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final dark = theme.brightness == Brightness.dark;
    final page = dark
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerLowest;
    final asked = this.asked;
    return MediaQuery.withNoTextScaling(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: HudaAiShareCard.width,
          constraints: const BoxConstraints(minHeight: HudaAiShareCard.width),
          decoration: BoxDecoration(
            color: page,
            gradient: RadialGradient(
              center: AlignmentDirectional.topEnd.resolve(
                Directionality.of(context),
              ),
              radius: 1.1,
              colors: [
                Color.alphaBlend(
                  tokens.ornament.withValues(alpha: dark ? 0.12 : 0.08),
                  page,
                ),
                page,
              ],
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                top: -96,
                end: -96,
                child: Ornament(
                  size: const Size.square(250),
                  painter: HudaAiNoorPainter(style: OrnamentStyle.of(context)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(_margin, 32, _margin, 24),
                child: IntrinsicHeight(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: HudaAiShareCard.width - 56,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          eyebrow.toUpperCase(),
                          style: context.type.eyebrow.copyWith(
                            color: scheme.tertiary,
                          ),
                        ),
                        if (asked != null) ...[
                          const SizedBox(height: 20),
                          FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: 0.74,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asked.$1,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  asked.$2,
                                  key: const ValueKey('huda_ai_share_asked'),
                                  textDirection: hudaAiTextDirection(asked.$2),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        for (var i = 0; i < sections.length; i++) ...[
                          if (i > 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: HudaAiMoteDivider(),
                            ),
                          sections[i],
                        ],
                        const Spacer(),
                        const SizedBox(height: 24),
                        _Foot(
                          color: scheme.onSurfaceVariant,
                          ink: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        for (final child in children) ...[const SizedBox(height: 10), child],
      ],
    );
  }
}

class _Latin extends StatelessWidget {
  const _Latin(this.text, {this.centered = false});

  final String text;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      textDirection: hudaAiTextDirection(text),
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.55,
        color: centered
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurface,
      ),
    );
  }
}

class _Arabic extends StatelessWidget {
  const _Arabic(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    textDirection: TextDirection.rtl,
    style: context.type.hadith.copyWith(
      fontSize: 20,
      height: 2,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _Reference extends StatelessWidget {
  const _Reference(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    textDirection: hudaAiTextDirection(text),
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.tertiary,
    ),
  );
}

class _Foot extends StatelessWidget {
  const _Foot({required this.color, required this.ink});

  final Color color;
  final Color ink;

  static const _glyphWidth = 830 / 1024;
  static const _glyphHeight = 448 / 1024;
  static const _height = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const side = _height / _glyphHeight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            l10n.aiGeneratedDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          key: const ValueKey('huda_ai_share_logo'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: side * _glyphWidth,
              height: _height,
              child: OverflowBox(
                maxWidth: side,
                maxHeight: side,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                  child: Image.asset(
                    BrandedShareFrame.logoAsset,
                    width: side,
                    height: side,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Huda',
              style: theme.textTheme.labelSmall?.copyWith(color: ink),
            ),
          ],
        ),
      ],
    );
  }
}
