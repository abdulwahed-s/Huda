import 'package:dart_pdf_editor/dart_pdf_editor.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';

/// A highlight ink the reader offers on a selection.
typedef PdfInk = ({Color color, String label});

/// The reader's floating capsule over the page's foot: zoom out, the page
/// ("12 / 412", opens Go to page), zoom in. While text is selected it
/// turns into the highlight inks and a clear button. A chrome capsule;
/// the two modes cross-fade.
class PdfReaderCapsule extends StatelessWidget {
  const PdfReaderCapsule({
    super.key,
    required this.controller,
    required this.selecting,
    required this.inks,
    required this.onInk,
    required this.onClearSelection,
    required this.onGoToPage,
  });

  final PdfViewerController controller;
  final bool selecting;
  final List<PdfInk> inks;
  final ValueChanged<Color> onInk;
  final VoidCallback onClearSelection;
  final VoidCallback onGoToPage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final iconTheme = IconThemeData(color: tokens.onChrome, size: 22);

    Widget pageMode() => ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final count = controller.pageCount;
        final page = (controller.currentPage + 1).clamp(
          1,
          count < 1 ? 1 : count,
        );
        return Row(
          key: const ValueKey('pages'),
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.booksZoomOut,
              onPressed: () => controller.setZoom(controller.zoom / 1.25),
              icon: const Icon(Icons.remove_rounded),
            ),
            Semantics(
              button: true,
              label: '${l10n.booksPageOf(page, count)}. ${l10n.goToPage}',
              excludeSemantics: true,
              child: Tooltip(
                message: l10n.goToPage,
                child: TextButton(
                  onPressed: count > 1 ? onGoToPage : null,
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.onChrome,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  child: Text(
                    '$page / $count',
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.booksZoomIn,
              onPressed: () => controller.setZoom(controller.zoom * 1.25),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        );
      },
    );

    Widget inkMode() => Row(
      key: const ValueKey('inks'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: space.md, end: space.xs),
          child: Text(
            l10n.booksHighlight,
            style: theme.textTheme.labelLarge?.copyWith(color: tokens.onChrome),
          ),
        ),
        for (final ink in inks)
          IconButton(
            tooltip: ink.label,
            onPressed: () => onInk(ink.color),
            icon: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: ink.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.onChrome.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
            ),
          ),
        IconButton(
          tooltip: l10n.cancel,
          onPressed: onClearSelection,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );

    return Material(
      color: tokens.chrome,
      shape: StadiumBorder(
        side: BorderSide(color: tokens.onChrome.withValues(alpha: 0.14)),
      ),
      child: Theme(
        data: theme.copyWith(
          iconTheme: iconTheme,
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: tokens.onChrome,
              disabledForegroundColor: tokens.onChromeMuted,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: space.xs),
          child: HudaStateSwitcher(
            stateKey: selecting,
            child: selecting ? inkMode() : pageMode(),
          ),
        ),
      ),
    );
  }
}
