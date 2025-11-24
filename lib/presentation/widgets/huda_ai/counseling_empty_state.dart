import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/huda_ai/question_chip.dart';

class CounselingEmptyState extends StatelessWidget {
  final bool isDark;

  const CounselingEmptyState({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [context.darkGradientStart, context.darkGradientEnd]
              : [
                  context.lightSurface,
                  context.primaryExtraLightColor.withValues(alpha: 0.3)
                ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(0.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactWelcomeIcon(context),
                      SizedBox(height: 12.h),
                      _buildWelcomeText(context),
                      SizedBox(height: 10.h),
                      _buildCompactIntroCard(context),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                  child: _buildHorizontalInfoCards(context),
                ),
                _buildExampleQuestions(context),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactWelcomeIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: SvgPicture.asset(
        'assets/images/consulting.svg',
        width: 40.w,
        height: 40.h,
        colorFilter: ColorFilter.mode(
          isDark ? Colors.white : colorScheme.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.counselingMode,
      style: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
        fontFamily: 'Amiri',
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCompactIntroCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(10.w),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3142) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Text(
        l10n.counselingIntro,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.sp,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.black87.withValues(alpha: 0.6),
          height: 1.3,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  Widget _buildHorizontalInfoCards(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.light_mode_outlined,
            title: l10n.guidanceTitle,
            subtitle: l10n.guidanceSubtitle,
            color: const Color(0xFF00897B),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.menu_book_outlined,
            title: l10n.quranTitle,
            subtitle: l10n.quranSubtitle,
            color: const Color(0xFF3949AB),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.favorite_outline,
            title: l10n.duaaTitle,
            subtitle: l10n.duaaSubtitle,
            color: const Color(0xFFC2185B),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3142) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28.sp,
            color: color,
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.sp,
              color:
                  isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExampleQuestions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final examples = [
      {'text': l10n.exampleFeelAnxious, 'icon': Icons.health_and_safety},
      {
        'text': l10n.exampleFeelOverwhelmed,
        'icon': Icons.sentiment_dissatisfied
      },
      {'text': l10n.exampleFeelingGrateful, 'icon': Icons.favorite},
      {'text': l10n.exampleSeekingPeace, 'icon': Icons.spa},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h),
        Text(
          l10n.tryExpressing,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Amiri',
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 120.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: examples.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final example = examples[index];
              return SizedBox(
                width: 150.w,
                child: QuestionChip(
                  context: context,
                  text: example['text'] as String,
                  icon: example['icon'] as IconData,
                  isDark: isDark,
                  onPressed: () {
                    context
                        .read<ChatCubit>()
                        .sendCounselingRequest(example['text'] as String);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
