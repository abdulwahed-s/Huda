import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class HadithText extends StatelessWidget {
  final String text;
  final bool isDark;
  final String currentLanguageCode;

  const HadithText({
    super.key,
    required this.text,
    required this.isDark,
    required this.currentLanguageCode,
  });

  String _convertToHtml(String text) {
    String converted = text
        .replaceAll('[prematn]', '<span class="prematn">')
        .replaceAll('[/prematn]', '</span>')
        .replaceAll('[matn]', '<span class="matn">')
        .replaceAll('[/matn]', '</span>');

    converted = converted.replaceAllMapped(
      RegExp(r'\[narrator id="([^"]*)" tooltip="([^"]*)"\]'),
      (match) => '<span class="narrator" title="${match.group(2)}">',
    );
    converted = converted.replaceAll('[/narrator]', '</span>');

    return converted;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = currentLanguageCode == "ar";
    final baseStyle = TextStyle(
      fontSize: 16.0.sp,
      height: 1.6,
      color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
    );
    final narratorColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;

    final document = html_parser.parse(_convertToHtml(text));

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: _buildSpans(
          document.body?.nodes ?? const <dom.Node>[],
          baseStyle,
          narratorColor,
        ),
      ),
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
    );
  }

  List<InlineSpan> _buildSpans(
    List<dom.Node> nodes,
    TextStyle style,
    Color narratorColor,
  ) {
    final spans = <InlineSpan>[];

    for (final node in nodes) {
      if (node is dom.Text) {
        final text = node.text.replaceAll(RegExp(r'\s+'), ' ');
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: text, style: style));
        }
      } else if (node is dom.Element) {
        final tag = node.localName;

        if (tag == 'br') {
          spans.add(const TextSpan(text: '\n'));
          continue;
        }

        var childStyle = style;
        if (node.classes.contains('matn')) {
          childStyle = childStyle.copyWith(fontWeight: FontWeight.bold);
        }
        if (node.classes.contains('narrator')) {
          childStyle = childStyle.copyWith(color: narratorColor);
        }

        if ((tag == 'p' || tag == 'div') && spans.isNotEmpty) {
          spans.add(const TextSpan(text: '\n'));
        }

        spans.addAll(_buildSpans(node.nodes, childStyle, narratorColor));
      }
    }

    return spans;
  }
}
