import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/pdf/marker.dart';
import 'package:huda/presentation/widgets/pdf/modern_markers_view.dart';
import 'package:huda/presentation/widgets/pdf/outline_view.dart';
import 'package:huda/presentation/widgets/pdf/text_search_view.dart';
import 'package:huda/presentation/widgets/pdf/thumbnails_view.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfSidebar extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final ValueNotifier<bool> showLeftPane;
  final ValueNotifier<PdfTextSearcher?> textSearcher;
  final ValueNotifier<List<PdfOutlineNode>?> outline;
  final ValueNotifier<PdfDocumentRef?> documentRef;
  final Map<int, List<Marker>> markers;
  final PdfViewerController pdfViewerController;

  const PdfSidebar({
    super.key,
    required this.isDark,
    required this.colorScheme,
    required this.showLeftPane,
    required this.textSearcher,
    required this.outline,
    required this.documentRef,
    required this.markers,
    required this.pdfViewerController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: showLeftPane.value ? 280.w : 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          boxShadow: showLeftPane.value
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(2, 0),
                  ),
                ]
              : [],
        ),
        child: showLeftPane.value
            ? DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        labelColor: colorScheme.primary,
                        unselectedLabelColor:
                            colorScheme.onSurface.withValues(alpha: 0.6),
                        indicatorColor: colorScheme.primary,
                        indicatorWeight: 3,
                        labelStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: [
                          Tab(
                              icon: const Icon(Icons.search_outlined, size: 20),
                              text: AppLocalizations.of(context)!.search),
                          Tab(
                              icon:
                                  const Icon(Icons.list_alt_outlined, size: 20),
                              text: AppLocalizations.of(context)!.contents),
                          Tab(
                              icon: const Icon(Icons.photo_library_outlined,
                                  size: 20),
                              text: AppLocalizations.of(context)!.pages),
                          Tab(
                              icon: const Icon(Icons.bookmark_border, size: 20),
                              text: AppLocalizations.of(context)!.markers),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ValueListenableBuilder(
                            valueListenable: textSearcher,
                            builder: (context, textSearcher, child) {
                              if (textSearcher == null) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return TextSearchView(textSearcher: textSearcher);
                            },
                          ),
                          ValueListenableBuilder(
                            valueListenable: outline,
                            builder: (context, outline, child) {
                              return OutlineView(
                                outline: outline,
                                controller: pdfViewerController,
                              );
                            },
                          ),
                          ValueListenableBuilder(
                            valueListenable: documentRef,
                            builder: (context, docRef, child) {
                              return ThumbnailsView(
                                documentRef: docRef,
                                controller: pdfViewerController,
                              );
                            },
                          ),
                          ModernMarkersView(
                            markers: markers.values.expand((e) => e).toList(),
                            onTap: (marker) {
                              final rect =
                                  pdfViewerController.calcRectForRectInsidePage(
                                pageNumber: marker.range.pageNumber,
                                rect: marker.range.bounds,
                              );
                              pdfViewerController.ensureVisible(rect);
                            },
                            onDeleteTap: (marker) {
                              markers[marker.range.pageNumber]!.remove(marker);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
