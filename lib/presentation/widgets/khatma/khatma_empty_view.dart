import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_gradient_button.dart';

class KhatmaEmptyView extends StatelessWidget {
  final TextDirection textDirection;
  final VoidCallback onStartNew;

  const KhatmaEmptyView({
    super.key,
    required this.textDirection,
    required this.onStartNew,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const Spacer(),
        Container(
          width: 100.r,
          height: 100.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              accent.withValues(alpha: 0.18),
              accent.withValues(alpha: 0.04),
            ]),
          ),
          child: Icon(Icons.menu_book_rounded,
              size: 46.sp, color: accent.withValues(alpha: 0.75)),
        ),
        SizedBox(height: 18.h),
        Text(
          l10n.khatmaTitle,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 36.w),
          child: Text(
            l10n.khatmaDescription,
            textAlign: TextAlign.center,
            textDirection: textDirection,
            style: TextStyle(
              height: 1.7,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ),
        SizedBox(height: 30.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: KhatmaGradientButton(
            label: l10n.khatmaStartNew,
            icon: Icons.add_rounded,
            onPressed: onStartNew,
            accent: accent,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
