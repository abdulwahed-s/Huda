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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(0.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCompactWelcomeIcon(context),
                      SizedBox(height: 12.h),
                      _buildWelcomeText(context),
                      SizedBox(height: 8.h),
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
                SizedBox(height: 10.h)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactWelcomeIcon(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Icon(
        Icons.auto_awesome,
        size: 40.sp,
        color: !isDark ? context.primaryColor : Colors.white,
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    return Text(
      appLocalizations.welcomeToHudaAI,
      style: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.bold,
        color: context.primaryColor,
        fontFamily: 'Amiri',
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCompactIntroCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
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
        appLocalizations.aiIntroMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.sp,
          color: isDark
              ? context.darkText.withValues(alpha: 0.7)
              : context.lightText.withValues(alpha: 0.6),
          height: 1.3,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  Widget _buildHorizontalInfoCards(BuildContext context) {
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
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: InfoCard(
            context: context,
            icon: Icons.verified_outlined,
            title: appLocalizations.verifySourcesTitle,
            subtitle: appLocalizations.verifySourcesSubtitle,
            color: Colors.orange,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildExampleQuestions(BuildContext context) {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h),
        Text(
          appLocalizations.tryAsking,
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
            itemCount: exampleQuestions.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 150.w,
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
