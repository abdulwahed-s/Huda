import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/l10n/app_localizations.dart';

class UpdateDialog extends StatefulWidget {
  final String version;
  final String? releaseNotes;
  final VoidCallback onUpdate;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.onUpdate,
    this.releaseNotes,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: child),
        );
      },
      child: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        elevation: 24,
        shadowColor: primaryColor.withValues(alpha: 0.3),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal:
              context.responsive(mobile: 24.w, tablet: 40.0, desktop: 40.0),
          vertical:
              context.responsive(mobile: 40.h, tablet: 40.0, desktop: 40.0),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.responsive(
                mobile: 400.w, tablet: 480.0, desktop: 520.0),
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1E1E1E),
                      context.darkGradientMid,
                      context.darkGradientEnd,
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFF8F6F4),
                      Colors.white,
                    ],
            ),
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, isDark, primaryColor),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildBody(context, isDark, primaryColor),
                ),
              ),
              _buildButtons(context, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.responsive(mobile: 24.w, tablet: 28.0, desktop: 28.0),
            context.responsive(mobile: 28.h, tablet: 32.0, desktop: 32.0),
            context.responsive(mobile: 24.w, tablet: 28.0, desktop: 28.0),
            context.responsive(mobile: 16.h, tablet: 20.0, desktop: 20.0),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(
                  context.responsive(mobile: 16.w, tablet: 18.0, desktop: 20.0),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.15),
                      context.accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  size: context.responsive(
                      mobile: 32.sp, tablet: 36.0, desktop: 40.0),
                  color: primaryColor,
                ),
              ),
              SizedBox(
                  height: context.responsive(
                      mobile: 16.h, tablet: 18.0, desktop: 20.0)),
              Text(
                l10n.updateAvailableTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsive(
                      mobile: 24.sp, tablet: 28.0, desktop: 30.0),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              SizedBox(
                  height: context.responsive(
                      mobile: 8.h, tablet: 10.0, desktop: 10.0)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(
                      mobile: 14.w, tablet: 16.0, desktop: 16.0),
                  vertical: context.responsive(
                      mobile: 5.h, tablet: 6.0, desktop: 7.0),
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  l10n.whatsNewVersion(widget.version),
                  style: TextStyle(
                    fontSize: context.responsive(
                        mobile: 13.sp, tablet: 15.0, desktop: 15.0),
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;
    final notes = widget.releaseNotes?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsive(mobile: 24.w, tablet: 28.0, desktop: 28.0),
        context.responsive(mobile: 4.h, tablet: 6.0, desktop: 6.0),
        context.responsive(mobile: 24.w, tablet: 28.0, desktop: 28.0),
        context.responsive(mobile: 8.h, tablet: 10.0, desktop: 10.0),
      ),
      child: hasNotes
          ? Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                context.responsive(mobile: 16.w, tablet: 18.0, desktop: 18.0),
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  width: 1,
                ),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: context.responsive(
                      mobile: 14.sp, tablet: 15.0, desktop: 16.0),
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            )
          : Text(
              l10n.updateAvailableBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsive(
                    mobile: 15.sp, tablet: 16.0, desktop: 17.0),
                fontWeight: FontWeight.w400,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
    );
  }

  Widget _buildButtons(BuildContext context, Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsive(mobile: 20.w, tablet: 24.0, desktop: 24.0),
        context.responsive(mobile: 8.h, tablet: 10.0, desktop: 10.0),
        context.responsive(mobile: 20.w, tablet: 24.0, desktop: 24.0),
        context.responsive(mobile: 20.h, tablet: 22.0, desktop: 22.0),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                widget.onUpdate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: primaryColor.withValues(alpha: 0.4),
                padding: EdgeInsets.symmetric(
                  vertical: context.responsive(
                      mobile: 14.h, tablet: 16.0, desktop: 16.0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: context.responsive(
                        mobile: 20.sp, tablet: 22.0, desktop: 22.0),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.updateNow,
                    style: TextStyle(
                      fontSize: context.responsive(
                          mobile: 16.sp, tablet: 18.0, desktop: 18.0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
              height:
                  context.responsive(mobile: 4.h, tablet: 6.0, desktop: 6.0)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.updateLater,
              style: TextStyle(
                fontSize: context.responsive(
                    mobile: 14.sp, tablet: 15.0, desktop: 16.0),
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
