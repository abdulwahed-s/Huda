import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/bookmarks/back_button_widget.dart';
import 'package:huda/presentation/widgets/bookmarks/options_button.dart';
import 'package:huda/presentation/widgets/bookmarks/search_bar_widget.dart';
import 'package:huda/presentation/widgets/bookmarks/tab_bar_widget.dart';
import 'package:huda/presentation/widgets/bookmarks/title_widget.dart';

class BookmarksAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOptionsPressed;
  final TabController tabController;

  const BookmarksAppBar({
    super.key,
    required this.isDark,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOptionsPressed,
    required this.tabController,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 130.h);

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      foregroundColor: isDark ? appColors.darkText : appColors.lightText,
      leading: BackButtonWidget(isDark: isDark),
      title: TitleWidget(isDark: isDark),
      actions: [OptionsButton(isDark: isDark, onPressed: onOptionsPressed)],
      bottom: PreferredSize(
        preferredSize: preferredSize,
        child: Column(
          children: [
            SearchBarWidget(
              isDark: isDark,
              controller: searchController,
              onChanged: onSearchChanged,
            ),
            TabBarWidget(
              isDark: isDark,
              tabController: tabController,
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}
