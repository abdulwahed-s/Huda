import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/error/action_button.dart';
import 'package:huda/presentation/widgets/error/error_details_card.dart';
import 'package:huda/presentation/widgets/error/error_header.dart';
import 'package:huda/presentation/widgets/error/feedback_section.dart';
import 'package:huda/presentation/widgets/error/info_card.dart';
import 'package:restart_app/restart_app.dart';
import '../../cubit/error/error_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';

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
        final bigEnough = constraints.hasBoundedWidth &&
            constraints.hasBoundedHeight &&
            constraints.maxWidth > 200 &&
            constraints.maxHeight > 200;

        if (!bigEnough) {
          return _MinimalErrorFallback(
            message: errorMessage.split('\n').first.trim(),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(
              create: (_) => ErrorCubit()..sendFlutterError(errorDetails),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            builder: (_, __) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LocalizationCubit.supportedLocales,
              home: ErrorPage(errorMessage: errorMessage),
            ),
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

class ErrorPage extends StatefulWidget {
  final String errorMessage;

  const ErrorPage({required this.errorMessage, super.key});

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _copyErrorToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.errorMessage));

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
                AppLocalizations.of(context)?.errorDetailsCopied ??
                    'Error details copied',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
        backgroundColor: context.accentColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restartApp() {
    HapticFeedback.heavyImpact();
    Restart.restartApp();
  }

  String _getErrorSummary() {
    final lines = widget.errorMessage.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim();
      if (firstLine.length > 80) {
        return '${firstLine.substring(0, 77)}...';
      }
      return firstLine;
    }
    return AppLocalizations.of(context)?.unknownErrorOccurred ??
        'An unknown error occurred';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? context.darkGradientStart : const Color(0xFFF8FAFC);
    final cardColor = isDark ? context.darkCardBackground : Colors.white;
    final textColor = isDark ? context.darkText : const Color(0xFF1E293B);
    final subtitleColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.08);
    final errorCodeBg =
        isDark ? context.darkGradientMid : const Color(0xFFF1F5F9);
    final errorCodeText =
        isDark ? Colors.grey.shade300 : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(20.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: 20.h),
                    SlideTransition(
                      position: _slideAnimation,
                      child: ErrorHeader(
                        pulseAnimation: _pulseAnimation,
                        errorSummary: _getErrorSummary(),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ActionButton(
                              icon: Icons.refresh_rounded,
                              label: AppLocalizations.of(context)
                                      ?.restartAppButton ??
                                  'Restart app',
                              onPressed: _restartApp,
                              color: context.primaryColor,
                              isPrimary: true,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            flex: 2,
                            child: ActionButton(
                              icon: Icons.copy_rounded,
                              label: AppLocalizations.of(context)?.copyButton ??
                                  'Copy',
                              onPressed: _copyErrorToClipboard,
                              color: context.accentColor,
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),
                    SlideTransition(
                      position: _slideAnimation,
                      child: ErrorDetailsCard(
                        errorMessage: widget.errorMessage,
                        isDark: isDark,
                        borderColor: borderColor,
                        shadowColor: shadowColor,
                        errorCodeBg: errorCodeBg,
                        errorCodeText: errorCodeText,
                        textColor: textColor,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FeedbackSection(
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        shadowColor: shadowColor,
                        errorCodeBg: errorCodeBg,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    SlideTransition(
                      position: _slideAnimation,
                      child: InfoCard(
                        isDark: isDark,
                        textColor: textColor,
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
