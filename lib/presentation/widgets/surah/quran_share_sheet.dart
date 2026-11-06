import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/get_fonts.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/quran_home/quran_index_widgets.dart';
import 'package:huda/presentation/widgets/share/huda_share_sheet.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_saver.dart';
import 'package:huda/presentation/widgets/surah/quran_share_card.dart';
import 'package:share_plus/share_plus.dart';

/// Opens Quran's share sheet for one ayah: a live preview of its
/// illuminated card, the translation and tafsir (when the reader chose
/// them) ticked in or out, then share as an image or text, copy, or save.
/// The image renders ahead, as Hadith's does.
Future<void> shareAyah(
  BuildContext context, {
  required int surah,
  required int ayah,
  required String text,
  String? translation,
  String? tafsir,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.share,
    maxDialogWidth: 760,
    builder: (_) => QuranShareSheet(
      screenContext: context,
      surah: surah,
      ayah: ayah,
      text: text,
      translation: translation,
      tafsir: tafsir,
    ),
  );
}

class QuranShareSheet extends StatefulWidget {
  const QuranShareSheet({
    super.key,
    required this.screenContext,
    required this.surah,
    required this.ayah,
    required this.text,
    this.translation,
    this.tafsir,
  });

  /// The reader's context: captures and toasts run there.
  final BuildContext screenContext;
  final int surah;
  final int ayah;
  final String text;
  final String? translation;
  final String? tafsir;

  @override
  State<QuranShareSheet> createState() => _QuranShareSheetState();
}

class _QuranShareSheetState extends State<QuranShareSheet> {
  bool _withTranslation = true;
  bool _withTafsir = false;
  final _renders = <(bool, bool), Future<Uint8List>>{};
  Timer? _ahead;

  static const _loadingHold = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _renderAhead(const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _ahead?.cancel();
    super.dispose();
  }

  String? get _translation {
    final t = widget.translation?.trim();
    return _withTranslation && t != null && t.isNotEmpty ? t : null;
  }

  String? get _tafsir {
    final t = widget.tafsir?.trim();
    return _withTafsir && t != null && t.isNotEmpty ? t : null;
  }

  String get _reference {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final surah = QuranSurahRef.number(widget.surah, language);
    return '${surah.title} · ${l10n.ayahNumber(widget.ayah)}';
  }

  QuranShareCard get _card => QuranShareCard(
    // The sheet cross-fades the preview, and forgets "Saved", per option.
    key: ValueKey((_translation != null, _tafsir != null)),
    ayahText: widget.text,
    ayahNumber: widget.ayah,
    surahNumber: widget.surah,
    quranFontFamily: getQuranFonts(),
    translation: _translation,
    tafsir: _tafsir,
    reference: _reference,
  );

  void _renderAhead([Duration delay = const Duration(milliseconds: 300)]) {
    _ahead?.cancel();
    _ahead = Timer(delay, () {
      if (mounted) _render().ignore();
    });
  }

  Future<Uint8List> _render() {
    _ahead?.cancel();
    final key = (_translation != null, _tafsir != null);
    final rendered = _renders[key];
    if (rendered != null) return rendered;
    final render = ShareImageCapture.capturePng(
      context: widget.screenContext,
      card: _card,
    );
    _renders[key] = render;
    render.then<void>((_) {}, onError: (Object _) => _renders.remove(key));
    return render;
  }

  String get _text {
    final l10n = AppLocalizations.of(context)!;
    return [
      widget.text,
      ?_translation,
      if (_tafsir != null) '${l10n.tafsirLabel}\n$_tafsir',
      '— $_reference',
      l10n.sharedViaHuda,
    ].join('\n\n');
  }

  String get _fileName => 'quran_${widget.surah}_${widget.ayah}';

  Future<void> _shareImage() async {
    final shown = Stopwatch()..start();
    final l10n = AppLocalizations.of(context)!;
    final screen = widget.screenContext;
    final reference = _reference;
    void failed(Object _) {
      if (screen.mounted) {
        showHudaToast(
          screen,
          message: l10n.failedToShareImage,
          kind: HudaToastKind.failed,
        );
      }
    }

    final Uint8List png;
    try {
      png = await _render();
    } catch (error) {
      failed(error);
      return;
    }
    if (!screen.mounted) return;
    unawaited(
      ShareImageCapture.sharePng(
        context: screen,
        pngBytes: png,
        fileName: '$_fileName.png',
        text: '$reference\n\n${l10n.sharedViaHuda}',
      ).catchError(failed),
    );
    final rest = _loadingHold - shown.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
  }

  void _shareText() {
    final size = MediaQuery.sizeOf(context);
    SharePlus.instance.share(
      ShareParams(
        text: _text,
        subject: _reference,
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 1,
          height: 1,
        ),
      ),
    );
  }

  Future<ShareImageSaveResult> _saveImage() async {
    try {
      final png = await _render();
      return ShareImageSaver.save(png, name: _fileName);
    } catch (_) {
      return ShareImageSaveResult.failed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTranslation = (widget.translation?.trim() ?? '').isNotEmpty;
    final hasTafsir = (widget.tafsir?.trim() ?? '').isNotEmpty;
    final options = <Widget>[
      if (hasTranslation)
        HudaTickOption(
          key: const ValueKey('quran_share_translation'),
          label: l10n.shareIncludeTranslation,
          icon: Icons.translate_rounded,
          value: _withTranslation,
          onChanged: (value) {
            HudaHaptics.selection(context);
            setState(() => _withTranslation = value);
            _renderAhead();
          },
        ),
      if (hasTafsir)
        HudaTickOption(
          key: const ValueKey('quran_share_tafsir'),
          label: l10n.includeTafsir,
          icon: Icons.menu_book_rounded,
          value: _withTafsir,
          onChanged: (value) {
            HudaHaptics.selection(context);
            setState(() => _withTafsir = value);
            _renderAhead();
          },
        ),
    ];
    return HudaShareSheetBody(
      card: _card,
      cardWidth: QuranShareCard.width,
      cardAspect: QuranShareCard.cardRatio(
        arabic: widget.text,
        translation: _translation ?? '',
        tafsir: _tafsir ?? '',
      ),
      previewLabel: l10n.share,
      controls: options.isEmpty
          ? null
          : Column(mainAxisSize: MainAxisSize.min, children: options),
      onShareImage: _shareImage,
      onShareText: _shareText,
      onCopyText: () => Clipboard.setData(ClipboardData(text: _text)),
      onSaveImage: _saveImage,
    );
  }
}
