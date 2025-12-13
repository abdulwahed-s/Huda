import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/huda_ai/mode_button.dart';

class ModeSwitcher extends StatefulWidget {
  final bool isCounselingMode;
  final bool isDark;
  final VoidCallback onModeChanged;

  const ModeSwitcher({
    super.key,
    required this.isCounselingMode,
    required this.isDark,
    required this.onModeChanged,
  });

  @override
  State<ModeSwitcher> createState() => _ModeSwitcherState();
}

class _ModeSwitcherState extends State<ModeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    if (!widget.isCounselingMode) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ModeSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCounselingMode != widget.isCounselingMode) {
      if (widget.isCounselingMode) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;

    // Enhanced color scheme for light/dark modes
    final containerBgColor = widget.isDark
        ? const Color(0xFF1A1A1A).withValues(alpha: 0.8)
        : Colors.white;

    final containerBorderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final shadowColor = widget.isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: containerBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: containerBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          if (widget.isDark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.02),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Animated sliding background indicator with enhanced styling
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (1 - _slideAnimation.value) *
                      (MediaQuery.of(context).size.width - 40) /
                      2,
                  right: _slideAnimation.value *
                      (MediaQuery.of(context).size.width - 40) /
                      2,
                  top: 0,
                  bottom: 0,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDark
                              ? [
                                  primaryColor.withValues(alpha: 0.9),
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.85),
                                ]
                              : [
                                  primaryColor.withValues(alpha: 0.85),
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.9),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(
                                alpha: widget.isDark ? 0.4 : 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: primaryColor.withValues(
                                alpha: widget.isDark ? 0.2 : 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      // Inner glow effect
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(
                                  alpha: widget.isDark ? 0.15 : 0.25),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Buttons overlay
            Row(
              children: [
                Expanded(
                  child: ModeButton(
                    icon: Icons.chat_bubble_outline,
                    label: AppLocalizations.of(context)!.chat,
                    isSelected: !widget.isCounselingMode,
                    isDark: widget.isDark,
                    primaryColor: primaryColor,
                    onTap:
                        widget.isCounselingMode ? widget.onModeChanged : null,
                  ),
                ),
                Expanded(
                  child: ModeButton(
                    svgPath: 'assets/images/consulting.svg',
                    label: AppLocalizations.of(context)!.counseling,
                    isSelected: widget.isCounselingMode,
                    isDark: widget.isDark,
                    primaryColor: primaryColor,
                    onTap:
                        !widget.isCounselingMode ? widget.onModeChanged : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
