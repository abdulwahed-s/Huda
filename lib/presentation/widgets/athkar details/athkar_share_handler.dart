import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/data/models/athkar_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_share_card.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/share/huda_share_sheet.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_saver.dart';
import 'package:share_plus/share_plus.dart';

/// Opens Athkar's share sheet for one dhikr: a live preview of its own
/// card (as tall as the dhikr needs; owner round 5 dropped the size
/// choice), the translation on or off, then share as an image or as text,
/// copy the text, or save the image to the device. The image is
/// rendered ahead, once the sheet has settled and after each option
/// change, so sharing or saving it rarely waits (owner round 3).
Future<void> shareAthkar(
  BuildContext context, {
  required AthkarDetailModel dhikr,
  required int index,
  required String title,
  required String titleEn,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.shareDhikr,
    maxDialogWidth: 760,
    builder: (_) => AthkarShareSheet(
      screenContext: context,
      dhikr: dhikr,
      index: index,
      title: title,
      titleEn: titleEn,
    ),
  );
}

/// The sheet's body: the options, the preview and the ways to share.
class AthkarShareSheet extends StatefulWidget {
  const AthkarShareSheet({
    super.key,
    required this.screenContext,
    required this.dhikr,
    required this.index,
    required this.title,
    required this.titleEn,
  });

  /// The chapter screen's context: captures and toasts run there.
  final BuildContext screenContext;
  final AthkarDetailModel dhikr;
  final int index;
  final String title;
  final String titleEn;

  @override
  State<AthkarShareSheet> createState() => _AthkarShareSheetState();
}

class _AthkarShareSheetState extends State<AthkarShareSheet> {
  bool? _withTranslation;

  /// Rendered images with and without the translation, so switching back
  /// is instant.
  final _renders = <bool, Future<Uint8List>>{};
  Timer? _ahead;

  @override
  void initState() {
    super.initState();
    // After the sheet's entrance, so rendering never costs it a frame.
    _renderAhead(const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _ahead?.cancel();
    super.dispose();
  }

  void _renderAhead([Duration delay = const Duration(milliseconds: 300)]) {
    _ahead?.cancel();
    _ahead = Timer(delay, () {
      if (mounted) _render().ignore();
    });
  }

  /// The image for the current options: rendered once, then reused. A
  /// failed render is forgotten, so the next tap tries again.
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

  String get _translation => (widget.dhikr.translatedText ?? '').trim();

  bool get _arabicUi => Localizations.localeOf(context).languageCode == 'ar';

  /// On by default, except in Arabic, where the dhikr is already the text.
  bool get _showTranslation =>
      _translation.isNotEmpty && (_withTranslation ?? !_arabicUi);

  String get _chapter => _arabicUi || widget.titleEn.trim().isEmpty
      ? widget.title
      : widget.titleEn;

  AthkarShareCard get _card => AthkarShareCard(
    // The sheet cross-fades the preview, and forgets "Saved", per option.
    key: ValueKey(_showTranslation),
    title: _chapter,
    arabicText: widget.dhikr.arabicText ?? '',
    translatedText: _showTranslation ? _translation : null,
    repeatCount: widget.dhikr.repeat ?? 1,
  );

  String get _text {
    final l10n = AppLocalizations.of(context)!;
    return [
      widget.dhikr.arabicText ?? '',
      if (_showTranslation) _translation,
      l10n.athkarShareRepeatCount(widget.dhikr.repeat ?? 0),
      l10n.sharedViaHuda,
    ].join('\n\n');
  }

  String get _fileName => 'athkar_${widget.index}';

  /// The system's share sheet opens as soon as the image is ready; the
  /// button keeps its loading at least [_loadingHold] (owner round 4: the
  /// loading should show, not flash), resting under the system sheet.
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
        text: '$_chapter\n\n${l10n.sharedViaHuda}',
      ).catchError(failed),
    );
    final rest = _loadingHold - shown.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
  }

  static const _loadingHold = Duration(milliseconds: 900);

  void _shareText() {
    final size = MediaQuery.sizeOf(context);
    SharePlus.instance.share(
      ShareParams(
        text: _text,
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
    // A tick box, so it reads as included or not at a glance (owner
    // round 3: a chip didn't say it could be turned off; round 6: a square
    // tick, not a switch). The only option: the card has one shape (owner
    // round 5).
    final controls = _translation.isEmpty
        ? null
        : HudaTickOption(
            key: const ValueKey('athkar_share_translation'),
            label: l10n.shareIncludeTranslation,
            icon: Icons.translate_rounded,
            value: _showTranslation,
            onChanged: (value) {
              HudaHaptics.selection(context);
              setState(() => _withTranslation = value);
              _renderAhead();
            },
          );
    return HudaShareSheetBody(
      card: _card,
      cardWidth: AthkarShareCard.width,
      cardAspect: AthkarShareCard.cardRatio(
        arabic: widget.dhikr.arabicText ?? '',
        translation: _showTranslation ? _translation : null,
      ),
      previewLabel: l10n.shareDhikr,
      controls: controls,
      onShareImage: _shareImage,
      onShareText: _shareText,
      onCopyText: () => Clipboard.setData(ClipboardData(text: _text)),
      onSaveImage: _saveImage,
    );
  }
}
