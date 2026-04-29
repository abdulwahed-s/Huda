import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_card.dart';
import 'package:huda/presentation/widgets/khatma/khatma_duration_tile.dart';
import 'package:huda/presentation/widgets/khatma/khatma_section_label.dart';
import 'package:huda/presentation/widgets/khatma/khatma_top_title.dart';

class KhatmaProgramPartsView extends StatelessWidget {
  final TextDirection textDirection;
  final VoidCallback onBack;
  final ValueChanged<int> onSelectDays;

  const KhatmaProgramPartsView({
    super.key,
    required this.textDirection,
    required this.onBack,
    required this.onSelectDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: textDirection,
      child: ListView(
        padding: EdgeInsets.only(
          top: 6.h,
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          KhatmaTopTitle(
            title: l10n.khatmaProgramTitle,
            onBack: onBack,
            textDirection: textDirection,
          ),
          SizedBox(height: 6.h),
          KhatmaSectionLabel(text: l10n.khatmaMonthsSection),
          SizedBox(height: 6.h),
          KhatmaCard(
            child: KhatmaDurationTile(
              days: 30,
              title: l10n.khatma30DaysTitle,
              subtitle: l10n.khatmaDailyWirdJuz,
              textDirection: textDirection,
              onTap: () => onSelectDays(30),
            ),
          ),
          SizedBox(height: 12.h),
          KhatmaSectionLabel(text: l10n.khatmaOtherSection),
          SizedBox(height: 6.h),
          KhatmaCard(
            child: Column(
              children: [
                KhatmaDurationTile(
                    days: 240,
                    title: l10n.khatma240DaysTitle,
                    subtitle: l10n.khatmaDailyWirdRubu,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(240)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 120,
                    title: l10n.khatma120DaysTitle,
                    subtitle: l10n.khatmaDailyWirdTwoRubu,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(120)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 80,
                    title: l10n.khatma80DaysTitle,
                    subtitle: l10n.khatmaDailyWird3Rubu,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(80)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 60,
                    title: l10n.khatma60DaysTitle,
                    subtitle: l10n.khatmaDailyWirdHizb,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(60)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 40,
                    title: l10n.khatma40DaysTitle,
                    subtitle: l10n.khatmaDailyWirdHizbAndHalf,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(40)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 30,
                    title: l10n.khatma30DaysTitle,
                    subtitle: l10n.khatmaDailyWirdJuz,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(30)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 20,
                    title: l10n.khatma20DaysTitle,
                    subtitle: l10n.khatmaDailyWirdJuzAndHalf,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(20)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 15,
                    title: l10n.khatma15DaysTitle,
                    subtitle: l10n.khatmaDailyWirdTwoJuz,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(15)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 10,
                    title: l10n.khatma10DaysTitle,
                    subtitle: l10n.khatmaDailyWird3Juz,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(10)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 6,
                    title: l10n.khatma6DaysTitle,
                    subtitle: l10n.khatmaDailyWird5Juz,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(6)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 3,
                    title: l10n.khatma3DaysTitle,
                    subtitle: l10n.khatmaDailyWird10Juz,
                    textDirection: textDirection,
                    onTap: () => onSelectDays(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
