import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/book_languages/book_languages_cubit.dart';
import 'package:huda/presentation/widgets/book_detail/language_chip.dart';
import 'package:huda/presentation/widgets/book_detail/shimmer_loading.dart';

class LanguagesSection extends StatelessWidget {
  final String? selectedLanguage;
  final int bookId;
  final String currentLanguageCode;
  final Function(String?) onLanguageSelected;

  const LanguagesSection({
    super.key,
    required this.selectedLanguage,
    required this.bookId,
    required this.currentLanguageCode,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookLanguagesCubit, BookLanguagesState>(
      builder: (context, state) {
        if (state is BookTranslationsLoading) {
          return _buildLanguagesLoading();
        } else if (state is BookTranslationsLoaded &&
            state.translations.isNotEmpty) {
          return _buildLanguagesLoaded(context, state);
        } else if (state is BookTranslationsOffline) {
          // Return offline state card
          return Container();
        } else if (state is BookTranslationsError) {
          // Return error state card
          return Container();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLanguagesLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerContainer(height: 24.h, width: 200.w),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(
              5,
              (index) => ShimmerContainer(height: 40.h, width: 100.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesLoaded(
      BuildContext context, BookTranslationsLoaded state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate_rounded,
                color: context.primaryColor,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Other Languages',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: state.translations.map((translation) {
              return LanguageChip(
                translation: translation,
                locale: Locale.fromSubtags(languageCode: translation.slang),
                isSelected: selectedLanguage == translation.slang,
                onTap: () => onLanguageSelected(
                  selectedLanguage == translation.slang
                      ? null
                      : translation.slang,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
