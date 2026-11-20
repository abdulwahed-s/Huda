import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/error/error_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

class ErrorReportStatus extends StatelessWidget {
  const ErrorReportStatus({
    super.key,
    required this.state,
    required this.retrying,
    required this.onRetry,
  });

  final ErrorState state;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    Widget line(Widget lead, String text, {bool live = false}) => Semantics(
      liveRegion: live,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: textScaler.scale(20),
            child: Center(child: lead),
          ),
          SizedBox(width: tokens.space.xs),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );

    final Widget child;
    final String key;
    if (retrying) {
      key = 'retrying';
      child = const HudaStatusBanner(status: HudaStatus.retrying);
    } else {
      switch (state) {
        case ErrorLoading():
          key = 'sending';
          child = line(
            HudaLampSpinner(size: textScaler.scale(16)),
            l10n.errorReportSending,
            live: true,
          );
        case ErrorLoaded() || ErrorSubmitting() || ErrorSubmitted():
          key = 'sent';
          child = line(
            Icon(
              Icons.check_rounded,
              size: textScaler.scale(18),
              color: tokens.ornament,
            ),
            l10n.errorReportSent,
          );
        case ErrorReportingDisabled():
          key = 'off';
          child = line(
            Icon(
              Icons.privacy_tip_outlined,
              size: textScaler.scale(18),
              color: scheme.onSurfaceVariant,
            ),
            l10n.crashReportingDisabledDescription,
          );
        case ErrorFailure():
          key = 'failed';
          child = HudaStatusBanner(
            status: HudaStatus.failed,
            message: l10n.errorReportFailed,
            onRetry: onRetry,
          );
        case ErrorInitial():
          key = 'none';
          child = const SizedBox.shrink();
      }
    }
    return HudaStateSwitcher(stateKey: key, child: child);
  }
}

class ErrorTechnicalDetails extends StatefulWidget {
  const ErrorTechnicalDetails({
    super.key,
    required this.errorMessage,
    this.collapsible = true,
  });

  final String errorMessage;
  final bool collapsible;

  @override
  State<ErrorTechnicalDetails> createState() => _ErrorTechnicalDetailsState();
}

class _ErrorTechnicalDetailsState extends State<ErrorTechnicalDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final open = _open || !widget.collapsible;
    final title = Text(
      l10n.errorTechnicalDetails,
      style: theme.textTheme.titleMedium,
    );
    final header = widget.collapsible
        ? InkWell(
            key: const ValueKey('error-details-toggle'),
            borderRadius: tokens.radius.card,
            onTap: () => setState(() => _open = !_open),
            child: Semantics(
              expanded: _open,
              button: true,
              child: Padding(
                padding: EdgeInsets.all(tokens.space.md),
                child: Row(
                  children: [
                    Expanded(child: title),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: tokens.motion.of(context, tokens.motion.medium),
                      curve: tokens.motion.standard,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.space.md,
              tokens.space.md,
              tokens.space.md,
              0,
            ),
            child: Semantics(header: true, child: title),
          );
    final text = Container(
      width: double.infinity,
      margin: EdgeInsets.all(tokens.space.md),
      padding: EdgeInsets.all(tokens.space.sm),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: tokens.radius.control,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SelectableText(
            widget.errorMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
    return HudaCard(
      padding: EdgeInsets.zero,
      child: HudaAnimatedSize(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, if (open) text],
        ),
      ),
    );
  }
}

class ErrorFeedbackCard extends StatefulWidget {
  const ErrorFeedbackCard({super.key, required this.state});

  final ErrorState state;

  @override
  State<ErrorFeedbackCard> createState() => _ErrorFeedbackCardState();
}

class _ErrorFeedbackCardState extends State<ErrorFeedbackCard> {
  final _message = TextEditingController();
  final _email = TextEditingController();
  bool _empty = false;

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  void _send() {
    final message = _message.text.trim();
    if (message.isEmpty) {
      setState(() => _empty = true);
      return;
    }
    final email = _email.text.trim();
    context.read<ErrorCubit>().submitFeedback(
      message,
      contactEmail: email.isEmpty ? null : email,
    );
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = widget.state;
    final sending = state is ErrorSubmitting;
    final failed = state is ErrorFeedbackFailure;

    if (state is ErrorSubmitted) {
      return HudaCard(
        key: const ValueKey('error-feedback-sent'),
        child: Row(
          children: [
            const HudaLamp(size: 36, child: Icon(Icons.check_rounded)),
            SizedBox(width: tokens.space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.feedbackThankYou,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.feedbackThankYouMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return HudaCard(
      key: const ValueKey('error-feedback'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.helpUsImproveTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SizedBox(height: tokens.space.xxs),
          Text(
            l10n.errorFeedbackPrompt,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.space.md),
          TextField(
            controller: _message,
            enabled: !sending,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            onChanged: (_) {
              if (_empty) setState(() => _empty = false);
            },
            decoration: InputDecoration(
              hintText: l10n.errorFeedbackHint,
              errorText: _empty ? l10n.pleaseEnterMessage : null,
              border: const OutlineInputBorder(),
            ),
          ),
          SizedBox(height: tokens.space.xs),
          TextField(
            controller: _email,
            enabled: !sending,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: l10n.emailOptional,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              border: const OutlineInputBorder(),
            ),
          ),
          if (failed) ...[
            SizedBox(height: tokens.space.sm),
            Text(
              l10n.errorFeedbackFailed,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          SizedBox(height: tokens.space.md),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: sending
                ? Semantics(
                    liveRegion: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HudaLampSpinner(size: 18),
                        SizedBox(width: tokens.space.xs),
                        Text(l10n.feedbackSending),
                      ],
                    ),
                  )
                : FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(l10n.feedbackSendButton),
                  ),
          ),
        ],
      ),
    );
  }
}
