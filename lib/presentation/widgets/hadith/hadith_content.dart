import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/hadith/hadith_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/hadith/error_state.dart';
import 'package:huda/presentation/widgets/hadith/hadith_list.dart';
import 'package:huda/presentation/widgets/hadith/loading_state.dart';
import 'package:huda/presentation/widgets/hadith/offline_state.dart';

class HadithContent extends StatelessWidget {
  const HadithContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: Text(
          AppLocalizations.of(context)!.hadith,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
            fontFamily: 'Amiri',
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HadithCubit, HadithState>(
        builder: (context, state) {
          if (state is HadithLoading) {
            return LoadingState(isDark: isDark);
          } else if (state is HadithLoaded) {
            return HadithList(
              hadithBooks: state.hadithBooks,
              isDark: isDark,
              context: context,
            );
          } else if (state is HadithOffline) {
            return OfflineState(isDark: isDark);
          } else if (state is HadithError) {
            return ErrorState(message: state.message, isDark: isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

