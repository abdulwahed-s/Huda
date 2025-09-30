import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

enum WidgetSize {
  small(160, 160),
  medium(320, 200),
  large(320, 320);

  const WidgetSize(this.width, this.height);
  final double width;
  final double height;
}

class HomeWidgetRenderer {
  static final WidgetsToImageController _controller =
      WidgetsToImageController();

  static Future<String?> generateWidgetImage({
    required String ayah,
    required String surahName,
    required String verseNumber,
    required String themeName,
    required bool isDarkMode,
    WidgetSize size = WidgetSize.medium,
    String? timestamp,
  }) async {
    try {
      debugPrint('🎨 Starting widget image generation...');
      debugPrint('📝 Ayah: $ayah');
      debugPrint('🎨 Theme: $themeName, Dark: $isDarkMode');
      debugPrint('📏 Widget size: ${size.name} (${size.width}x${size.height})');

      final Uint8List? bytes = await _controller.capturePng(
        pixelRatio: _getPixelRatioForSize(size),
        waitForAnimations: true,
      );

      if (bytes == null) {
        debugPrint('❌ Failed to capture home widget image - bytes is null');
        return null;
      }

      debugPrint('✅ Successfully captured image: ${bytes.length} bytes');

      final String fileName =
          'home_widget_${DateTime.now().millisecondsSinceEpoch}.png';
      final String? filePath = await _saveImageToFile(bytes, fileName);

      if (filePath != null) {
        debugPrint('💾 Image saved to: $filePath');
      } else {
        debugPrint('❌ Failed to save image to file');
      }

      return filePath;
    } catch (e) {
      debugPrint('💥 Error generating home widget image: $e');
      return null;
    }
  }

  static Widget buildHomeWidget({
    required String ayah,
    required String surahName,
    required String verseNumber,
    required String themeName,
    required bool isDarkMode,
    WidgetSize size = WidgetSize.medium,
    String? timestamp,
  }) {
    return WidgetsToImage(
      controller: _controller,
      child: _HomeWidgetContent(
        ayah: ayah,
        surahName: surahName,
        verseNumber: verseNumber,
        themeName: themeName,
        isDarkMode: isDarkMode,
        timestamp: timestamp ?? 'آخر تحديث: الآن',
        widgetSize: size,
      ),
    );
  }

  static Future<String?> _saveImageToFile(
      Uint8List imageBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving widget image file: $e');
      return null;
    }
  }

  static Future<void> cleanupOldImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();

      final now = DateTime.now();
      for (final file in files) {
        if (file is File && file.path.contains('home_widget_')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          if (age.inHours > 24) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }

  static void dispose() {
    _controller.dispose();
  }

  static double _getPixelRatioForSize(WidgetSize size) {
    switch (size) {
      case WidgetSize.small:
        return 2.0;
      case WidgetSize.medium:
        return 3.0;
      case WidgetSize.large:
        return 3.5;
    }
  }
}

class _HomeWidgetContent extends StatelessWidget {
  final String ayah;
  final String surahName;
  final String verseNumber;
  final String themeName;
  final bool isDarkMode;
  final String timestamp;
  final WidgetSize widgetSize;

