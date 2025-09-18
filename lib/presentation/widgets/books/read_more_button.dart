import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class ReadMoreButton extends StatelessWidget {
  const ReadMoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.arrow_forward_rounded,
          size: 16.sp,
          color: context.primaryColor,
        ),
        SizedBox(width: 4.w),
        Text(
          AppLocalizations.of(context)!.readMore,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: context.primaryColor,
            fontFamily: 'Amiri',
          ),
        ),
      ],
    );
  }
}