import 'package:huda/core/theme/theme_extension.dart';
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
import 'package:flutter_screenutil/flutter_screenutil.dart';

void setCustomErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails e) => BlocProvider<ErrorCubit>(
        create: (context) => ErrorCubit()..sendError(e.exceptionAsString()),
        child: ErrorPage(errorMessage: e.exceptionAsString()),
      );
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

    // Main fade animation
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

    // Pulse animation for error icon
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

    // Slide animation for content
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

    // Enhanced feedback with haptic
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text('Error details copied to clipboard',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: "Amiri",
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
    // Extract meaningful error summary
    final lines = widget.errorMessage.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim();
      if (firstLine.length > 80) {
        return '${firstLine.substring(0, 77)}...';
      }
      return firstLine;
    }
    return 'Unknown error occurred';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Enhanced color scheme with better contrast
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

                    // Header section
                    SlideTransition(
                      position: _slideAnimation,
                      child: ErrorHeader(
                        pulseAnimation: _pulseAnimation,
                        errorSummary: _getErrorSummary(),
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Action buttons
                    SlideTransition(
                      position: _slideAnimation,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ActionButton(
                              icon: Icons.refresh_rounded,
                              label: 'Restart App',
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
                              label: 'Copy',
                              onPressed: _copyErrorToClipboard,
                              color: context.accentColor,
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Error details card
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

                    // Feedback section
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

                    // Info card
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
