import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/bookmark/bookmarks_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class ErrorStateWidget extends StatelessWidget {
  final BookmarksError state;

  const ErrorStateWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.r, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context)!.errorLoadingBookmarks,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red,
              fontFamily: 'Amiri',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.message,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => context.read<BookmarksCubit>().loadBookmarks(),
            child: Text(
              AppLocalizations.of(context)!.retry,
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
          ),
        ],
      ),
    );
  }
}
