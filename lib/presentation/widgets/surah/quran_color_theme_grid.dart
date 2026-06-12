import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuranColorThemeGrid extends StatelessWidget {
  final List<List<Color>> presets;
  final Color? selectedBgColor;
  final Color? selectedTextColor;
  final bool isDark;
  final Color accent;
  final void Function(Color bg, Color text) onSelect;

  const QuranColorThemeGrid({
    super.key,
    required this.presets,
    required this.selectedBgColor,
    required this.selectedTextColor,
    required this.isDark,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 1.6,
        ),
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final pair = presets[index];
          final bg = pair[0];
          final text = pair[1];
          final isSelected = selectedBgColor == bg && selectedTextColor == text;
          return GestureDetector(
            onTap: () => onSelect(bg, text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : (isDark ? Colors.white24 : Colors.black12),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isSelected
                    ? Container(
                        width: 26.r,
                        height: 26.r,
                        decoration: BoxDecoration(
                          color: text,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: bg,
                          size: 16.sp,
                        ),
                      )
                    : Container(
                        width: 20.r,
                        height: 20.r,
                        decoration: BoxDecoration(
                          color: text,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
