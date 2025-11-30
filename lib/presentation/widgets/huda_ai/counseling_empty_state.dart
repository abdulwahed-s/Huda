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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final isTabletLandscape = isTablet && isLandscape;
            final contentMaxWidth = isTablet ? 1000.0 : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: isTabletLandscape
                      ? _buildLandscapeLayout(context, isTablet)
                      : _buildPortraitLayout(context, isTablet),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 24.0 : 16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactWelcomeIcon(context, isTablet),
              SizedBox(height: isTablet ? 20.0 : 12.h),
              _buildWelcomeText(context, isTablet),
              SizedBox(height: isTablet ? 16.0 : 10.h),
              _buildCompactIntroCard(context, isTablet),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24.0 : 16.w,
            vertical: isTablet ? 16.0 : 8.w,
          ),
          child: _buildHorizontalInfoCards(context, isTablet),
        ),
        _buildExampleQuestions(context, isTablet),
        SizedBox(height: isTablet ? 20.0 : 10.h),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactWelcomeIcon(context, isTablet),
                    const SizedBox(height: 20.0),
                    _buildWelcomeText(context, isTablet),
                    const SizedBox(height: 16.0),
                    _buildCompactIntroCard(context, isTablet),
                  ],
                ),
              ),
              const SizedBox(width: 32.0),
              Expanded(
                flex: 3,
                child: _buildHorizontalInfoCards(context, isTablet),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          _buildExampleQuestions(context, isTablet),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _buildCompactWelcomeIcon(BuildContext context, bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconSize = isTablet ? 56.0 : 40.w;
    final padding = isTablet ? 16.0 : 12.w;
    final borderRadius = isTablet ? 24.0 : 20.r;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: SvgPicture.asset(
        'assets/images/consulting.svg',
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(
          isDark ? Colors.white : colorScheme.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context, bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final fontSize = isTablet ? 28.0 : 22.sp;

    return Text(
      l10n.counselingMode,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
        fontFamily: 'Amiri',
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCompactIntroCard(BuildContext context, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final padding = isTablet ? 18.0 : 10.w;
    final margin = isTablet ? 16.0 : 8.w;
    final borderRadius = isTablet ? 16.0 : 12.r;
    final fontSize = isTablet ? 15.0 : 12.sp;

    return Container(
      padding: EdgeInsets.all(padding),
      margin: EdgeInsets.symmetric(horizontal: margin),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3142) : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
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
          fontSize: fontSize,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.black87.withValues(alpha: 0.6),
          height: 1.4,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  Widget _buildHorizontalInfoCards(BuildContext context, bool isTablet) {
    final l10n = AppLocalizations.of(context)!;
    final spacing = isTablet ? 16.0 : 8.w;

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.light_mode_outlined,
            title: l10n.guidanceTitle,
            subtitle: l10n.guidanceSubtitle,
            color: const Color(0xFF00897B),
            isTablet: isTablet,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.menu_book_outlined,
            title: l10n.quranTitle,
            subtitle: l10n.quranSubtitle,
            color: const Color(0xFF3949AB),
            isTablet: isTablet,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: _buildInfoCard(
            context,
            icon: Icons.favorite_outline,
            title: l10n.duaaTitle,
            subtitle: l10n.duaaSubtitle,
            color: const Color(0xFFC2185B),
            isTablet: isTablet,
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
    required bool isTablet,
  }) {
    final padding = isTablet ? 16.0 : 10.w;
    final borderRadius = isTablet ? 16.0 : 12.r;
    final iconSize = isTablet ? 36.0 : 28.sp;
    final titleSize = isTablet ? 16.0 : 13.sp;
    final subtitleSize = isTablet ? 12.0 : 9.sp;
    final spacing1 = isTablet ? 10.0 : 6.h;
    final spacing2 = isTablet ? 4.0 : 2.h;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3142) : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
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
            size: iconSize,
            color: color,
          ),
          SizedBox(height: spacing1),
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: subtitleSize,
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

  Widget _buildExampleQuestions(BuildContext context, bool isTablet) {
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

    final titleSize = isTablet ? 18.0 : 15.sp;
    final spacing = isTablet ? 12.0 : 8.h;
    final chipHeight = isTablet ? 140.0 : 120.h;
    final chipWidth = isTablet ? 200.0 : 150.w;
    final chipSpacing = isTablet ? 12.0 : 8.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: spacing),
        Text(
          l10n.tryExpressing,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Amiri',
          ),
        ),
        SizedBox(height: spacing),
        SizedBox(
          height: chipHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: examples.length,
            separatorBuilder: (context, index) => SizedBox(width: chipSpacing),
            itemBuilder: (context, index) {
              final example = examples[index];
              return SizedBox(
                width: chipWidth,
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
