import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';

class QuranShareCard extends StatelessWidget {
  final String ayahText;
  final int ayahNumber;
  final String? quranFontFamily;
  final String? translation;
  final String? tafsir;

  final String? reference;

  const QuranShareCard({
    super.key,
    required this.ayahText,
    required this.ayahNumber,
    this.quranFontFamily,
    this.translation,
    this.tafsir,
    this.reference,
  });

  static String _arabicDigits(int value) => value
      .toString()
      .split('')
      .map((digit) => String.fromCharCode(0x0660 + int.parse(digit)))
      .join();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = ShareImagePalette.of(context);
    final translation = this.translation;
    final tafsir = this.tafsir;

    return BrandedShareFrame(
      palette: palette,
      sectionLabel: localizations.quran,
      sectionIcon: Icons.menu_book_rounded,
      title: reference,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$ayahText \uFD3F${_arabicDigits(ayahNumber)}\uFD3E',
            key: const ValueKey('quran_share_ayah'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: quranFontFamily,
              fontSize: 25,
              height: 2.1,
              color: palette.ink,
            ),
          ),
          if (translation != null && translation.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            ShareOrnamentDivider(color: palette.gold),
            const SizedBox(height: 16),
            Text(
              translation,
              textAlign: TextAlign.center,
              textDirection: shareTextDirection(translation),
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: palette.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (tafsir != null && tafsir.trim().isNotEmpty) ...[
            const SizedBox(height: 22),
            ShareSectionHeading(
              palette: palette,
              icon: Icons.auto_stories_rounded,
              label: localizations.tafsirLabel.replaceAll(
                RegExp(r'[:：]\s*$'),
                '',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tafsir,
              textDirection: shareTextDirection(tafsir),
              style: TextStyle(
                fontSize: 14,
                height: 1.75,
                color: palette.inkMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
