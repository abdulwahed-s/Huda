import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:huda/l10n/app_localizations.dart';

class ShareImageOverlay {
  static Future<void> shareAsImage({
    required BuildContext context,
    required String messageText,
    required AppLocalizations appLocalizations,
    required Function(dynamic) onError,
    required Function() onComplete,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    try {
      final GlobalKey shareKey = GlobalKey();
      OverlayEntry? overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => _buildOverlayContent(
          shareKey: shareKey,
          isDark: isDark,
          colorScheme: colorScheme,
          messageText: messageText,
          appLocalizations: appLocalizations,
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 200));

      final RenderRepaintBoundary boundary =
          shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      overlayEntry.remove();

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'huda_ai_response_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: appLocalizations.shareTextHudaAI,
      ));
    } catch (e) {
      if (context.mounted) {
        scaffoldMessengerState.showSnackBar(
          SnackBar(
            content: Text(
              '${appLocalizations.error}: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
          ),
        );
      }
      onError(e);
    } finally {
      onComplete();
    }
  }

  static Widget _buildOverlayContent({
    required GlobalKey shareKey,
    required bool isDark,
    required ColorScheme colorScheme,
    required String messageText,
    required AppLocalizations appLocalizations,
  }) {
    return Positioned(
      top: -2000,
      left: 0,
      child: RepaintBoundary(
        key: shareKey,
        child: Material(
          color: Colors.transparent,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF1A1A2E),
                          const Color(0xFF16213E),
                        ]
                      : [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(204),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(appLocalizations),
                  const SizedBox(height: 24),
                  _buildMessageContent(messageText, isDark, colorScheme),
                  const SizedBox(height: 20),
                  _buildFooter(appLocalizations),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildHeader(AppLocalizations appLocalizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Huda AI',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizations.islamicAssistant,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  static Widget _buildMessageContent(
    String messageText,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Markdown(
        data: messageText,
        selectable: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            height: 1.8,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
          h1: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            height: 1.6,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          h2: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            height: 1.6,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          h3: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            height: 1.6,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          strong: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            height: 1.8,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          em: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            height: 1.8,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            fontStyle: FontStyle.italic,
          ),
          listBullet: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            height: 1.8,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
          code: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            height: 1.6,
            color: isDark ? const Color(0xFF1A1A2E) : colorScheme.primary,
            backgroundColor: Colors.grey.withAlpha(25),
          ),
          blockquote: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16,
            height: 1.8,
            color: (isDark ? const Color(0xFF1A1A2E) : colorScheme.primary)
                .withAlpha(204),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  static Widget _buildFooter(AppLocalizations appLocalizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(51),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              appLocalizations.aiGeneratedDisclaimer,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.mosque,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}