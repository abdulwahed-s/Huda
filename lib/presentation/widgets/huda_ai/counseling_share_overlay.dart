import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/data/models/counseling_response_model.dart';

class CounselingShareOverlay {
  static Future<void> shareAsImage({
    required BuildContext context,
    required CounselingResponse response,
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
          response: response,
          appLocalizations: appLocalizations,
        ),
      );

      Overlay.of(context).insert(overlayEntry);
      await Future.delayed(const Duration(milliseconds: 300));

      final RenderRepaintBoundary boundary =
          shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      overlayEntry.remove();

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'huda_counseling_${DateTime.now().millisecondsSinceEpoch}.png';
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
    required CounselingResponse response,
    required AppLocalizations appLocalizations,
  }) {
    return Positioned(
      top: -5000,
      left: 0,
      child: RepaintBoundary(
        key: shareKey,
        child: Material(
          color: Colors.transparent,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              width: 450,
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
                  _buildGuidanceCard(response.counselingText),
                  const SizedBox(height: 16),
                  _buildQuranCard(
                    response.ayah,
                    response.ayahTranslation,
                    response.ayahReference,
                  ),
                  const SizedBox(height: 16),
                  _buildDuaaCard(
                    response.duaa,
                    response.duaaTranslation,
                  ),
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
                  Icons.psychology,
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
          const Text(
            'Counseling Mode',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildGuidanceCard(String content) {
    return _buildSectionCard(
      title: 'Guidance',
      icon: Icons.light_mode,
      content: content,
      gradientColors: const [Color(0xFF00897B), Color(0xFF00BFA5)],
    );
  }

  static Widget _buildQuranCard(
    String ayah,
    String translation,
    String reference,
  ) {
    return _buildSectionCard(
      title: 'Quranic Wisdom',
      icon: Icons.menu_book,
      content: ayah,
      subContent: translation.isNotEmpty ? translation : null,
      footer: reference,
      gradientColors: const [Color(0xFF3949AB), Color(0xFF5E35B1)],
    );
  }

  static Widget _buildDuaaCard(String duaa, String translation) {
    return _buildSectionCard(
      title: 'Duaa',
      icon: Icons.favorite,
      content: duaa,
      subContent: translation.isNotEmpty ? translation : null,
      gradientColors: const [Color(0xFFC2185B), Color(0xFFD81B60)],
    );
  }

  static Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String content,
    String? subContent,
    String? footer,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: gradientColors[0],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(
            height: 2,
            width: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 12),
          // Content
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              height: 1.8,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500,
            ),
          ),
          // Translation
          if (subContent != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gradientColors[0].withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: gradientColors[0].withAlpha(51),
                ),
              ),
              child: Text(
                '"$subContent"',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  height: 1.7,
                  color: gradientColors[0],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          // Footer reference
          if (footer != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors[0].withAlpha(38),
                      gradientColors[1].withAlpha(38),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  footer,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: gradientColors[0],
                  ),
                ),
              ),
            ),
          ],
        ],
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
