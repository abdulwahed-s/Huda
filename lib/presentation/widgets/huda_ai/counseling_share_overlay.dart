import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/data/models/counseling_response_model.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

class CounselingShareOverlay {
  static Future<void> shareAsImage({
    required BuildContext context,
    required CounselingResponse response,
    required AppLocalizations appLocalizations,
    required Function(dynamic) onError,
    required Function() onComplete,
  }) async {
    try {
      await ShareImageCapture.share(
        context: context,
        card: CounselingShareCard(response: response),
        fileName:
            'huda_counseling_${DateTime.now().millisecondsSinceEpoch}.png',
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

class CounselingShareCard extends StatelessWidget {
  final CounselingResponse response;

  const CounselingShareCard({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = ShareImagePalette.of(context);

    final sections = <Widget>[
      if (response.counselingText.trim().isNotEmpty)
        _Section(
          palette: palette,
          icon: Icons.lightbulb_rounded,
          title: localizations.guidance,
          children: [_bodyText(response.counselingText, palette)],
        ),
      if (response.ayah.trim().isNotEmpty)
        _Section(
          palette: palette,
          icon: Icons.menu_book_rounded,
          title: localizations.quranicWisdom,
          children: [
            _scriptureText(response.ayah, palette),
            if (response.ayahTranslation.trim().isNotEmpty)
              _translationText(response.ayahTranslation, palette),
            if (response.ayahReference.trim().isNotEmpty)
              ShareInfoChip(
                palette: palette,
                icon: Icons.bookmark_rounded,
                label: response.ayahReference,
                textDirection: shareTextDirection(response.ayahReference),
              ),
          ],
        ),
      if (response.duaa.trim().isNotEmpty)
        _Section(
          palette: palette,
          icon: Icons.volunteer_activism_rounded,
          title: localizations.duaa,
          children: [
            _scriptureText(response.duaa, palette),
            if (response.duaaTranslation.trim().isNotEmpty)
              _translationText(response.duaaTranslation, palette),
          ],
        ),
    ];

    return BrandedShareFrame(
      palette: palette,
      sectionLabel: localizations.hudaAI,
      sectionIcon: Icons.psychology_rounded,
      title: localizations.counselingMode,
      footnote: ShareFootnote(
        icon: Icons.info_outline_rounded,
        text: localizations.aiGeneratedDisclaimer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 20),
              ShareOrnamentDivider(color: palette.gold),
              const SizedBox(height: 20),
            ],
            sections[i],
          ],
        ],
      ),
    );
  }

  static Widget _bodyText(String text, ShareImagePalette palette) => Text(
    text,
    textDirection: shareTextDirection(text),
    style: TextStyle(
      fontSize: 15,
      height: 1.75,
      color: palette.ink,
      fontWeight: FontWeight.w500,
    ),
  );

  static Widget _scriptureText(String text, ShareImagePalette palette) => Text(
    text,
    textAlign: TextAlign.center,
    textDirection: shareTextDirection(text),
    style: TextStyle(
      fontFamily: 'Amiri',
      fontSize: 20,
      height: 2,
      color: palette.ink,
    ),
  );

  static Widget _translationText(String text, ShareImagePalette palette) =>
      Text(
        text,
        textAlign: TextAlign.center,
        textDirection: shareTextDirection(text),
        style: TextStyle(
          fontSize: 14,
          height: 1.7,
          color: palette.inkMuted,
          fontWeight: FontWeight.w500,
        ),
      );
}

class _Section extends StatelessWidget {
  final ShareImagePalette palette;
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.palette,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShareSectionHeading(palette: palette, icon: icon, label: title),
        for (final child in children) ...[const SizedBox(height: 12), child],
      ],
    );
  }
}
