import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/hadith/hadith_refs.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_share_card.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_text.dart';
import 'package:huda/presentation/widgets/share/huda_share_sheet.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_saver.dart';
import 'package:share_plus/share_plus.dart';

/// Opens Hadith's share sheet for one hadith: a live preview of its folio
/// card, the translation ticked in or out, then share as an image or as
/// text, copy the text (it moved here from the card), or save the image.
/// The image renders ahead, as Athkar's does, so sharing rarely waits.
Future<void> shareHadith(
  BuildContext context, {
  required HadithEntry entry,
  required HadithCollectionRef collection,
  required HadithBookRef book,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.hadithShare,
    maxDialogWidth: 760,
    builder: (_) => HadithShareSheet(
      screenContext: context,
      entry: entry,
      collection: collection,
      book: book,
    ),
  );
}

/// The sheet's body: the option, the preview and the ways to share.
class HadithShareSheet extends StatefulWidget {
  const HadithShareSheet({
    super.key,
    required this.screenContext,
    required this.entry,
    required this.collection,
    required this.book,
  });

  /// The reader screen's context: captures and toasts run there.
  final BuildContext screenContext;
  final HadithEntry entry;
  final HadithCollectionRef collection;
  final HadithBookRef book;

  @override
  State<HadithShareSheet> createState() => _HadithShareSheetState();
}

class _HadithShareSheetState extends State<HadithShareSheet> {
  bool? _withTranslation;
  final _renders = <bool, Future<Uint8List>>{};
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

  HadithEntry get _entry => widget.entry;

  bool get _arabicUi => Localizations.localeOf(context).languageCode == 'ar';

  /// The option shows only when there's both an Arabic text and a
  /// translation. On by default, except in Arabic.
  bool get _canChoose =>
      _entry.arabic.isNotEmpty && _entry.translation.isNotEmpty;

  bool get _showTranslation => _entry.arabic.isEmpty
      ? true
      : _canChoose && (_withTranslation ?? !_arabicUi);

  String? get _rubric =>
      _entry.bab(arabicUi: _arabicUi) ??
      (widget.book.title.isEmpty ? null : widget.book.title);

  HadithShareCard get _card => HadithShareCard(
    // The sheet cross-fades the preview, and forgets "Saved", per option.
    key: ValueKey(_showTranslation),
    collection: widget.collection.title,
    collectionArabic: widget.collection.arabicTitle,
    number: _entry.number,
    rubric: _rubric,
    arabic: _entry.arabic,
    translation: _showTranslation ? _entry.translation : const [],
    narrators: _entry.narrators,
    grade: _entry.grade,
    gradedBy: _entry.gradedBy,
    quietArabic: !_arabicUi && _entry.unmarkedChain,
  );

  void _renderAhead([Duration delay = const Duration(milliseconds: 300)]) {
    _ahead?.cancel();
    _ahead = Timer(delay, () {
      if (mounted) _render().ignore();
    });
  }

  Future<Uint8List> _render() {
    _ahead?.cancel();
    final key = _showTranslation;
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

  String get _citation => '${widget.collection.title} ${_entry.number}';

  String get _text {
    final l10n = AppLocalizations.of(context)!;
    final grade = _entry.grade;
    return [
      ?_rubric,
      if (_entry.arabicText.isNotEmpty) _entry.arabicText,
      if (_showTranslation && _entry.translationText.isNotEmpty)
        _entry.translationText,
      [
        _citation,
        if (grade != null)
          [
            hadithGradeLabel(l10n, grade),
            ?hadithGraderName(_entry.gradedBy, arabic: _arabicUi),
          ].join(', '),
      ].join(' · '),
      l10n.sharedViaHuda,
    ].join('\n\n');
  }

  String get _fileName => 'hadith_${widget.collection.slug}_${_entry.number}'
      .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');

  Future<void> _shareImage() async {
    final shown = Stopwatch()..start();
    final l10n = AppLocalizations.of(context)!;
    final screen = widget.screenContext;
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
        text: '$_citation\n\n${l10n.sharedViaHuda}',
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
        subject: _citation,
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
    return HudaShareSheetBody(
      card: _card,
      cardWidth: HadithShareCard.width,
      cardAspect: HadithShareCard.cardRatio(
        arabic: _entry.arabicText,
        translation: _showTranslation ? _entry.translationText : '',
      ),
      previewLabel: l10n.hadithShare,
      controls: !_canChoose
          ? null
          : HudaTickOption(
              key: const ValueKey('hadith_share_translation'),
              label: l10n.shareIncludeTranslation,
              icon: Icons.translate_rounded,
              value: _showTranslation,
              onChanged: (value) {
                HudaHaptics.selection(context);
                setState(() => _withTranslation = value);
                _renderAhead();
              },
            ),
      onShareImage: _shareImage,
      onShareText: _shareText,
      onCopyText: () => Clipboard.setData(ClipboardData(text: _text)),
      onSaveImage: _saveImage,
    );
  }
}
