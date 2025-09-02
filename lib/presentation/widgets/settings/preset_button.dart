import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';

class PresetButton extends StatelessWidget {
  final double value;
  final String label;
  final bool isSelected;

  const PresetButton({
    super.key,
    required this.value,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ThemeCubit>().setTextScaleFactor(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor
              : context.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? context.primaryColor
                : context.primaryColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : context.primaryColor,
            fontFamily: "Amiri",
          ),
        ),
      ),
    );
  }
}
