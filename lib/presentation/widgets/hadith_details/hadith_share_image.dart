import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:huda/core/utils/hadith_text_formatter.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

class HadithShareImage {
  static Future<void> share({
    required BuildContext context,
    required String chapterName,
    required String hadithBody,
    required String status,
    required String languageCode,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final title = HadithTextFormatter.format(chapterName).plainText;
    return ShareImageCapture.share(
      context: context,
      card: HadithShareCard(
        chapterName: chapterName,
        hadithBody: hadithBody,
        status: status,
        languageCode: languageCode,
      ),
      fileName: 'hadith.png',
      text: '$title\n\n${localizations.sharedViaHuda}',
      subject: title,
    );
  }

  static Future<Uint8List> capturePng({
    required BuildContext context,
    required String chapterName,
    required String hadithBody,
    required String status,
    required String languageCode,
  }) {
    return ShareImageCapture.capturePng(
      context: context,
      card: HadithShareCard(
        chapterName: chapterName,
        hadithBody: hadithBody,
        status: status,
        languageCode: languageCode,
      ),
    );
  }
}

class HadithShareCard extends StatelessWidget {
  final String chapterName;
  final String hadithBody;
  final String status;
  final String languageCode;

  const HadithShareCard({
    super.key,
    required this.chapterName,
    required this.hadithBody,
    required this.status,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = ShareImagePalette.of(context);
    final isArabic = languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final bodyStyle = TextStyle(
      fontFamily: isArabic ? 'Amiri' : null,
      fontSize: isArabic ? 19 : 16.5,
      height: isArabic ? 1.95 : 1.7,
      color: palette.ink,
    );
    final formattedBody = HadithTextFormatter.format(hadithBody);

    return BrandedShareFrame(
      palette: palette,
      sectionLabel: localizations.hadith,
      sectionIcon: Icons.auto_stories_rounded,
      title: HadithTextFormatter.format(chapterName).plainText,
      titleDirection: textDirection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: bodyStyle,
              children: [
                for (final run in formattedBody.runs)
                  TextSpan(
                    text: run.text,
                    style: bodyStyle.copyWith(
                      fontWeight: run.bold ? FontWeight.bold : null,
                      fontStyle: run.italic ? FontStyle.italic : null,
                      color: run.narrator
                          ? palette.accentInk
                          : run.quran
                          ? const Color(0xFF8A6420)
                          : null,
                    ),
                  ),
              ],
            ),
            key: const ValueKey('hadith_share_body'),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: textDirection,
          ),
          if (status.trim().isNotEmpty) ...[
            const SizedBox(height: 22),
            ShareInfoChip(
              palette: palette,
              icon: Icons.verified_rounded,
              label: '${localizations.status}: $status',
            ),
          ],
        ],
      ),
    );
  }
}
