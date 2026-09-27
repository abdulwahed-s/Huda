import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:huda/presentation/widgets/athkar%20details/athkar_share_card.dart';
import 'package:huda/presentation/widgets/share/share_image_capture.dart';
import 'package:huda/presentation/widgets/share/share_options_bottom_sheet.dart';

class AthkarShareHandler {
  final BuildContext context;
  final Map<int, GlobalKey> athkarCardKeys;
  final ValueChanged<bool> onGeneratingStateChanged;
  final String title;
  final String titleEn;

  bool isGeneratingImage = false;

  AthkarShareHandler({
    required this.context,
    required this.athkarCardKeys,
    required this.onGeneratingStateChanged,
    required this.title,
    required this.titleEn,
  });

  String get currentLanguageCode =>
      context.read<LocalizationCubit>().state.locale.languageCode;

  String get localizedTitle =>
      currentLanguageCode == 'ar' || titleEn.trim().isEmpty ? title : titleEn;

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
    final localizations = AppLocalizations.of(context)!;
    final shareText =
        """
${athkar.arabicText ?? ''}

${athkar.translatedText ?? ''}

${localizations.athkarShareRepeatCount(athkar.repeat ?? 0)}

${localizations.sharedViaHuda}
""";

    final screenSize = MediaQuery.of(context).size;
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 1,
          height: 1,
        ),
      ),
    );
  }

  Future<void> _shareAsImage(int index) async {
    _updateGeneratingState(true);

    try {
      final state = context.read<AthkarDetailsCubit>().state;
      if (state is! AthkarDetailsLoaded) return;

      final athkar = state.athkarCategory.details[index];
      await ShareImageCapture.share(
        context: context,
        card: AthkarShareCard(
          title: localizedTitle,
          arabicText: athkar.arabicText ?? '',
          translatedText: currentLanguageCode == 'ar'
              ? null
              : athkar.translatedText,
          repeatCount: athkar.repeat ?? 1,
        ),
        fileName: 'athkar_$index.png',
        text:
            '$localizedTitle\n\n${AppLocalizations.of(context)!.sharedViaHuda}',
      );
    } catch (e) {
      _showShareErrorSnackbar(e.toString());
    } finally {
      _updateGeneratingState(false);
    }
  }

  void _updateGeneratingState(bool isGenerating) {
    isGeneratingImage = isGenerating;
    onGeneratingStateChanged(isGenerating);
  }

  void _showShareErrorSnackbar(String error) {
    HudaSnackBar.error(
      context,
      message: AppLocalizations.of(context)!.failedToShareImage,
    );
  }
}
