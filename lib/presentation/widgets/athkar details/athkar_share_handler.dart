import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/athkar_detail_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_image_arabic_text.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_image_footer.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_image_header.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_image_translation.dart';
import 'package:huda/presentation/widgets/athkar%20details/share_options_bottom_sheet.dart';

class AthkarShareHandler {
  final BuildContext context;
  final Map<int, GlobalKey> athkarCardKeys;
  final ValueChanged<bool> onGeneratingStateChanged;
  final String title;

  bool isGeneratingImage = false;

  AthkarShareHandler({
    required this.context,
    required this.athkarCardKeys,
    required this.onGeneratingStateChanged,
    required this.title,
  });

  String get currentLanguageCode =>
      context.read<LocalizationCubit>().state.locale.languageCode;

  void showShareOptions(int index) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ShareOptionsBottomSheet(
          isGeneratingImage: isGeneratingImage,
          onShareText: () {
            Navigator.pop(context);
            _shareAsText(index);
          },
          onShareImage: () {
            Navigator.pop(context);
            _shareAsImage(index);
          },
        );
      },
    );
  }

  Future<void> _shareAsText(int index) async {
    final state = context.read<AthkarDetailsCubit>().state;
    if (state is! AthkarDetailsLoaded) return;

    final athkar = state.athkarCategory.details[index];
    final shareText = """
${athkar.arabicText ?? ''}

${athkar.translatedText ?? ''}

${"عدد التكرار: ${athkar.repeat}"}
""";

    await Share.share(shareText);
  }

  Future<void> _shareAsImage(int index) async {
    _updateGeneratingState(true);

    try {
      final state = context.read<AthkarDetailsCubit>().state;
      if (state is! AthkarDetailsLoaded) return;

      final athkar = state.athkarCategory.details[index];
      final colorScheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      final imageBytes = await _captureShareImage(
          athkar: athkar,
          colorScheme: colorScheme,
          isDark: isDark,
          title: title);

      final file = await _saveImageToTempFile(imageBytes, index);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'مشاركة الأذكار - ${state.athkarCategory.title}',
      );
    } catch (e) {
      _showShareErrorSnackbar(e.toString());
    } finally {
      _updateGeneratingState(false);
    }
  }

  Future<Uint8List> _captureShareImage({
    required String title,
    required AthkarDetailModel athkar,
    required ColorScheme colorScheme,
    required bool isDark,
  }) async {
    final GlobalKey shareKey = GlobalKey();
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
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
                            colorScheme.primary.withValues(alpha: 0.8),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShareImageHeader(title: title),
                    const SizedBox(height: 24),
                    ShareImageArabicText(
                      arabicText: athkar.arabicText ?? '',
                      isDark: isDark,
                      colorScheme: colorScheme,
                    ),
                    if (athkar.translatedText != null &&
                        athkar.translatedText!.isNotEmpty &&
                        currentLanguageCode != "ar")
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ShareImageTranslation(
                          translatedText: athkar.translatedText ?? '',
                          isDark: isDark,
                          colorScheme: colorScheme,
                        ),
                      ),
                    const SizedBox(height: 20),
                    ShareImageFooter(
                      repeatCount: athkar.repeat ?? 1,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    await Future.delayed(const Duration(milliseconds: 200));

    final RenderRepaintBoundary boundary =
        shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    overlayEntry.remove();

    return byteData!.buffer.asUint8List();
  }

  Future<File> _saveImageToTempFile(Uint8List pngBytes, int index) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = 'athkar_$index.png';
    final File file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  void _updateGeneratingState(bool isGenerating) {
    isGeneratingImage = isGenerating;
    onGeneratingStateChanged(isGenerating);
  }

  void _showShareErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'فشل في مشاركة الصورة: $error',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
      ),
    );
  }
}
