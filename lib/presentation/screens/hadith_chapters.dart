import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/chapters/chapters_cubit.dart';
import 'package:huda/presentation/widgets/hadith_chapters/chapters_list.dart';

class HadithChapters extends StatelessWidget {
  final String bookName;
  final String fullBookName;

  const HadithChapters({
    super.key,
    required this.bookName,
    required this.fullBookName,
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
          fullBookName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            fontFamily: 'Amiri',
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ChaptersCubit, ChaptersState>(
        builder: (context, state) {
          if (state is ChaptersLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ChaptersLoaded) {
            return ChaptersList(
              bookName: bookName,
              chapters: state.bookChapters.data!,
              isDark: isDark,
            );
          } else if (state is ChaptersError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
