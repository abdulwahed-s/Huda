import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/hadith/hadith_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class OfflineState extends StatelessWidget {
  final bool isDark;

  const OfflineState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.0.h),
          Text(
            'Error loading hadith books',
            style: TextStyle(
              fontSize: 18.sp,
              fontFamily: 'Amiri',
              color:
                  isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
            ),
          ),
          SizedBox(height: 8.0.h),
          Text(
            'No Internet Connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: 'Amiri',
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 8.0.h),
          ElevatedButton.icon(
            onPressed: () {
              context.read<HadithCubit>().fetchHadithBooks();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: 24.0.w,
                vertical: 12.0.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            icon: Icon(
              Icons.refresh,
              size: 20.sp,
            ),
            label: Text(
              AppLocalizations.of(context)!.tryAgain,
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
