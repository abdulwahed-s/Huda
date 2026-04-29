import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_card.dart';
import 'package:huda/presentation/widgets/khatma/khatma_duration_tile.dart';
import 'package:huda/presentation/widgets/khatma/khatma_top_title.dart';

class KhatmaProgramMeaningView extends StatelessWidget {
  final TextDirection textDirection;
  final VoidCallback onBack;
  final ValueChanged<int> onSelectDays;
  final int Function(int days) pagesPerDayFn;

  const KhatmaProgramMeaningView({
    super.key,
    required this.textDirection,
    required this.onBack,
    required this.onSelectDays,
    required this.pagesPerDayFn,
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
          SizedBox(height: 4.h),
          KhatmaCard(
            child: Column(
              children: [
                KhatmaDurationTile(
                    days: 60,
                    title: l10n.khatmaTwoMonthsProgram,
                    pagesPerDay: pagesPerDayFn(60),
                    textDirection: textDirection,
                    onTap: () => onSelectDays(60)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 29,
                    title: l10n.khatmaOneMonthProgram,
                    pagesPerDay: pagesPerDayFn(29),
                    textDirection: textDirection,
                    onTap: () => onSelectDays(29)),
                Divider(height: 1, indent: 16.w),
                KhatmaDurationTile(
                    days: 7,
                    title: l10n.khatmaOneWeekProgram,
                    pagesPerDay: pagesPerDayFn(7),
                    textDirection: textDirection,
                    onTap: () => onSelectDays(7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
