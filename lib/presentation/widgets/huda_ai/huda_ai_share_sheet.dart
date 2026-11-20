import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:huda/data/models/counseling_response_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_share_card.dart';
import 'package:huda/presentation/widgets/share/huda_share_sheet.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_image_saver.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareHudaAiAnswer(
  BuildContext context, {
  required String answer,
  String? question,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _open(
    context,
    card: HudaAiShareCard(messageText: answer, question: question),
    aspect: HudaAiShareCard.cardRatio(answer: answer, question: question),
    text: hudaAiAnswerText(l10n, answer: answer, question: question),
    fileName: 'huda_ai_answer',
  );
}

Future<void> shareHudaAiCounsel(
  BuildContext context, {
  required CounselingResponse response,
  String? feeling,
}) {
  final l10n = AppLocalizations.of(context)!;
  return _open(
    context,
    card: CounselingShareCard(response: response, feeling: feeling),
    aspect: CounselingShareCard.cardRatio(response, feeling: feeling),
    text: hudaAiCounselText(l10n, response),
    fileName: 'huda_ai_counsel',
  );
}

String hudaAiAnswerText(
  AppLocalizations l10n, {
  required String answer,
  String? question,
}) => [
  if (question != null && question.trim().isNotEmpty) question.trim(),
  answer.trim(),
  l10n.aiGeneratedDisclaimer,
  l10n.sharedViaHuda,
].join('\n\n');

String hudaAiCounselText(AppLocalizations l10n, CounselingResponse r) {
  String section(String title, List<String> lines) {
    final body = lines.where((line) => line.trim().isNotEmpty).join('\n');
    return body.isEmpty ? '' : '◆ $title\n$body';
  }

  return [
    section(l10n.guidance, [r.counselingText.trim()]),
    section(l10n.quranicWisdom, [
      r.ayah.trim(),
      if (r.ayahTranslation.trim().isNotEmpty) '"${r.ayahTranslation.trim()}"',
      if (r.ayahReference.trim().isNotEmpty) '— ${r.ayahReference.trim()}',
    ]),
    section(l10n.duaa, [
      r.duaa.trim(),
      if (r.duaaTranslation.trim().isNotEmpty) '"${r.duaaTranslation.trim()}"',
    ]),
  ].where((part) => part.isNotEmpty).join('\n\n');
}

Future<void> _open(
  BuildContext context, {
  required Widget card,
  required double aspect,
  required String text,
  required String fileName,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.hudaAiShareAnswer,
    maxDialogWidth: 760,
    builder: (_) => _HudaAiShareSheet(
      screenContext: context,
      card: card,
      aspect: aspect,
      text: text,
      fileName: fileName,
    ),
  );
}

class _HudaAiShareSheet extends StatefulWidget {
  const _HudaAiShareSheet({
    required this.screenContext,
    required this.card,
    required this.aspect,
    required this.text,
    required this.fileName,
  });

  final BuildContext screenContext;
  final Widget card;
  final double aspect;
  final String text;
  final String fileName;

  @override
  State<_HudaAiShareSheet> createState() => _HudaAiShareSheetState();
}

class _HudaAiShareSheetState extends State<_HudaAiShareSheet> {
  Future<Uint8List>? _rendered;
  Timer? _ahead;

  static const _loadingHold = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _ahead = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _render().ignore();
    });
  }

  @override
  void dispose() {
    _ahead?.cancel();
    super.dispose();
  }

  Future<Uint8List> _render() {
    _ahead?.cancel();
    final rendered = _rendered;
    if (rendered != null) return rendered;
    final render = ShareImageCapture.capturePng(
      context: widget.screenContext,
      card: widget.card,
    );
    _rendered = render;
    render.then<void>((_) {}, onError: (Object _) => _rendered = null);
    return render;
  }

  String get _name =>
      '${widget.fileName}_${DateTime.now().millisecondsSinceEpoch}';

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
        fileName: '$_name.png',
        text: l10n.sharedViaHuda,
      ).catchError(failed),
    );
    final rest = _loadingHold - shown.elapsed;
    if (rest > Duration.zero) await Future<void>.delayed(rest);
  }

  void _shareText() {
    final size = MediaQuery.sizeOf(context);
    SharePlus.instance.share(
      ShareParams(
        text: widget.text,
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
      return ShareImageSaver.save(png, name: _name);
    } catch (_) {
      return ShareImageSaveResult.failed;
    }
  }

  @override
  Widget build(BuildContext context) => HudaShareSheetBody(
    card: widget.card,
    cardWidth: HudaAiShareCard.width,
    cardAspect: widget.aspect,
    previewLabel: AppLocalizations.of(context)!.hudaAiShareAnswer,
    onShareImage: _shareImage,
    onShareText: _shareText,
    onSaveImage: _saveImage,
  );
}
