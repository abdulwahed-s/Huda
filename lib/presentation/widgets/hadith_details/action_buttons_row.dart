import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/data/models/hadith_details_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith_details/action_button.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
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
      final screenSize = MediaQuery.of(context).size;
      await SharePlus.instance.share(ShareParams(
        text: formattedText,
        subject: chapterName,
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 1,
          height: 1,
        ),
      ));
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToShareText,
          HudaSnackBarKind.error,
        );
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
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.messageCopied,
          HudaSnackBarKind.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToCopy,
          HudaSnackBarKind.error,
        );
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
    final index = languageCode == 'ar' ? 1 : 0;

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
    final localizations = AppLocalizations.of(context)!;

    return '''
📖 $chapterName

$hadithText

🔍 ${localizations.status}: $status

---
${localizations.sharedViaHuda}
''';
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
