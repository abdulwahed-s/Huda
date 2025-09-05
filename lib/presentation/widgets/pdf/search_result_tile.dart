import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/pdf/pdf_page_text_cache.dart';
import 'package:pdfrx/pdfrx.dart';

class SearchResultTile extends StatefulWidget {
  const SearchResultTile({
    required this.match,
    required this.onTap,
    required this.pageTextStore,
    required this.height,
    required this.isCurrent,
    super.key,
  });

  final PdfPageTextRange match;
  final void Function() onTap;
  final PdfPageTextCache pageTextStore;
  final double height;
  final bool isCurrent;

  @override
  State<SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<SearchResultTile> {
  PdfPageText? pageText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _release() {
    if (pageText != null) {
      widget.pageTextStore.releaseText(pageText!.pageNumber);
    }
  }

  Future<void> _load() async {
    _release();
    pageText = await widget.pageTextStore.loadText(widget.match.pageNumber);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = Text.rich(createTextSpanForMatch(pageText, widget.match));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isCurrent
            ? colorScheme.primary.withValues(alpha: 0.5)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isCurrent
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: widget.isCurrent ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            height: widget.height,
            child: text,
          ),
        ),
      ),
    );
  }

  TextSpan createTextSpanForMatch(PdfPageText? pageText, PdfPageTextRange match,
      {TextStyle? style}) {
    final colorScheme = Theme.of(context).colorScheme;
    style ??= TextStyle(
      fontSize: 13.sp,
      color: colorScheme.onSurface,
    );
    if (pageText == null) {
      return TextSpan(
        text: match.text,
        style: style,
      );
    }
    final fullText = pageText.fullText;
    int first = 0;
    for (int i = match.start - 1; i >= 0;) {
      if (fullText[i] == '\n') {
        first = i + 1;
        break;
      }
      i--;
    }
    int last = fullText.length;
    for (int i = match.end; i < fullText.length; i++) {
      if (fullText[i] == '\n') {
        last = i;
        break;
      }
    }

    final header = fullText.substring(first, match.start);
    final body = fullText.substring(match.start, match.end);
    final footer = fullText.substring(match.end, last);

    return TextSpan(
      children: [
        TextSpan(text: header, style: style),
        TextSpan(
          text: body,
          style: style.copyWith(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(text: footer, style: style),
      ],
    );
  }
}
