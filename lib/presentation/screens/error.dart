import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_theme.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/error/error_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';
import 'package:huda/presentation/widgets/error/error_report.dart';
import 'package:huda/presentation/widgets/error/system_identity.dart';
import 'package:restart_app/restart_app.dart';

const Color _kErrorBackground = Color(0xFF0c1d2b);

bool _renderingError = false;

void setCustomErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (_renderingError) {
      return _MinimalErrorFallback(message: _firstLine(details));
    }

    _renderingError = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderingError = false;
    });

    try {
      return _SafeErrorBoundary(errorDetails: details);
    } catch (_) {
      return _MinimalErrorFallback(message: _firstLine(details));
    }
  };
}

String _firstLine(FlutterErrorDetails details) {
  final text = details.exceptionAsString();
  final line = text.split('\n').first.trim();
  if (line.isEmpty) return 'Something went wrong';
  return line.length > 200 ? '${line.substring(0, 197)}...' : line;
}

class _SafeErrorBoundary extends StatelessWidget {
  const _SafeErrorBoundary({required this.errorDetails});

  final FlutterErrorDetails errorDetails;

  @override
  Widget build(BuildContext context) {
    final errorMessage = errorDetails.exceptionAsString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bigEnough =
            constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight &&
            constraints.maxWidth > 200 &&
            constraints.maxHeight > 200;

        if (!bigEnough) {
          return _MinimalErrorFallback(
            message: errorMessage.split('\n').first.trim(),
          );
        }

        // Self-contained: its own app, theme (the default palette, light or
        // dark with the device) and cubit; nothing from the app around it.
        return BlocProvider(
          create: (_) => ErrorCubit()..sendFlutterError(errorDetails),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: HudaTheme.build(
              colorTheme: AppColors.defaultTheme,
              brightness: Brightness.light,
            ),
            darkTheme: HudaTheme.build(
              colorTheme: AppColors.defaultTheme,
              brightness: Brightness.dark,
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LocalizationCubit.supportedLocales,
            home: ErrorPage(errorMessage: errorMessage),
          ),
        );
      },
    );
  }
}

class _MinimalErrorFallback extends StatelessWidget {
  const _MinimalErrorFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LimitedBox(
        maxWidth: 600,
        maxHeight: 400,
        child: ColoredBox(
          color: _kErrorBackground,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message.isEmpty ? 'Something went wrong' : message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFB0B8C4),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The error screen: what happened in plain words, Restart and Copy, where
/// the report stands, the technical details and a note for the team. On
/// wide windows the details and the note sit in their own pane.
class ErrorPage extends StatefulWidget {
  const ErrorPage({required this.errorMessage, super.key});

  final String errorMessage;

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  bool _retrying = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.errorMessage));
    HudaHaptics.light(context);
    showHudaToast(
      context,
      message: AppLocalizations.of(context)!.errorDetailsCopied,
    );
  }

  void _retryReport() {
    setState(() => _retrying = true);
    context.read<ErrorCubit>().sendError(widget.errorMessage);
  }

  @override
  Widget build(BuildContext context) {
    // Lantern tokens even where the theme above has none (the harness).
    final theme = Theme.of(context);
    final lantern = theme.extension<HudaTokens>() != null
        ? theme
        : HudaTheme.build(
            colorTheme: AppColors.defaultTheme,
            brightness: theme.brightness,
          );
    return Theme(
      data: lantern,
      child: BlocConsumer<ErrorCubit, ErrorState>(
        listenWhen: (_, _) => _retrying,
        listener: (context, state) {
          if (state is! ErrorLoading) setState(() => _retrying = false);
        },
        builder: (context, state) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: HudaSystemUi.over(
            top: lantern.brightness,
            bottom: lantern.brightness,
          ),
          child: Scaffold(
            body: HudaRevealScope(
              child: LayoutBuilder(
                builder: (context, box) {
                  final wide = AdaptivePanes.showsTwoPanes(
                    box.maxWidth,
                    FoldInfo.of(context),
                  );
                  final summary = _Summary(
                    state: state,
                    retrying: _retrying,
                    onRetry: _retryReport,
                    onCopy: _copy,
                    showDetails: !wide,
                    errorMessage: widget.errorMessage,
                  );
                  // A short page centers; side by side, both panes start at
                  // the same top.
                  if (!wide) {
                    return _Column(
                      center: true,
                      children: summary.children(context),
                    );
                  }
                  return AdaptivePanes(
                    primary: _Column(children: summary.children(context)),
                    secondary: _Column(
                      children: [
                        ErrorTechnicalDetails(
                          errorMessage: widget.errorMessage,
                          collapsible: false,
                        ),
                        ?_feedback(state),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget? _feedback(ErrorState state) => switch (state) {
  ErrorLoaded() ||
  ErrorSubmitting() ||
  ErrorSubmitted() => ErrorFeedbackCard(state: state),
  _ => null,
};

class _Summary {
  const _Summary({
    required this.state,
    required this.retrying,
    required this.onRetry,
    required this.onCopy,
    required this.showDetails,
    required this.errorMessage,
  });

  final ErrorState state;
  final bool retrying;
  final VoidCallback onRetry;
  final VoidCallback onCopy;
  final bool showDetails;
  final String errorMessage;

  List<Widget> children(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final feedback = showDetails ? _feedback(state) : null;
    var i = 0;
    Widget reveal(Widget child) => HudaReveal(index: i++, child: child);
    return [
      reveal(
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SystemMendLine(
            color: tokens.ornament,
            mending: retrying,
            width: 168,
            height: 24,
          ),
        ),
      ),
      reveal(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.somethingWentWrong,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            SizedBox(height: tokens.space.xs),
            Text(
              l10n.errorScreenMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      reveal(
        Wrap(
          spacing: tokens.space.sm,
          runSpacing: tokens.space.sm,
          children: [
            FilledButton.icon(
              onPressed: Restart.restartApp,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.restartAppButton),
            ),
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l10n.copyButton),
            ),
          ],
        ),
      ),
      reveal(
        ErrorReportStatus(state: state, retrying: retrying, onRetry: onRetry),
      ),
      if (showDetails)
        reveal(ErrorTechnicalDetails(errorMessage: errorMessage)),
      ?feedback,
    ];
  }
}

/// A scrolling column at a readable width, edge to edge (the insets are
/// padding inside the scroll view).
class _Column extends StatelessWidget {
  const _Column({required this.children, this.center = false});

  final List<Widget> children;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = space.gutter(box.maxWidth);
        final padding = context.scrollPadding(
          EdgeInsets.fromLTRB(gutter, space.xxl, gutter, space.xxl),
          includeTop: true,
        );
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: center
                  ? (box.maxHeight - padding.vertical).clamp(0, double.infinity)
                  : 0,
            ),
            child: Align(
              alignment: center ? Alignment.center : Alignment.topCenter,
              child: ReadableWidth(
                maxWidth: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0) SizedBox(height: space.lg),
                      child,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
