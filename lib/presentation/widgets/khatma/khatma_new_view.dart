import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_card.dart';
import 'package:huda/presentation/widgets/khatma/khatma_icon_list_tile.dart';
import 'package:huda/presentation/widgets/khatma/khatma_section_label.dart';
import 'package:huda/presentation/widgets/khatma/khatma_top_title.dart';

class KhatmaNewView extends StatelessWidget {
  final TextDirection textDirection;
  final VoidCallback onBack;
  final VoidCallback onRecommendedTap;
  final VoidCallback onProgramMeaning;
  final VoidCallback onProgramParts;

  const KhatmaNewView({
    super.key,
    required this.textDirection,
    required this.onBack,
    required this.onRecommendedTap,
    required this.onProgramMeaning,
    required this.onProgramParts,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.primaryColor;
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
            title: l10n.khatmaNewTitle,
            onBack: onBack,
            textDirection: textDirection,
          ),
          SizedBox(height: 10.h),
          _RecommendedCard(
            textDirection: textDirection,
            accent: accent,
            onTap: onRecommendedTap,
          ),
          SizedBox(height: 18.h),
          KhatmaSectionLabel(text: l10n.khatmaOtherPrograms),
          SizedBox(height: 8.h),
          KhatmaCard(
            child: Column(
              children: [
                KhatmaIconListTile(
                  icon: Icons.auto_stories_rounded,
                  iconColor: Colors.purple,
                  title: l10n.khatmaBySemanticTitle,
                  subtitle: l10n.khatmaBySemanticSubtitle,
                  textDirection: textDirection,
                  onTap: onProgramMeaning,
                ),
                Divider(height: 1, indent: 62.w),
                KhatmaIconListTile(
                  icon: Icons.grid_view_rounded,
                  iconColor: Colors.blue.shade600,
                  title: l10n.khatmaByPartsTitle,
                  subtitle: l10n.khatmaByPartsSubtitle,
                  textDirection: textDirection,
                  onTap: onProgramParts,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final TextDirection textDirection;
  final Color accent;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.textDirection,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.72)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(18.r),
          child: Row(
            children: [
              Container(
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.star_rounded, color: Colors.white, size: 26.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(l10n.khatmaSuggested,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(height: 6.h),
                    Text(l10n.khatmaOneMonthProgram,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 3.h),
                    Text(l10n.khatmaDailyWird21Pages,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(
                  textDirection == TextDirection.rtl
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16.sp),
            ],
          ),
        ),
      ),
    );
  }
}
