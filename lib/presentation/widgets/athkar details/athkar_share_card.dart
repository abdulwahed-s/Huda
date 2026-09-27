import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

class AthkarShareCard extends StatelessWidget {
  final String title;
  final String arabicText;
  final String? translatedText;
  final int repeatCount;

  const AthkarShareCard({
    super.key,
    required this.title,
    required this.arabicText,
    this.translatedText,
    required this.repeatCount,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = ShareImagePalette.of(context);
    final translatedText = this.translatedText;

    return BrandedShareFrame(
      palette: palette,
      sectionLabel: localizations.athkar,
      sectionIcon: Icons.spa_rounded,
      title: title,
      titleDirection: shareTextDirection(title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            arabicText,
            key: const ValueKey('athkar_share_arabic'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              height: 2.1,
              color: palette.ink,
            ),
          ),
          if (translatedText != null && translatedText.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            ShareOrnamentDivider(color: palette.gold),
            const SizedBox(height: 16),
            Text(
              translatedText,
              textAlign: TextAlign.center,
              textDirection: shareTextDirection(translatedText),
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: palette.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 22),
          ShareInfoChip(
            palette: palette,
            icon: Icons.repeat_rounded,
            label: localizations.athkarShareRepeatCount(repeatCount),
          ),
        ],
      ),
    );
  }
}
