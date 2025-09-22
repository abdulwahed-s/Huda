import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class CustomFAB extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onPressed;

  const CustomFAB({
    super.key,
    required this.animation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: FloatingActionButton.extended(
            onPressed: onPressed,
            backgroundColor: context.primaryColor,
            elevation: 6,
            icon: Icon(Icons.add, color: Colors.white, size: 20.w),
            label: Text(
              AppLocalizations.of(context)!.addEvent,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
                fontFamily: "Amiri",
              ),
            ),
          ),
        );
      },
    );
  }
}
