import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/mushaf_pack_service.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/surah/quran_mushaf_page_view.dart';
import 'package:huda/presentation/widgets/surah/quran_font_option_tile.dart';
import 'package:huda/presentation/widgets/surah/reading_mode_option_card.dart';
import 'package:huda/presentation/widgets/surah/settings_section_header.dart';
import 'package:huda/presentation/widgets/surah/surah_segmented_control.dart';

class SettingsTab extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final QuranReadingMode readingMode;
  final HorizontalPageDisplayMode horizontalDisplayMode;
  final MushafFlipDirection mushafFlipDirection;
  final String quranFont;
  final List<Map<String, String>> fontOptions;

  final MushafPackService? hafsPackService;
  final MushafPackService? tajweedPackService;
  final MushafPackService? indopakPackService;

  final void Function(
    QuranReadingMode mode,
    MushafPackService? packService,
    bool requiresPack,
  )
  onReadingModeTap;

  final ValueChanged<HorizontalPageDisplayMode> onHorizontalDisplayModeSelected;
  final ValueChanged<MushafFlipDirection> onMushafFlipDirectionSelected;
  final ValueChanged<String> onFontSelected;

  const SettingsTab({
    super.key,
    required this.isDark,
    required this.accent,
    required this.readingMode,
    required this.horizontalDisplayMode,
    required this.mushafFlipDirection,
    required this.quranFont,
    required this.fontOptions,
    required this.onReadingModeTap,
    required this.onHorizontalDisplayModeSelected,
    required this.onMushafFlipDirectionSelected,
    required this.onFontSelected,
    this.hafsPackService,
    this.tajweedPackService,
    this.indopakPackService,
  });

  MushafPackService? _packServiceFor(QuranReadingMode mode) {
    switch (mode) {
      case QuranReadingMode.scrollList:
        return null;
      case QuranReadingMode.horizontalPages:
        return hafsPackService;
      case QuranReadingMode.tajweed:
        return tajweedPackService;
      case QuranReadingMode.indopak:
        return indopakPackService;
    }
  }

  Widget _modeCard(BuildContext context, QuranReadingMode mode) {
    final packService = _packServiceFor(mode);
    return ReadingModeOptionCard(
      icon: mode.icon,
      label: mode.localizedLabel(context),
      isSelected: readingMode == mode,
      requiresPack: mode.isMushaf,
      isDark: isDark,
      accent: accent,
      packService: packService,
      onTap: () => onReadingModeTap(mode, packService, mode.isMushaf),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(
            title: l.settingsReadingMode,
            icon: Icons.import_contacts_rounded,
            isDark: isDark,
            accent: accent,
          ),
          SizedBox(height: 12.h),
          for (final row in const [
            [QuranReadingMode.scrollList, QuranReadingMode.horizontalPages],
            [QuranReadingMode.tajweed, QuranReadingMode.indopak],
          ]) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _modeCard(context, row[0])),
                  SizedBox(width: 10.w),
                  Expanded(child: _modeCard(context, row[1])),
                ],
              ),
            ),
            if (row.first == QuranReadingMode.scrollList)
              SizedBox(height: 10.h),
          ],
          if (readingMode.isMushaf) ...[
            SettingsSectionHeader(
              title: l.settingsHorizontalLayout,
              icon: Icons.view_column_rounded,
              isDark: isDark,
              accent: accent,
            ),
            SurahSegmentedControl(
              isDark: isDark,
              accent: accent,
              options: HorizontalPageDisplayMode.values
                  .map(
                    (dm) => SurahSegmentOption(
                      label: dm.localizedLabel(context),
                      icon: dm.icon,
                      isSelected: horizontalDisplayMode == dm,
                      onTap: () => onHorizontalDisplayModeSelected(dm),
                    ),
                  )
                  .toList(),
            ),
            SettingsSectionHeader(
              title: l.settingsFlipDirection,
              icon: Icons.swap_horiz_rounded,
              isDark: isDark,
              accent: accent,
            ),
            SurahSegmentedControl(
              isDark: isDark,
              accent: accent,
              options: MushafFlipDirection.values
                  .map(
                    (fd) => SurahSegmentOption(
                      label: fd.localizedLabel(context),
                      icon: fd.icon,
                      isSelected: mushafFlipDirection == fd,
                      onTap: () => onMushafFlipDirectionSelected(fd),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (readingMode == QuranReadingMode.scrollList) ...[
            SettingsSectionHeader(
              title: l.settingsQuranFont,
              icon: Icons.font_download_rounded,
              isDark: isDark,
              accent: accent,
            ),
            ...fontOptions.map((font) {
              return QuranFontOptionTile(
                fontFamily: font['family']!,
                label: font['label']!,
                isSelected: quranFont == font['family'],
                isDark: isDark,
                accent: accent,
                onTap: () => onFontSelected(font['family']!),
              );
            }),
          ],
        ],
      ),
    );
  }
}
