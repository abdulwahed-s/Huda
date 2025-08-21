import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/theme_extension.dart';

class ZakatCalculatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onHelpPressed;
  final TabController tabController;

  const ZakatCalculatorAppBar({
    super.key,
    required this.onBackPressed,
    required this.onHelpPressed,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        AppLocalizations.of(context)!.zakatCalculator,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
          fontFamily: "Amiri",
          letterSpacing: 0.3,
          shadows: [
            Shadow(
              offset: const Offset(0, 1),
              blurRadius: 3,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
      centerTitle: true,
      toolbarHeight: 65.h,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryColor,
              context.primaryColor.withValues(alpha: 0.95),
              context.primaryColor.withValues(alpha: 0.85),
              context.primaryColor.withValues(alpha: 0.9),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 22.sp,
        ),
        onPressed: onBackPressed,
        splashRadius: 24,
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.help_outline_rounded,
            color: Colors.white,
            size: 24.sp,
          ),
          onPressed: onHelpPressed,
          splashRadius: 24,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48.h),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          child: TabBar(
            controller: tabController,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.1)),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white,
                  width: 3,
                ),
              ),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
            labelStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              fontFamily: "Amiri",
              letterSpacing: 0.4,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              fontFamily: "Amiri",
              letterSpacing: 0.3,
            ),
            labelPadding:
                EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            tabs: [
              Tab(text: AppLocalizations.of(context)!.calculate),
              Tab(text: AppLocalizations.of(context)!.results),
              Tab(text: AppLocalizations.of(context)!.settings),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(113.h); // 65 + 48
}