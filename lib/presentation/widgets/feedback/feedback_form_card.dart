import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

extension FeedbackCategoryCopy on FeedbackCategory {
  static const ordered = [
    FeedbackCategory.general,
    FeedbackCategory.featureRequest,
    FeedbackCategory.issue,
  ];

  String title(AppLocalizations l10n) => switch (this) {
    FeedbackCategory.issue => l10n.reportAnIssue,
    FeedbackCategory.featureRequest => l10n.detailedFeedbackTitle,
    FeedbackCategory.general => l10n.shareYourThoughts,
  };

  String description(AppLocalizations l10n) => switch (this) {
    FeedbackCategory.issue => l10n.issueDescription,
    FeedbackCategory.featureRequest => l10n.detailedFeedbackSubtitle,
    FeedbackCategory.general => l10n.feedbackDescription,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    FeedbackCategory.issue => l10n.describeIssueHint,
    FeedbackCategory.featureRequest => l10n.detailedFeedbackSubtitle,
    FeedbackCategory.general => l10n.feedbackHintText,
  };

  IconData get icon => switch (this) {
    FeedbackCategory.issue => Icons.report_problem_outlined,
    FeedbackCategory.featureRequest => Icons.lightbulb_outline_rounded,
    FeedbackCategory.general => Icons.chat_bubble_outline_rounded,
  };
}

class FeedbackKindChoice extends StatelessWidget {
  const FeedbackKindChoice({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final FeedbackCategory selected;
  final ValueChanged<FeedbackCategory> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.feedbackFormTitle, style: theme.textTheme.titleMedium),
        ),
        SizedBox(height: space.xxs),
        Text(
          l10n.feedbackFormSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: space.md),
        HudaAnimatedSize(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in FeedbackCategoryCopy.ordered) ...[
                if (category != FeedbackCategoryCopy.ordered.first)
                  SizedBox(height: space.xs),
                HudaChoiceRow(
                  key: ValueKey('feedback-category-${category.name}'),
                  leading: Icon(
                    category.icon,
                    color: category == selected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  title: category.title(l10n),
                  subtitle: category == selected
                      ? category.description(l10n)
                      : null,
                  semanticLabel:
                      '${category.title(l10n)}. ${category.description(l10n)}',
                  selected: category == selected,
                  onTap: enabled ? () => onChanged(category) : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class FeedbackFields extends StatelessWidget {
  const FeedbackFields({
    super.key,
    required this.feedbackFieldKey,
    required this.feedbackController,
    required this.emailController,
    required this.feedbackFocusNode,
    required this.emailFocusNode,
    required this.category,
    required this.onSubmitted,
    required this.errorText,
    required this.enabled,
  });

  final GlobalKey feedbackFieldKey;
  final TextEditingController feedbackController;
  final TextEditingController emailController;
  final FocusNode feedbackFocusNode;
  final FocusNode emailFocusNode;
  final FeedbackCategory category;
  final VoidCallback onSubmitted;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: feedbackFieldKey,
            controller: feedbackController,
            focusNode: feedbackFocusNode,
            enabled: enabled,
            minLines: 4,
            maxLines: 10,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onTapOutside: (_) => feedbackFocusNode.unfocus(),
            decoration: feedbackFieldDecoration(
              context,
              label: category.title(l10n),
              hint: category.hint(l10n),
              error: errorText,
              alignLabelWithHint: true,
            ),
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: space.sm),
          TextField(
            controller: emailController,
            focusNode: emailFocusNode,
            enabled: enabled,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) {
              if (enabled) onSubmitted();
            },
            onTapOutside: (_) => emailFocusNode.unfocus(),
            decoration: feedbackFieldDecoration(
              context,
              label: l10n.emailOptional,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

InputDecoration feedbackFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  String? error,
  Widget? prefixIcon,
  bool alignLabelWithHint = false,
}) {
  final tokens = context.tokens;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final radius = BorderRadius.circular(tokens.radius.md);
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: error,
    errorMaxLines: 3,
    hintMaxLines: 3,
    prefixIcon: prefixIcon,
    prefixIconColor: scheme.onSurfaceVariant,
    alignLabelWithHint: alignLabelWithHint,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: scheme.surfaceContainerLow,
    contentPadding: EdgeInsets.all(tokens.space.md),
    labelStyle: theme.textTheme.labelLarge?.copyWith(
      color: scheme.onSurfaceVariant,
    ),
    floatingLabelStyle: theme.textTheme.labelLarge?.copyWith(
      color: scheme.primary,
    ),
    hintStyle: theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    ),
    counterStyle: theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    ),
    errorStyle: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
    border: border(scheme.outline),
    enabledBorder: border(scheme.outline),
    disabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, tokens.stroke.fine),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, tokens.stroke.fine),
  );
}
