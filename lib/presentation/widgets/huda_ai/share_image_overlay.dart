import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

class ShareImageOverlay {
  static Future<void> shareAsImage({
    required BuildContext context,
    required String messageText,
    required AppLocalizations appLocalizations,
    required Function(dynamic) onError,
    required Function() onComplete,
  }) async {
    try {
      await ShareImageCapture.share(
        context: context,
        card: HudaAiShareCard(messageText: messageText),
        fileName:
            'huda_ai_response_${DateTime.now().millisecondsSinceEpoch}.png',
        text: appLocalizations.sharedViaHuda,
      );
    } catch (e) {
      if (context.mounted) {
        HudaSnackBar.error(
          context,
          message: appLocalizations.failedToShareImage,
        );
      }
      onError(e);
    } finally {
      onComplete();
    }
  }
}

class HudaAiShareCard extends StatelessWidget {
  final String messageText;

  const HudaAiShareCard({super.key, required this.messageText});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = ShareImagePalette.of(context);
    final body = TextStyle(
      fontSize: 15.5,
      height: 1.75,
      color: palette.ink,
      fontWeight: FontWeight.w500,
    );
    final heading = body.copyWith(
      color: palette.accentInk,
      fontWeight: FontWeight.bold,
      height: 1.5,
    );

    return BrandedShareFrame(
      palette: palette,
      sectionLabel: localizations.hudaAI,
      sectionIcon: Icons.auto_awesome_rounded,
      title: localizations.islamicAssistant,
      footnote: ShareFootnote(
        icon: Icons.info_outline_rounded,
        text: localizations.aiGeneratedDisclaimer,
      ),
      child: Directionality(
        textDirection: shareTextDirection(messageText),
        child: MarkdownBody(
          data: messageText,
          styleSheet: MarkdownStyleSheet(
            p: body,
            h1: heading.copyWith(fontSize: 20),
            h2: heading.copyWith(fontSize: 18),
            h3: heading.copyWith(fontSize: 16),
            strong: body.copyWith(fontWeight: FontWeight.bold),
            em: body.copyWith(fontStyle: FontStyle.italic),
            listBullet: body.copyWith(color: palette.accentInk),
            code: body.copyWith(
              fontFamily: 'Courier',
              fontSize: 13.5,
              backgroundColor: palette.accentInk.withValues(alpha: 0.08),
            ),
            blockquote: body.copyWith(
              color: palette.inkMuted,
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: BoxDecoration(
              color: palette.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: palette.gold.withValues(alpha: 0.6)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
