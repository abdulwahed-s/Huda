import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class FeedbackFormCard extends StatelessWidget {
  const FeedbackFormCard({
    super.key,
    required this.feedbackFieldKey,
    required this.feedbackController,
    required this.emailController,
    required this.feedbackFocusNode,
    required this.emailFocusNode,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onFeedbackSubmitted,
    required this.feedbackErrorText,
    required this.isSubmitting,
    required this.l10n,
  });

  final GlobalKey feedbackFieldKey;
  final TextEditingController feedbackController;
  final TextEditingController emailController;
  final FocusNode feedbackFocusNode;
  final FocusNode emailFocusNode;
  final FeedbackCategory selectedCategory;
  final ValueChanged<FeedbackCategory> onCategoryChanged;
  final VoidCallback onFeedbackSubmitted;
  final String? feedbackErrorText;
  final bool isSubmitting;
  final AppLocalizations l10n;

  static const _categoryOrder = [
    FeedbackCategory.general,
    FeedbackCategory.featureRequest,
    FeedbackCategory.issue,
  ];

  String _titleForCategory(FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.issue => l10n.reportAnIssue,
      FeedbackCategory.featureRequest => l10n.detailedFeedbackTitle,
      FeedbackCategory.general => l10n.shareYourThoughts,
    };
  }

  String _descriptionForCategory(FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.issue => l10n.issueDescription,
      FeedbackCategory.featureRequest => l10n.detailedFeedbackSubtitle,
      FeedbackCategory.general => l10n.feedbackDescription,
    };
  }

  String _hintForCategory() {
    return switch (selectedCategory) {
      FeedbackCategory.issue => l10n.describeIssueHint,
      FeedbackCategory.featureRequest => l10n.detailedFeedbackSubtitle,
      FeedbackCategory.general => l10n.feedbackHintText,
    };
  }

  IconData _iconForCategory(FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.issue => Icons.report_problem_outlined,
      FeedbackCategory.featureRequest => Icons.lightbulb_outline_rounded,
      FeedbackCategory.general => Icons.chat_bubble_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final secondaryText = colorScheme.onSurfaceVariant;
    final fieldFill = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: isDark ? 0.07 : 0.035),
      colorScheme.surface,
    );

    return Semantics(
      container: true,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: isDark ? 0.9 : 0.98),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: colorScheme.onSurface.withValues(
              alpha: isDark ? 0.14 : 0.08,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.055),
              blurRadius: 24.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.feedbackFormTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                l10n.feedbackFormSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryText,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 17.h),
              ..._categoryOrder.map((category) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: category == _categoryOrder.last ? 0 : 8,
                  ),
                  child: _CategoryOption(
                    key: ValueKey('feedback-category-${category.name}'),
                    icon: _iconForCategory(category),
                    title: _titleForCategory(category),
                    semanticDescription: _descriptionForCategory(category),
                    selected: selectedCategory == category,
                    enabled: !isSubmitting,
                    onTap: () => onCategoryChanged(category),
                  ),
                );
              }),
              const SizedBox(height: 10),
              AnimatedSize(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: AlignmentDirectional.topCenter,
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  reverseDuration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    );
                    return FadeTransition(
                      opacity: curvedAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.18),
                          end: Offset.zero,
                        ).animate(curvedAnimation),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey(selectedCategory),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 13.w,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.13 : 0.07,
                      ),
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: Icon(
                            _iconForCategory(selectedCategory),
                            size: 17.sp,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 9.w),
                        Expanded(
                          child: Text(
                            _descriptionForCategory(selectedCategory),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                key: feedbackFieldKey,
                controller: feedbackController,
                focusNode: feedbackFocusNode,
                enabled: !isSubmitting,
                minLines: 5,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onTapOutside: (_) => feedbackFocusNode.unfocus(),
                decoration: _fieldDecoration(
                  context,
                  fillColor: fieldFill,
                  labelText: _titleForCategory(selectedCategory),
                  hintText: _hintForCategory(),
                  errorText: feedbackErrorText,
                  alignLabelWithHint: true,
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                focusNode: emailFocusNode,
                enabled: !isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) {
                  if (!isSubmitting) onFeedbackSubmitted();
                },
                onTapOutside: (_) => emailFocusNode.unfocus(),
                decoration: _fieldDecoration(
                  context,
                  fillColor: fieldFill,
                  labelText: l10n.emailOptional,
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    color: secondaryText,
                    size: 20.sp,
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required Color fillColor,
    required String labelText,
    String? hintText,
    String? errorText,
    Widget? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(15.r);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      alignLabelWithHint: alignLabelWithHint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: fillColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        height: 1.4,
      ),
      counterStyle: theme.textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      errorStyle: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.error,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.16),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.16),
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 1.8),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    super.key,
    required this.icon,
    required this.title,
    required this.semanticDescription,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String semanticDescription;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final selectedColor = colorScheme.primary;
    final animationDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '$title. $semanticDescription',
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: selected ? 1 : 0.988,
          duration: animationDuration,
          curve: selected ? Curves.easeOutBack : Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected
                  ? selectedColor.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.17 : 0.085,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(
                color: selected
                    ? selectedColor.withValues(alpha: 0.9)
                    : colorScheme.onSurface.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.2 : 0.14,
                      ),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: selectedColor.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.16
                              : 0.1,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15.r),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? onTap : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 58),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 13.w,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: animationDuration,
                          curve: Curves.easeOutCubic,
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            color: selectedColor.withValues(
                              alpha: selected ? 0.18 : 0.075,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: AnimatedScale(
                            scale: selected ? 1.08 : 1,
                            duration: animationDuration,
                            curve: Curves.easeOutBack,
                            child: Icon(
                              icon,
                              color: selectedColor,
                              size: 21.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            style:
                                theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  height: 1.25,
                                ) ??
                                const TextStyle(),
                            child: Text(title),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            final curvedAnimation = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            );
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.55,
                                  end: 1,
                                ).animate(curvedAnimation),
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            key: ValueKey(selected),
                            color: selected
                                ? selectedColor
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.55,
                                  ),
                            size: 23.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
