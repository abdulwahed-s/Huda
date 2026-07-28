import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  final GlobalKey _ayahCardKey = GlobalKey();
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
                    child: ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                      ),
                      label: Text(AppLocalizations.of(context)!.copyText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareText,
                      icon: const Icon(
                        Icons.text_fields_rounded,
                        size: 18,
                      ),
                      label: Text(AppLocalizations.of(context)!.shareText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryVariantColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!Platform.isLinux)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingImage ? null : _shareAsImage,
                    icon: _isGeneratingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.image_rounded,
                            size: 18,
                          ),
                    label: Text(_isGeneratingImage
                        ? AppLocalizations.of(context)!.generating
                        : AppLocalizations.of(context)!.shareAsImage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryLightColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? context.darkCardBackground
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.accentColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RepaintBoundary(
            key: _ayahCardKey,
            child: _buildShareableCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildShareableCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2F2F2F)
            : context.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF505050)
              : context.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${widget.ayah.numberInSurah}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.primaryColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              (() {
                String ayahText = widget.ayah.text ?? '';
                final isFirstAyah = widget.ayah.numberInSurah == 1;
                final shouldShowBismillah = isFirstAyah &&
                    widget.ayah.number != 1 &&
                    widget.ayah.number != 9;

                if (shouldShowBismillah) {
                  const bismillahText =
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';
                  if (ayahText.trim().startsWith(bismillahText)) {
                    ayahText =
                        ayahText.trim().replaceFirst(bismillahText, '').trim();
                  }
                }
                return ayahText;
              })(),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: getQuranFonts(),
                fontSize: 22,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFE0E0E0)
                    : const Color(0xFF2C3E50),
                height: 2.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_includeTranslation && widget.currentTranslation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF606060)
                      : context.accentColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                _getTranslationText(),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFD0D0D0)
                      : const Color(0xFF2C3E50),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (_includeTafsir && widget.currentTafsir != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF404040)
                    : const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF606060)
                      : context.accentColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.tafsirLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFB0B0B0)
                          : context.accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      _getTafsirText(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFD0D0D0)
                            : const Color(0xFF2C3E50),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_includeReference) ...[
            const SizedBox(height: 16),
            Text(
              _getReference(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF888888)
                    : context.accentColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.hudaQuranApp,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF666666)
                  : context.accentColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
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
    final displaySurahName =
        englishName.isNotEmpty ? '$surahName ($englishName)' : surahName;

    return AppLocalizations.of(context)!
        .surahAyahReference(displaySurahName, ayahNumber.toString());
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
      await SharePlus.instance.share(ShareParams(
        text: _getShareText(),
        subject: widget.surahName != null
            ? AppLocalizations.of(context)!.ayahFromSurah(widget.surahName!)
            : AppLocalizations.of(context)!.ayahFromQuran,
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 1,
          height: 1,
        ),
      ));
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
      final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

      RenderRepaintBoundary boundary = _ayahCardKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'ayah_${widget.surahNumber}_${widget.ayah.numberInSurah}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      final screenSize = MediaQuery.of(context).size;
      final shareTitle = widget.surahName != null
          ? appLocalizations.ayahFromSurah(widget.surahName!)
          : appLocalizations.ayahFromQuran;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '$shareTitle\n\n${appLocalizations.sharedViaHuda}',
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 1,
          height: 1,
        ),
      ));
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
