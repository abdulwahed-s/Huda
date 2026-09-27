import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:huda/presentation/widgets/share/share_image_frame.dart';
import 'package:share_plus/share_plus.dart';

class ShareImageCapture {
  ShareImageCapture._();

  static const double _maxPixelRatio = 3;
  static const double _maxImageSide = 8192;

  static Future<Uint8List> capturePng({
    required BuildContext context,
    required Widget card,
    double width = BrandedShareFrame.width,
    double pixelRatio = _maxPixelRatio,
  }) async {
    await precacheImage(const AssetImage(BrandedShareFrame.logoAsset), context);
    if (!context.mounted) {
      throw StateError('Share image context is no longer mounted');
    }

    final shareKey = GlobalKey();
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: -100000,
        left: 0,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          fit: OverflowBoxFit.deferToChild,
          minWidth: width,
          maxWidth: width,
          maxHeight: double.infinity,
          child: RepaintBoundary(
            key: shareKey,
            child: MediaQuery.withNoTextScaling(child: card),
          ),
        ),
      ),
    );

    try {
      Overlay.of(context).insert(entry);
      await WidgetsBinding.instance.endOfFrame;

      final boundary = shareKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Share image could not be rendered');
      }

      final longestSide = math.max(boundary.size.width, boundary.size.height);
      final effectiveRatio = math.min(pixelRatio, _maxImageSide / longestSide);
      final image = await boundary.toImage(pixelRatio: effectiveRatio);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw StateError('Share image could not be encoded');
        }
        return bytes.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      entry.remove();
      entry.dispose();
    }
  }

  static Future<void> share({
    required BuildContext context,
    required Widget card,
    required String fileName,
    required String text,
    String? subject,
  }) async {
    final pngBytes = await capturePng(context: context, card: card);
    if (!context.mounted) return;

    final screenSize = MediaQuery.of(context).size;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(pngBytes, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
        text: text,
        subject: subject,
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 1,
          height: 1,
        ),
      ),
    );
  }
}
