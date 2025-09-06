import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final ValueNotifier<bool> showLeftPane;
  final bool isHorizontalLayout;
  final VoidCallback changeLayoutType;
  final VoidCallback showGoToPageDialog;
  final PdfViewerController pdfViewerController;

  const PdfAppBar({
    super.key,
    required this.isDark,
    required this.colorScheme,
    required this.showLeftPane,
    required this.isHorizontalLayout,
    required this.changeLayoutType,
    required this.showGoToPageDialog,
    required this.pdfViewerController,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showLeftPane,
      builder: (context, showPane, child) {
        return AppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          foregroundColor: colorScheme.onSurface,
          title: Text(
            AppLocalizations.of(context)!.pdfViewer,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
          leading: IconButton(
            icon: AnimatedRotation(
              turns: showLeftPane.value ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                showLeftPane.value ? Icons.menu_open : Icons.menu,
                color: colorScheme.primary,
              ),
            ),
            onPressed: () {
              showLeftPane.value = !showLeftPane.value;
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  isHorizontalLayout ? Icons.view_agenda : Icons.view_day,
                  color: colorScheme.primary,
                ),
                onPressed: changeLayoutType,
                tooltip: AppLocalizations.of(context)!.switchLayout,
              ),
            ),
            IconButton(
              icon: Icon(Icons.find_in_page_outlined,
                  color: colorScheme.onSurface),
              onPressed: () {
                if (pdfViewerController.isReady) {
                  showGoToPageDialog();
                }
              },
              tooltip: AppLocalizations.of(context)!.goToPage,
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