  const _HomeWidgetContent({
    required this.ayah,
    required this.surahName,
    required this.verseNumber,
    required this.themeName,
    required this.isDarkMode,
    required this.timestamp,
    this.widgetSize = WidgetSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors(themeName, isDarkMode);
    final config = _getConfigForSize(widgetSize);

    return Container(
      width: widgetSize.width,
      height: widgetSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.background,
            colors.background.withValues(alpha: 0.95),
            colors.backgroundSecondary,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(config.borderRadius),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.2),
            blurRadius: config.shadowBlur,
            offset: Offset(0, config.shadowOffset),
          ),
        ],
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.3),
          width: config.borderWidth,
        ),
      ),
      child: Stack(
        children: [
          if (widgetSize != WidgetSize.small)
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPatternPainter(
                  color: colors.accent.withValues(alpha: 0.1),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(config.padding),
            child: _buildContentForSize(colors, config),
          ),
        ],
      ),
    );
  }

  Widget _buildContentForSize(_ThemeColors colors, _WidgetConfig config) {
    switch (widgetSize) {
      case WidgetSize.small:
        return _buildSmallContent(colors, config);
      case WidgetSize.medium:
        return _buildMediumContent(colors, config);
      case WidgetSize.large:
        return _buildLargeContent(colors, config);
    }
  }

  Widget _buildSmallContent(_ThemeColors colors, _WidgetConfig config) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Huda',
          style: TextStyle(
            fontFamily: 'Ciguatera',
            fontSize: config.titleFontSize,
            fontWeight: FontWeight.w600,
            color: colors.accent,
          ),
        ),
        SizedBox(height: config.spacing),
        Expanded(
          child: Center(
            child: Text(
              ayah.length > 50 ? '${ayah.substring(0, 50)}...' : ayah,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: config.ayahFontSize,
                fontWeight: FontWeight.bold,
                color: colors.text,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumContent(_ThemeColors colors, _WidgetConfig config) {
    return Column(
      children: [
        _buildHeader(colors, config),
        SizedBox(height: config.spacing),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(config.cardPadding),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(config.cardBorderRadius),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                ayah,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: config.ayahFontSize,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                  height: 1.4,
                  letterSpacing: 0.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        SizedBox(height: config.spacing / 2),
        _buildFooter(colors, config),
      ],
    );
  }

  Widget _buildLargeContent(_ThemeColors colors, _WidgetConfig config) {
    return Column(
      children: [
        _buildHeader(colors, config),
        SizedBox(height: config.spacing),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(config.cardPadding),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(config.cardBorderRadius),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    ayah,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: config.ayahFontSize,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: config.spacing),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$surahName - آية $verseNumber',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: config.spacing),
        _buildFooter(colors, config),
      ],
    );
  }

  Widget _buildHeader(_ThemeColors colors, _WidgetConfig config) {
    if (widgetSize == WidgetSize.small) {
      return Container();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: config.decorativeWidth,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.accent.withValues(alpha: 0.3),
                colors.accent,
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(width: config.spacing),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: config.headerPadding,
            vertical: config.headerPadding / 2,
          ),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Huda',
            style: TextStyle(
              fontFamily: 'Ciguatera',
              fontSize: config.titleFontSize,
              fontWeight: FontWeight.w600,
              color: colors.accent,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SizedBox(width: config.spacing),
        Container(
          width: config.decorativeWidth,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.accent,
                colors.accent.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(_ThemeColors colors, _WidgetConfig config) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: config.footerWidth,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.accent.withValues(alpha: 0.2),
                colors.accent.withValues(alpha: 0.6),
                colors.accent.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  _WidgetConfig _getConfigForSize(WidgetSize size) {
    switch (size) {
      case WidgetSize.small:
        return const _WidgetConfig(
          padding: 12.0,
          spacing: 6.0,
          borderRadius: 16.0,
          borderWidth: 1.0,
          shadowBlur: 4.0,
          shadowOffset: 2.0,
          titleFontSize: 14.0,
          ayahFontSize: 11.0,
          cardPadding: 8.0,
          cardBorderRadius: 12.0,
          headerPadding: 8.0,
          decorativeWidth: 20.0,
          footerWidth: 30.0,
        );
      case WidgetSize.medium:
        return const _WidgetConfig(
          padding: 20.0,
          spacing: 12.0,
          borderRadius: 20.0,
          borderWidth: 1.5,
          shadowBlur: 8.0,
          shadowOffset: 4.0,
          titleFontSize: 18.0,
          ayahFontSize: 14.0,
          cardPadding: 12.0,
          cardBorderRadius: 16.0,
          headerPadding: 16.0,
          decorativeWidth: 40.0,
          footerWidth: 60.0,
        );
      case WidgetSize.large:
        return const _WidgetConfig(
          padding: 24.0,
          spacing: 16.0,
          borderRadius: 24.0,
          borderWidth: 2.0,
          shadowBlur: 12.0,
          shadowOffset: 6.0,
          titleFontSize: 22.0,
          ayahFontSize: 16.0,
          cardPadding: 16.0,
          cardBorderRadius: 20.0,
          headerPadding: 20.0,
          decorativeWidth: 60.0,
          footerWidth: 80.0,
        );
    }
  }

  _ThemeColors _getThemeColors(String themeName, bool isDarkMode) {
    if (isDarkMode) {
      switch (themeName) {
        case 'green':
          return _ThemeColors(
            background: const Color(0xFF0A1F0A),
            backgroundSecondary: const Color(0xFF0F2A0F),
            cardBackground: const Color(0xFF1A3A1A).withValues(alpha: 0.7),
            accent: const Color(0xFF4ADE80),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
        case 'blue':
          return _ThemeColors(
            background: const Color(0xFF0A1A2F),
            backgroundSecondary: const Color(0xFF0F2040),
            cardBackground: const Color(0xFF1A3A5F).withValues(alpha: 0.7),
            accent: const Color(0xFF60A5FA),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
        case 'red':
          return _ThemeColors(
            background: const Color(0xFF2F0A0A),
            backgroundSecondary: const Color(0xFF400F0F),
            cardBackground: const Color(0xFF5F1A1A).withValues(alpha: 0.7),
            accent: const Color(0xFFF87171),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
        case 'orange':
          return _ThemeColors(
            background: const Color(0xFF2F1A0A),
            backgroundSecondary: const Color(0xFF40250F),
            cardBackground: const Color(0xFF5F3A1A).withValues(alpha: 0.7),
            accent: const Color(0xFFFB923C),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
        case 'teal':
          return _ThemeColors(
            background: const Color(0xFF0A2F2F),
            backgroundSecondary: const Color(0xFF0F4040),
            cardBackground: const Color(0xFF1A5F5F).withValues(alpha: 0.7),
            accent: const Color(0xFF5EEAD4),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
        case 'indigo':
          return _ThemeColors(
            background: const Color(0xFF0F0A2F),
            backgroundSecondary: const Color(0xFF1A0F40),
            cardBackground: const Color(0xFF2F1A5F).withValues(alpha: 0.7),
            accent: const Color(0xFF818CF8),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
        case 'pink':
          return _ThemeColors(
            background: const Color(0xFF2F0A2A),
            backgroundSecondary: const Color(0xFF400F35),
            cardBackground: const Color(0xFF5F1A4F).withValues(alpha: 0.7),
            accent: const Color(0xFFF472B6),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
        case 'purple':
        default:
          return _ThemeColors(
            background: const Color(0xFF1A0F1C),
            backgroundSecondary: const Color(0xFF251A27),
            cardBackground: const Color(0xFF3A2A3F).withValues(alpha: 0.7),
            accent: const Color(0xFFA78BFA),
            text: const Color(0xFFFFFFFF),
            textSecondary: const Color(0xFFBBBBBB),
          );
      }
    } else {
      switch (themeName) {
        case 'green':
          return _ThemeColors(
            background: const Color(0xFFF0FDF4),
            backgroundSecondary: const Color(0xFFDCFCE7),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFF16A34A),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
        case 'blue':
          return _ThemeColors(
            background: const Color(0xFFEFF6FF),
            backgroundSecondary: const Color(0xFFDBEAFE),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFF2563EB),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
        case 'red':
          return _ThemeColors(
            background: const Color(0xFFFEF2F2),
            backgroundSecondary: const Color(0xFFFECACA),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFFDC2626),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
        case 'orange':
          return _ThemeColors(
            background: const Color(0xFFFFF7ED),
            backgroundSecondary: const Color(0xFFFFEDD5),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFFEA580C),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
        case 'teal':
          return _ThemeColors(
            background: const Color(0xFFF0FDFA),
            backgroundSecondary: const Color(0xFFCCFBF1),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFF0D9488),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
        case 'indigo':
          return _ThemeColors(
            background: const Color(0xFFEEF2FF),
            backgroundSecondary: const Color(0xFFE0E7FF),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFF4F46E5),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
        case 'pink':
          return _ThemeColors(
            background: const Color(0xFFFDF2F8),
            backgroundSecondary: const Color(0xFFFCE7F3),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFFDB2777),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
        case 'purple':
        default:
          return _ThemeColors(
            background: const Color(0xFFFAF5FF),
            backgroundSecondary: const Color(0xFFF3E8FF),
            cardBackground: const Color(0xFFFFFFFF).withValues(alpha: 0.9),
            accent: const Color(0xFF7C3AED),
            text: const Color(0xFF1A1A1A),
            textSecondary: const Color(0xFF666666),
          );
      }
    }
  }
}

class _WidgetConfig {
  final double padding;
  final double spacing;
  final double borderRadius;
  final double borderWidth;
  final double shadowBlur;
  final double shadowOffset;
  final double titleFontSize;
  final double ayahFontSize;
  final double cardPadding;
  final double cardBorderRadius;
  final double headerPadding;
  final double decorativeWidth;
  final double footerWidth;

  const _WidgetConfig({
    required this.padding,
    required this.spacing,
    required this.borderRadius,
    required this.borderWidth,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.titleFontSize,
    required this.ayahFontSize,
    required this.cardPadding,
    required this.cardBorderRadius,
    required this.headerPadding,
    required this.decorativeWidth,
    required this.footerWidth,
  });
}

class _ThemeColors {
  final Color background;
  final Color backgroundSecondary;
  final Color cardBackground;
  final Color accent;
  final Color text;
  final Color textSecondary;

  const _ThemeColors({
    required this.background,
    required this.backgroundSecondary,
    required this.cardBackground,
    required this.accent,
    required this.text,
    required this.textSecondary,
  });
}

class _BackgroundPatternPainter extends CustomPainter {
  final Color color;

  _BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.15), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.85), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 10, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 12, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
