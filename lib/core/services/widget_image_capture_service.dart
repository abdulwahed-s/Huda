import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

class WidgetImageCaptureService {
  static final WidgetsToImageController _controller =
      WidgetsToImageController();

  /// Generate and capture widget image with Uthmanic font
  static Future<String?> captureWidgetImage({
    required String text,
    required String themeName,
    required bool isDarkMode,
    String? primaryColor,
    String? accentColor,
  }) async {
    try {
      // Capture the widget with high quality
      final Uint8List? bytes = await _controller.capturePng(
        pixelRatio: 3.0,
        waitForAnimations: true,
      );

      if (bytes == null) {
        debugPrint('Failed to capture widget image');
        return null;
      }

      // Save the image to file
      final String fileName =
          'widget_text_${DateTime.now().millisecondsSinceEpoch}.png';
      final String? filePath = await _saveImageToFile(bytes, fileName);

      return filePath;
    } catch (e) {
      debugPrint('Error capturing widget image: $e');
      return null;
    }
  }

  /// Build the widget content for capturing
  static Widget buildWidgetContent({
    required String text,
    required String themeName,
    required bool isDarkMode,
    String? primaryColor,
    String? accentColor,
  }) {
    return WidgetsToImage(
      controller: _controller,
      child: _WidgetImageContent(
        text: text,
        themeName: themeName,
        isDarkMode: isDarkMode,
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );
  }

  /// Save image bytes to a file
  static Future<String?> _saveImageToFile(
      Uint8List imageBytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving image file: $e');
      return null;
    }
  }

  /// Get the background color based on theme
  static Color _getBackgroundColor(String themeName, bool isDarkMode) {
    if (isDarkMode) {
      switch (themeName) {
        case 'green':
          return const Color(0xFF0A1F0A);
        case 'blue':
          return const Color(0xFF0A1A2F);
        case 'red':
          return const Color(0xFF2F0A0A);
        case 'orange':
          return const Color(0xFF2F1A0A);
        case 'teal':
          return const Color(0xFF0A2F2F);
        case 'indigo':
          return const Color(0xFF0F0A2F);
        case 'pink':
          return const Color(0xFF2F0A2A);
        case 'purple':
        default:
          return const Color(0xFF1A0F1C);
      }
    } else {
      switch (themeName) {
        case 'green':
          return const Color(0xFFF0FDF4);
        case 'blue':
          return const Color(0xFFEFF6FF);
        case 'red':
          return const Color(0xFFFEF2F2);
        case 'orange':
          return const Color(0xFFFFF7ED);
        case 'teal':
          return const Color(0xFFF0FDFA);
        case 'indigo':
          return const Color(0xFFEEF2FF);
        case 'pink':
          return const Color(0xFFFDF2F8);
        case 'purple':
        default:
          return const Color(0xFFFAF5FF);
      }
    }
  }

  /// Get theme accent color
  static Color _getAccentColor(String themeName) {
    switch (themeName) {
      case 'green':
        return const Color(0xFF22C55E);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'red':
        return const Color(0xFFEF4444);
      case 'orange':
        return const Color(0xFFF97316);
      case 'teal':
        return const Color(0xFF14B8A6);
      case 'indigo':
        return const Color(0xFF6366F1);
      case 'pink':
        return const Color(0xFFEC4899);
      case 'purple':
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  /// Dispose the controller
  static void dispose() {
    _controller.dispose();
  }
}

/// Widget that represents the content to be rendered as an image
class _WidgetImageContent extends StatelessWidget {
  final String text;
  final String themeName;
  final bool isDarkMode;
  final String? primaryColor;
  final String? accentColor;

  const _WidgetImageContent({
    required this.text,
    required this.themeName,
    required this.isDarkMode,
    this.primaryColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        WidgetImageCaptureService._getBackgroundColor(themeName, isDarkMode);
    final accentColorValue =
        WidgetImageCaptureService._getAccentColor(themeName);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1A1A);

    return Container(
      width: 320.0,
      height: 200.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColorValue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header with decorative elements
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: accentColorValue,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '🕌',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                'هُدى',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accentColorValue,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: accentColorValue,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main text with Uthmanic font
          Expanded(
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'uthmanic', // Beautiful Uthmanic font!
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.6,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Footer decorative line
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColorValue.withValues(alpha: 0.6),
                  accentColorValue.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
