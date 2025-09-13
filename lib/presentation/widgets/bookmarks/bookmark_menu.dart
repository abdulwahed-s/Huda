import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/bookmark_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/bookmarks/menu_item_widget.dart';

class BookmarkMenu extends StatelessWidget {
  final BookmarkModel bookmark;
  final bool isDark;
  final Function(String, BookmarkModel) onHandleBookmarkAction;

  const BookmarkMenu({
    super.key,
    required this.bookmark,
    required this.isDark,
    required this.onHandleBookmarkAction,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 8,
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) => onHandleBookmarkAction(value, bookmark),
        icon: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: (isDark ? Colors.grey[700] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.more_vert,
            size: 18.r,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        itemBuilder: (context) => [
          if (bookmark.type == BookmarkType.note)
            PopupMenuItem(
              value: 'edit',
              child: MenuItemWidget(
                icon: Icons.edit,
                color: Colors.blue,
                label: AppLocalizations.of(context)!.editNote,
                isDark: isDark,
              ),
            ),
          PopupMenuItem(
            value: 'navigate',
            child: MenuItemWidget(
              icon: Icons.navigation,
              color: Colors.green,
              label: AppLocalizations.of(context)!.goToVerse,
              isDark: isDark,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: MenuItemWidget(
              icon: Icons.delete,
              color: Colors.red,
              label: AppLocalizations.of(context)!.delete,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

