import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/huda_ai/info_card.dart';
import 'package:huda/presentation/widgets/huda_ai/question_chip.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool isDark;
  final AppLocalizations appLocalizations;
  final TextEditingController controller;
  final ChatCubit chatCubit;

  const EmptyStateWidget({
    super.key,
    required this.isDark,
    required this.appLocalizations,
    required this.controller,
    required this.chatCubit,
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
          padding: EdgeInsets.all(isTablet ? 24.0 : 10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCompactWelcomeIcon(context, isTablet),
              SizedBox(height: isTablet ? 20.0 : 12.h),
              _buildWelcomeText(context, isTablet),
              SizedBox(height: isTablet ? 16.0 : 8.h),
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
        SizedBox(height: isTablet ? 20.0 : 10.h)
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
    final iconSize = isTablet ? 56.0 : 40.sp;
    final padding = isTablet ? 16.0 : 12.w;
    final borderRadius = isTablet ? 24.0 : 20.r;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.auto_awesome,
        size: iconSize,
        color: !isDark ? context.primaryColor : Colors.white,
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context, bool isTablet) {
    final fontSize = isTablet ? 28.0 : 22.sp;

    return Text(
      appLocalizations.welcomeToHudaAI,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: context.primaryColor,
        fontFamily: 'Amiri',
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCompactIntroCard(BuildContext context, bool isTablet) {
    final padding = isTablet ? 18.0 : 10.w;
    final margin = isTablet ? 16.0 : 8.w;
    final borderRadius = isTablet ? 16.0 : 12.r;
    final fontSize = isTablet ? 15.0 : 12.sp;

    return Container(
      padding: EdgeInsets.all(padding),
      margin: EdgeInsets.symmetric(horizontal: margin),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
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
        appLocalizations.aiIntroMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          color: isDark
              ? context.darkText.withValues(alpha: 0.7)
              : context.lightText.withValues(alpha: 0.6),
          height: 1.4,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  Widget _buildHorizontalInfoCards(BuildContext context, bool isTablet) {
    final spacing = isTablet ? 16.0 : 8.w;

    return Row(
      children: [
        Expanded(
          child: InfoCard(
            context: context,
            icon: Icons.info_outline,
            title: appLocalizations.aiAssistantTitle,
            subtitle: appLocalizations.aiAssistantSubtitle,
            color: Colors.blue,
            isDark: isDark,
            isTablet: isTablet,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: InfoCard(
            context: context,
            icon: Icons.verified_outlined,
            title: appLocalizations.verifySourcesTitle,
            subtitle: appLocalizations.verifySourcesSubtitle,
            color: Colors.orange,
            isDark: isDark,
            isTablet: isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildExampleQuestions(BuildContext context, bool isTablet) {
    final exampleQuestions = [
      appLocalizations.exampleQuestion1,
      appLocalizations.exampleQuestion2,
      appLocalizations.exampleQuestion3,
      appLocalizations.exampleQuestion4,
    ];

    final icons = [
      Icons.mosque,
      Icons.stars_outlined,
      Icons.bedtime,
      Icons.favorite,
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
          appLocalizations.tryAsking,
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
            itemCount: exampleQuestions.length,
            separatorBuilder: (context, index) => SizedBox(width: chipSpacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: chipWidth,
                child: QuestionChip(
                  context: context,
                  text: exampleQuestions[index],
                  icon: icons[index],
                  isDark: isDark,
                  onPressed: () {
                    controller.text = exampleQuestions[index];
                    chatCubit.sendMessage(exampleQuestions[index]);
                    controller.clear();
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
