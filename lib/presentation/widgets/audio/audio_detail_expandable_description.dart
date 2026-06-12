import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class AudioDetailExpandableDescription extends StatefulWidget {
  final String text;
  final bool isDark;

  const AudioDetailExpandableDescription({
    super.key,
    required this.text,
    required this.isDark,
  });

  @override
  State<AudioDetailExpandableDescription> createState() =>
      _AudioDetailExpandableDescriptionState();
}

class _AudioDetailExpandableDescriptionState
    extends State<AudioDetailExpandableDescription> {
  bool _expanded = false;
  static const int _collapsedLines = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 18.h,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              AppLocalizations.of(context)!.aboutThisAudio,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? context.darkText : context.lightText,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Text(
            widget.text,
            maxLines: _collapsedLines,
            overflow: TextOverflow.ellipsis,
            style: _textStyle(context),
          ),
          secondChild: Text(widget.text, style: _textStyle(context)),
        ),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded
                ? AppLocalizations.of(context)!.readLess
                : AppLocalizations.of(context)!.readMore,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: context.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _textStyle(BuildContext context) => TextStyle(
        fontSize: 14.sp,
        height: 1.65,
        color: (widget.isDark ? context.darkText : context.lightText)
            .withValues(alpha: 0.75),
      );
}
