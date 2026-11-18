import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:restart_app/restart_app.dart';

import 'package:huda/core/bootstrap/bootstrap.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_theme.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/screens/app.dart';
import 'package:huda/presentation/screens/error.dart' show setCustomErrorWidget;
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/error/system_identity.dart';

// The native launch screen's color and logo: the splash continues it.
const Color _bootBackground = Color(0xFF0c1d2b);
const String _bootLogo = 'assets/images/huda.png';

class Bootstrapper extends StatefulWidget {
  const Bootstrapper({super.key});

  @override
  State<Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<Bootstrapper> {
  String? _initialRoute;
  Object? _error;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _runGate();
  }

  /// A retry keeps the failure on screen with "Retrying…" until it's
  /// settled, instead of falling back to the splash.
  void _runGate({bool retry = false}) {
    setState(() {
      _initialRoute = null;
      _retrying = retry;
      if (!retry) _error = null;
    });

    initCriticalAndGetRoute()
        .then((route) {
          if (!mounted) return;
          setCustomErrorWidget();
          setState(() {
            _retrying = false;
            _initialRoute = route;
          });
        })
        .catchError((Object e, StackTrace stack) {
          debugPrint('Critical bootstrap failed: $e');
          debugPrintStack(stackTrace: stack);
          if (!mounted) return;
          setState(() {
            _retrying = false;
            _error = e;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialRoute != null) {
      return App(initialRoute: _initialRoute!);
    }

    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: bootTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalizationCubit.supportedLocales,
      home: _error != null
          ? BootRetry(onRetry: () => _runGate(retry: true), retrying: _retrying)
          : const BootSplash(),
    );
    return app;
  }
}

/// Lantern's night on the launch screen's color. Built without the
/// owner's settings, which aren't loaded yet.
ThemeData bootTheme() {
  final night = HudaTheme.build(
    colorTheme: AppColors.defaultTheme,
    brightness: Brightness.dark,
  ).extension<HudaTokens>()!.night();
  return night.copyWith(scaffoldBackgroundColor: _bootBackground);
}

class BootSplash extends StatelessWidget {
  const BootSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return _bootBars(
      Scaffold(
        backgroundColor: _bootBackground,
        body: Center(
          // GTK can report a transient 1x1 surface before the Linux window gets
          // its first real allocation. Scale the splash during that frame rather
          // than overflowing its fixed-size column.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BootLogo(size: 160),
                const SizedBox(height: 40),
                HudaLampSpinner(
                  size: 26,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Startup failed: the broken line, what happened, Retry (then
/// "Retrying…", while the line mends) and Restart.
class BootRetry extends StatelessWidget {
  const BootRetry({super.key, required this.onRetry, this.retrying = false});

  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return _bootBars(
      Scaffold(
        body: LayoutBuilder(
          builder: (context, outer) {
            // Tabletop: the gate stays above the hinge.
            final fold = FoldInfo.of(context);
            final top = fold.separatorAxis == Axis.horizontal && fold.avoided
                ? fold.start
                : null;
            final page = LayoutBuilder(
              builder: (context, box) {
                final short = box.maxHeight < 480;
                return SingleChildScrollView(
                  padding: context.scrollPadding(
                    EdgeInsets.all(tokens.space.gutter(box.maxWidth)),
                    includeTop: true,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (box.maxHeight - tokens.space.xxl * 2).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: ReadableWidth(
                        maxWidth: 420,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _BootLogo(size: short ? 72 : 112),
                            SizedBox(height: tokens.space.lg),
                            SystemMendLine(
                              color: tokens.gilt,
                              mending: retrying,
                              width: 180,
                              height: 24,
                            ),
                            SizedBox(height: tokens.space.lg),
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.bootFailedTitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                            SizedBox(height: tokens.space.xs),
                            Text(
                              l10n.bootFailedMessage,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: tokens.space.xl),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: tokens.space.sm,
                              runSpacing: tokens.space.sm,
                              children: [
                                HudaRetryButton(
                                  onRetry: onRetry,
                                  retrying: retrying,
                                ),
                                OutlinedButton(
                                  onPressed: Restart.restartApp,
                                  child: Text(l10n.restartAppButton),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
            if (top == null || top < 200) return page;
            return Column(
              children: [
                SizedBox(
                  height: top,
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: page,
                  ),
                ),
                const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BootLogo extends StatelessWidget {
  const _BootLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _bootLogo,
      width: size,
      height: size,
      errorBuilder: (_, _, _) => SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.mosque, size: size * 0.6, color: Colors.white70),
      ),
    );
  }
}

/// Transparent bars with light icons over the night.
Widget _bootBars(Widget child) => AnnotatedRegion<SystemUiOverlayStyle>(
  value: HudaSystemUi.over(top: Brightness.dark, bottom: Brightness.dark),
  child: child,
);
