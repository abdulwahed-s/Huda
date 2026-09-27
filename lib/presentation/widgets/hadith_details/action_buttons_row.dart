import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/hadith_text_formatter.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith_details/action_button.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_share_image.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/share/share_options_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';

class ActionButtonsRow extends StatefulWidget {
  final String hadithBody;
  final String status;
  final bool isDark;
  final String chapterName;
  final String languageCode;

  const ActionButtonsRow({
    super.key,
    required this.hadithBody,
    required this.status,
    required this.isDark,
    required this.chapterName,
    required this.languageCode,
  });

  @override
  State<ActionButtonsRow> createState() => _ActionButtonsRowState();
}

class _ActionButtonsRowState extends State<ActionButtonsRow> {
  bool _isGeneratingImage = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.0.h),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isGeneratingImage)
            SizedBox(
              width: 44.w,
              height: 44.h,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            ActionButton(
              icon: Icons.share_outlined,
              onPressed: _showShareOptions,
              isDark: widget.isDark,
            ),
          SizedBox(width: 8.0.w),
          ActionButton(
            icon: Icons.copy_outlined,
            onPressed: _copyHadith,
            isDark: widget.isDark,
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ShareOptionsBottomSheet(
        title: AppLocalizations.of(sheetContext)!.shareOptions,
        isGeneratingImage: _isGeneratingImage,
        onShareText: () {
          Navigator.of(sheetContext).pop();
          _shareHadithAsText();
        },
        onShareImage: () {
          Navigator.of(sheetContext).pop();
          _shareHadithAsImage();
        },
      ),
    );
  }

  Future<void> _shareHadithAsText() async {
    try {
      final formattedText = _formatHadithForSharing(context);
      final screenSize = MediaQuery.of(context).size;
      await SharePlus.instance.share(
        ShareParams(
          text: formattedText,
          subject: widget.chapterName,
          sharePositionOrigin: Rect.fromCenter(
            center: Offset(screenSize.width / 2, screenSize.height / 2),
            width: 1,
            height: 1,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToShareText,
          HudaSnackBarKind.error,
        );
      }
    }
  }

  Future<void> _shareHadithAsImage() async {
    if (_isGeneratingImage) return;
    setState(() => _isGeneratingImage = true);

    try {
      await HadithShareImage.share(
        context: context,
        chapterName: widget.chapterName,
        hadithBody: widget.hadithBody,
        status: widget.status.isEmpty
            ? ''
            : _getTranslatedStatus(context, widget.status),
        languageCode: widget.languageCode,
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToShareImage,
          HudaSnackBarKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }

  Future<void> _copyHadith() async {
    try {
      HapticFeedback.lightImpact();
      final formattedText = _formatHadithForSharing(context);
      await Clipboard.setData(ClipboardData(text: formattedText));
      if (mounted) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.messageCopied,
          HudaSnackBarKind.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToCopy,
          HudaSnackBarKind.error,
        );
      }
    }
  }

  String _formatHadithForSharing(BuildContext context) {
    final hadithText = HadithTextFormatter.format(widget.hadithBody).plainText;
    final title = HadithTextFormatter.format(widget.chapterName).plainText;
    final localizations = AppLocalizations.of(context)!;
    final statusLine = widget.status.trim().isEmpty
        ? ''
        : '\n\n🔍 ${localizations.status}: ${_getTranslatedStatus(context, widget.status)}';

    return '''📖 $title

$hadithText$statusLine

---
${localizations.sharedViaHuda}
'''
        .trim();
  }

  String _getTranslatedStatus(BuildContext context, String status) {
    switch (status) {
      case 'Sahih':
      case 'sahih':
        return AppLocalizations.of(context)!.sahih;
      case 'Da`eef':
      case 'da`eef':
        return AppLocalizations.of(context)!.daif;
      case 'Hasan':
      case 'hasan':
        return AppLocalizations.of(context)!.hasan;
      default:
        return status;
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    HudaSnackBarKind kind,
  ) {
    HudaSnackBar.show(context, message: message, kind: kind);
  }
}
