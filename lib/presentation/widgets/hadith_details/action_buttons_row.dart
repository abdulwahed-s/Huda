import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/hadith_details_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith_details/action_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;

class ActionButtonsRow extends StatelessWidget {
  final Data hadith;
  final bool isDark;
  final String chapterName;
  final BuildContext context;

  const ActionButtonsRow({
    super.key,
    required this.hadith,
    required this.isDark,
    required this.chapterName,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.0.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ActionButton(
            icon: Icons.share_outlined,
            onPressed: () => _shareHadith(context),
            isDark: isDark,
          ),
          SizedBox(width: 8.0.w),
          ActionButton(
            icon: Icons.copy_outlined,
            onPressed: () => _copyHadith(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  void _shareHadith(BuildContext context) async {
    try {
      final currentLanguageCode =
          context.read<LocalizationCubit>().state.locale.languageCode;
      final formattedText = _formatHadithForSharing(currentLanguageCode);
      await SharePlus.instance
          .share(ShareParams(text: formattedText, subject: chapterName));
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getErrorMessage('share', e));
      }
    }
  }

  void _copyHadith(BuildContext context) async {
    try {
      HapticFeedback.lightImpact();
      final currentLanguageCode =
          context.read<LocalizationCubit>().state.locale.languageCode;
      final formattedText = _formatHadithForSharing(currentLanguageCode);
      await Clipboard.setData(ClipboardData(text: formattedText));
      if (context.mounted) {
        _showSnackBar(context, _getSuccessMessage('copy'));
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, _getErrorMessage('copy', e));
      }
    }
  }

  String _cleanCustomTags(String html) {
    String cleaned = html
        .replaceAll('[prematn]', '')
        .replaceAll('[/prematn]', '')
        .replaceAll('[matn]', '')
        .replaceAll('[/matn]', '');

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[narrator[^\]]*\]'),
      (match) => '',
    );
    cleaned = cleaned.replaceAll('[/narrator]', '');

    return cleaned;
  }

  String _formatHadithForSharing(String languageCode) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    int index = currentLanguageCode == "ar" ? 1 : 0;

    final rawHadithHtml = hadith.hadith![index].body!;

    final cleanedHtml = _cleanCustomTags(rawHadithHtml);

    final document = html_parser.parse(cleanedHtml);
    final hadithText = document.body?.text.trim() ?? '';

    final status = _getTranslatedStatus(
        context,
        hadith.hadith?.isNotEmpty == true
            ? hadith.hadith![0].grades?.isNotEmpty == true
                ? hadith.hadith![0].grades![0].grade ?? ""
                : ""
            : "");

    if (languageCode == "ar") {
      return '''
📖 $chapterName

$hadithText

🔍 الحالة: $status

---
مشارك من تطبيق هدى
''';
    } else if (languageCode == "ur") {
      return '''
📖 $chapterName

$hadithText

🔍 حیثیت: $status

---
ہدیٰ ایپ سے شیئر کیا گیا
''';
    } else {
      return '''
📖 $chapterName

$hadithText

🔍 Status: $status

---
Shared from Huda App
''';
    }
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

  String _getSuccessMessage(String action) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    if (action == 'copy') {
      return currentLanguageCode == "ar"
          ? "تم نسخ الحديث إلى الحافظة"
          : currentLanguageCode == "ur"
              ? "حدیث کلپ بورڈ میں کاپی ہو گئی"
              : "Hadith copied to clipboard";
    }
    return '';
  }

  String _getErrorMessage(String action, dynamic error) {
    final currentLanguageCode =
        context.read<LocalizationCubit>().state.locale.languageCode;
    if (action == 'share') {
      return currentLanguageCode == "ar"
          ? "فشل في مشاركة الحديث"
          : currentLanguageCode == "ur"
              ? "حدیث شیئر کرنے میں ناکام"
              : "Failed to share hadith";
    } else if (action == 'copy') {
      return currentLanguageCode == "ar"
          ? "فشل في نسخ الحديث"
          : currentLanguageCode == "ur"
              ? "حدیث کاپی کرنے میں ناکام"
              : "Failed to copy hadith";
    }
    return '';
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.0.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: "Amiri",
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16.0.w),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}
