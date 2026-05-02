import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/qcf_font_service.dart';
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

  final QcfFontService? qcf4FontService;
  final QcfFontService? tajweedFontService;

  final void Function(
    QuranReadingMode mode,
    QcfFontService? fontService,
    bool requiresFonts,
  ) onReadingModeTap;

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
    this.qcf4FontService,
    this.tajweedFontService,
  });

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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ReadingModeOptionCard(
                    icon: QuranReadingMode.scrollList.icon,
                    label: QuranReadingMode.scrollList.localizedLabel(context),
                    isSelected: readingMode == QuranReadingMode.scrollList,
                    requiresFonts: false,
                    isDark: isDark,
                    accent: accent,
                    onTap: () => onReadingModeTap(
                      QuranReadingMode.scrollList,
                      null,
                      false,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ReadingModeOptionCard(
                    icon: QuranReadingMode.horizontalPages.icon,
                    label: QuranReadingMode.horizontalPages
                        .localizedLabel(context),
                    isSelected: readingMode == QuranReadingMode.horizontalPages,
                    requiresFonts: true,
                    isDark: isDark,
                    accent: accent,
                    fontService: qcf4FontService,
                    onTap: () => onReadingModeTap(
                      QuranReadingMode.horizontalPages,
                      qcf4FontService,
                      true,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ReadingModeOptionCard(
                    icon: QuranReadingMode.tajweed.icon,
                    label: QuranReadingMode.tajweed.localizedLabel(context),
                    isSelected: readingMode == QuranReadingMode.tajweed,
                    requiresFonts: true,
                    isDark: isDark,
                    accent: accent,
                    fontService: tajweedFontService,
                    onTap: () => onReadingModeTap(
                      QuranReadingMode.tajweed,
                      tajweedFontService,
                      true,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
