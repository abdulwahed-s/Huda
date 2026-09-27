import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/core/theme/app_fonts.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/surah/quran_share_card.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/data/models/surah_model.dart';
import 'package:huda/data/models/tafsir_model.dart' as tafsir;
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class ShareWidget extends StatefulWidget {
  final Ayahs ayah;
  final int surahNumber;
  final String? surahName;
  final String? surahEnglishName;
  final String? selectedTranslationId;
  final tafsir.TafsirModel? currentTranslation;
  final String? selectedTafsirId;
  final tafsir.TafsirModel? currentTafsir;

  const ShareWidget({
    super.key,
    required this.ayah,
    required this.surahNumber,
    this.surahName,
    this.surahEnglishName,
    this.selectedTranslationId,
    this.currentTranslation,
    this.selectedTafsirId,
    this.currentTafsir,
  });

  @override
  State<ShareWidget> createState() => _ShareWidgetState();
}

class _ShareWidgetState extends State<ShareWidget> {
  bool _isGeneratingImage = false;
  bool _includeTranslation = false;
  bool _includeTafsir = false;
  bool _includeReference = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.shareCopy,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? context.accentColor
                : context.primaryColor,
          ),
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? context.darkCardBackground
                : context.lightSurface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: context.primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.share_rounded,
                    size: 18.sp,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.accentColor
                        : context.primaryColor,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    AppLocalizations.of(context)!.shareOptions,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? context.accentColor
                          : context.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.currentTranslation != null)
                CheckboxListTile(
                  title: Text(
                    AppLocalizations.of(context)!.includeTranslation,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _includeTranslation,
                  onChanged: (value) =>
                      setState(() => _includeTranslation = value ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: context.primaryColor,
                ),
              if (widget.currentTafsir != null)
                CheckboxListTile(
                  title: Text(
                    AppLocalizations.of(context)!.includeTafsir,
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _includeTafsir,
                  onChanged: (value) =>
                      setState(() => _includeTafsir = value ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: context.primaryColor,
                ),
              CheckboxListTile(
                title: Text(
                  AppLocalizations.of(context)!.includeReference,
                  style: const TextStyle(fontSize: 13),
                ),
                value: _includeReference,
                onChanged: (value) =>
                    setState(() => _includeReference = value ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: context.primaryColor,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: AppLocalizations.of(context)!.copyText,
                      icon: Icons.copy_rounded,
                      onPressed: _copyToClipboard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      label: AppLocalizations.of(context)!.shareText,
                      icon: Icons.text_fields_rounded,
                      onPressed: _shareText,
                    ),
                  ),
                ],
              ),
              if (!Platform.isLinux) ...[
                const SizedBox(height: 10),
                _buildActionButton(
                  label: _isGeneratingImage
                      ? AppLocalizations.of(context)!.generating
                      : AppLocalizations.of(context)!.shareAsImage,
                  icon: Icons.image_rounded,
                  onPressed: _shareAsImage,
                  busy: _isGeneratingImage,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: MediaQuery.withNoTextScaling(child: _buildShareCard()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool busy = false,
  }) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? context.accentColor
        : context.primaryColor;
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        disabledForegroundColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.45,
        ),
        backgroundColor: accent.withValues(alpha: 0.03),
        side: BorderSide(color: accent.withValues(alpha: 0.18)),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          : Icon(icon, size: 20),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge,
      ),
    );
  }

  Widget _buildShareCard() {
    return QuranShareCard(
      ayahText: _getAyahDisplayText(),
      ayahNumber: widget.ayah.numberInSurah ?? 1,
      quranFontFamily: AppFonts.resolve(getQuranFonts()),
      translation: _includeTranslation && widget.currentTranslation != null
          ? _getTranslationText()
          : null,
      tafsir: _includeTafsir && widget.currentTafsir != null
          ? _getTafsirText()
          : null,
      reference: _includeReference ? _getImageReference() : null,
    );
  }

  String _getAyahDisplayText() {
    final ayahText = widget.ayah.text ?? '';
    final shouldStripBismillah =
        widget.ayah.numberInSurah == 1 &&
        widget.ayah.number != 1 &&
        widget.ayah.number != 9;
    const bismillahText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
    if (shouldStripBismillah && ayahText.trim().startsWith(bismillahText)) {
      return ayahText.trim().replaceFirst(bismillahText, '').trim();
    }
    return ayahText;
  }

  String _getTranslationText() {
    if (widget.currentTranslation == null ||
        widget.currentTranslation!.data == null ||
        widget.currentTranslation!.data!.surahs == null ||
        widget.currentTranslation!.data!.surahs!.isEmpty) {
      return AppLocalizations.of(context)!.translationNotAvailable;
    }

    final surah = widget.currentTranslation!.data!.surahs!.firstWhere(
      (s) => s.number == widget.surahNumber,
      orElse: () => tafsir.Surahs(),
    );

    if (surah.ayahs == null ||
        surah.ayahs!.length <= (widget.ayah.numberInSurah! - 1)) {
      return AppLocalizations.of(context)!.translationNotAvailable;
    }

    return surah.ayahs![widget.ayah.numberInSurah! - 1].text ??
        AppLocalizations.of(context)!.translationNotAvailable;
  }

  String _getTafsirText() {
    if (widget.currentTafsir == null ||
        widget.currentTafsir!.data == null ||
        widget.currentTafsir!.data!.surahs == null ||
        widget.currentTafsir!.data!.surahs!.isEmpty) {
      return AppLocalizations.of(context)!.tafsirNotAvailable;
    }

    final surah = widget.currentTafsir!.data!.surahs!.firstWhere(
      (s) => s.number == widget.surahNumber,
      orElse: () => tafsir.Surahs(),
    );

    if (surah.ayahs == null ||
        surah.ayahs!.length <= (widget.ayah.numberInSurah! - 1)) {
      return AppLocalizations.of(context)!.tafsirNotAvailable;
    }

    return surah.ayahs![widget.ayah.numberInSurah! - 1].text ??
        AppLocalizations.of(context)!.tafsirNotAvailable;
  }

  String _getReference() {
    final surahName =
        widget.surahName ?? AppLocalizations.of(context)!.unknownSurah;
    final englishName = widget.surahEnglishName ?? '';
    final ayahNumber = widget.ayah.numberInSurah ?? 1;
    final displaySurahName = englishName.isNotEmpty
        ? '$surahName ($englishName)'
        : surahName;

    return AppLocalizations.of(
      context,
    )!.surahAyahReference(displaySurahName, ayahNumber.toString());
  }

  String? _localizedSurahName() {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final englishName = widget.surahEnglishName?.trim() ?? '';
    final arabicName = (widget.surahName ?? '')
        .replaceFirst(RegExp(r'^\s*سُورَةُ\s+'), '')
        .trim();
    if (!isRtl && englishName.isNotEmpty) return englishName;
    if (arabicName.isNotEmpty) return arabicName;
    return englishName.isNotEmpty ? englishName : null;
  }

  String _getImageReference() {
    final localizations = AppLocalizations.of(context)!;
    return localizations.surahAyahReference(
      _localizedSurahName() ?? localizations.unknownSurah,
      '${widget.ayah.numberInSurah ?? 1}',
    );
  }

  String _shareTitle() {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final fullArabicName = widget.surahName?.trim() ?? '';
    final surahName = isRtl && fullArabicName.isNotEmpty
        ? fullArabicName
        : _localizedSurahName();
    return surahName != null
        ? localizations.ayahFromSurah(surahName)
        : localizations.ayahFromQuran;
  }

  String _getShareText() {
    String text = '';

    text += '${widget.ayah.text ?? ''}\n\n';

    if (_includeTranslation && widget.currentTranslation != null) {
      text +=
          '${AppLocalizations.of(context)!.translationLabel}\n${_getTranslationText()}\n\n';
    }

    if (_includeTafsir && widget.currentTafsir != null) {
      text +=
          '${AppLocalizations.of(context)!.tafsirLabel}\n${_getTafsirText()}\n\n';
    }

    if (_includeReference) {
      text += '— ${_getReference()}\n\n';
    }

    text += AppLocalizations.of(context)!.sharedViaHuda;

    return text;
  }

  void _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _getShareText()));

      if (mounted) {
        _showSnack(
          AppLocalizations.of(context)!.copiedToClipboard,
          HudaSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          AppLocalizations.of(context)!.failedToCopy,
          HudaSnackBarKind.error,
        );
      }
    }
  }

  void _showSnack(String message, HudaSnackBarKind kind) {
    HudaSnackBar.show(
      context,
      message: message,
      kind: kind,
      duration: const Duration(seconds: 2),
    );
  }

  void _shareText() async {
    try {
      final screenSize = MediaQuery.of(context).size;
      await SharePlus.instance.share(
        ShareParams(
          text: _getShareText(),
          subject: _shareTitle(),
          sharePositionOrigin: Rect.fromCenter(
            center: Offset(screenSize.width / 2, screenSize.height / 2),
            width: 1,
            height: 1,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.failedShareText,
        );
      }
    }
  }

  void _shareAsImage() async {
    setState(() {
      _isGeneratingImage = true;
    });

    try {
      final appLocalizations = AppLocalizations.of(context)!;
      final shareTitle = _shareTitle();
      await ShareImageCapture.share(
        context: context,
        card: _buildShareCard(),
        fileName: 'ayah_${widget.surahNumber}_${widget.ayah.numberInSurah}.png',
        text: '$shareTitle\n\n${appLocalizations.sharedViaHuda}',
        subject: shareTitle,
      );
    } catch (e) {
      if (mounted) {
        HudaSnackBar.error(
          context,
          message: AppLocalizations.of(context)!.failedShareImage,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }
}
