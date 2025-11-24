import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ModeButton extends StatefulWidget {
  final IconData? icon;
  final String? svgPath;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback? onTap;

  const ModeButton({super.key, 
    this.icon,
    this.svgPath,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    this.onTap,
  }) : assert(icon != null || svgPath != null,
            'Either icon or svgPath must be provided');

  @override
  State<ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<ModeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered && !widget.isSelected) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced color scheme for selected/unselected states
    final Color textColor;
    final Color iconColor;

    if (widget.isSelected) {
      // Selected state - always white on colored background
      textColor = Colors.white;
      iconColor = Colors.white;
    } else {
      // Unselected state - dark in light mode, light in dark mode
      textColor =
          widget.isDark ? const Color(0xFFB0B0B0) : const Color(0xFF424242);
      iconColor =
          widget.isDark ? const Color(0xFF9E9E9E) : const Color(0xFF616161);
    }

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: widget.primaryColor.withValues(alpha: 0.1),
          highlightColor: widget.primaryColor.withValues(alpha: 0.05),
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: !widget.isSelected && _isHovered
                      ? (widget.isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02))
                      : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: widget.svgPath != null
                          ? SvgPicture.asset(
                              widget.svgPath!,
                              width: widget.isSelected ? 21 : 20,
                              height: widget.isSelected ? 21 : 20,
                              colorFilter: ColorFilter.mode(
                                iconColor,
                                BlendMode.srcIn,
                              ),
                            )
                          : Icon(
                              widget.icon,
                              size: widget.isSelected ? 21 : 20,
                              color: iconColor,
                            ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontSize: widget.isSelected ? 15.5 : 15,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.4,
                        height: 1.2,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
