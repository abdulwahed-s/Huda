import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140.h,
      floating: false,
      pinned: true,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: context.primaryColor,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryColor,
              context.primaryLightColor,
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: Text(
            AppLocalizations.of(context)!.huda,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: "Amiri",
            ),
          ),
          titlePadding: EdgeInsets.only(
            left: 20.w,
            bottom: 16.h,
            right: 20.w,
          ),
        ),
      ),
    );
  }
}
