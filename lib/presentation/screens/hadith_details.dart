import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/hadith_details/hadith_details_cubit.dart';
import 'package:huda/presentation/widgets/hadith_details/error_state.dart';
import 'package:huda/presentation/widgets/hadith_details/loading_state.dart';
import 'package:huda/presentation/widgets/hadith_details/hadith_list.dart';

class HadithDetails extends StatelessWidget {
  final String chapterNumber;
  final String bookName;
  final String chapterName;

  const HadithDetails({
    super.key,
    required this.chapterNumber,
    required this.bookName,
    required this.chapterName,
  });

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
          chapterName,
          style: TextStyle(
            fontFamily: "Amiri",
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HadithDetailsCubit, HadithDetailsState>(
        builder: (context, state) {
          if (state is HadithDetailsLoading) {
            return LoadingState(isDark: isDark);
          } else if (state is HadithDetailsLoaded) {
            return HadithList(
              hadithDetail: state.hadithDetail,
              isDark: isDark,
              chapterNumber: chapterNumber,
              bookName: bookName,
              chapterName: chapterName,
            );
          } else if (state is HadithDetailsError) {
            return ErrorState(isDark: isDark);
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
