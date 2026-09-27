import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

class HadithTextRun {
  final String text;
  final bool bold;
  final bool italic;
  final bool narrator;
  final bool quran;

  const HadithTextRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.narrator = false,
    this.quran = false,
  });
}

class FormattedHadithText {
  final List<HadithTextRun> runs;

  const FormattedHadithText(this.runs);

  String get plainText => runs.map((run) => run.text).join();
}

class HadithTextFormatter {
  static final _quranShortcode = RegExp(
    r'\[(/?)quran(?:\s+[^\]]*)?\]',
    caseSensitive: false,
  );
  static final _shortcode = RegExp(
    r'\[(/?)(prematn|matn|postmatn|commentary|narrator|quran)(?:\s+[^\]]*)?\]',
    caseSensitive: false,
  );

  static FormattedHadithText format(String source) {
    final spaced = source.replaceAllMapped(
      RegExp(
        r'(\[/(?:prematn|matn|postmatn)\])(?=\[(?:prematn|matn|postmatn)(?:\s|\]))',
        caseSensitive: false,
      ),
      (match) => '${match[1]} ',
    );

    final repaired = _closeUnterminatedQuranQuotes(spaced);
    final html = repaired.replaceAllMapped(_shortcode, (match) {
      final tag = match[2]!.toLowerCase();
      if (match[1] == '/') return '</span>';
      return '<span data-hadith-tag="$tag">';
    });

    final composer = _HadithRunComposer();
    final fragment = html_parser.parseFragment(html);
    for (final node in fragment.nodes) {
      composer.visit(node, const _HadithFormat());
    }
    return FormattedHadithText(composer.finish());
  }

  static String _closeUnterminatedQuranQuotes(String source) {
    final tags = _quranShortcode.allMatches(source).toList();
    var repaired = source;

    for (var i = tags.length - 1; i >= 0; i--) {
      final tag = tags[i];
      if (tag[1] == '/') continue;

      final next = i + 1 < tags.length ? tags[i + 1] : null;
      if (next != null && next[1] == '/') continue;

      final boundary = next?.start ?? source.length;
      final openingBrace = source.indexOf('{', tag.end);
      final closingBrace = openingBrace >= 0
          ? source.indexOf('}', openingBrace + 1)
          : -1;
      if (openingBrace >= 0 &&
          openingBrace < boundary &&
          closingBrace >= 0 &&
          closingBrace < boundary) {
        repaired = repaired.replaceRange(
          closingBrace + 1,
          closingBrace + 1,
          '[/quran]',
        );
      } else {
        repaired = repaired.replaceRange(tag.start, tag.end, '');
      }
    }
    return repaired;
  }
}

class _HadithFormat {
  final bool bold;
  final bool italic;
  final bool narrator;
  final bool quran;

  const _HadithFormat({
    this.bold = false,
    this.italic = false,
    this.narrator = false,
    this.quran = false,
  });

  _HadithFormat withElement(dom.Element element) {
    final tag = element.localName;
    final shortcode = element.attributes['data-hadith-tag'];
    final style = element.attributes['style']?.toLowerCase() ?? '';
    return _HadithFormat(
      bold:
          bold ||
          tag == 'b' ||
          tag == 'strong' ||
          shortcode == 'matn' ||
          element.classes.contains('matn') ||
          style.contains('font-weight: bold') ||
          style.contains('font-weight: 700'),
      italic:
          italic ||
          tag == 'i' ||
          tag == 'em' ||
          shortcode == 'commentary' ||
          style.contains('font-style: italic'),
      narrator:
          narrator ||
          shortcode == 'narrator' ||
          element.classes.contains('narrator'),
      quran: quran || shortcode == 'quran' || element.classes.contains('quran'),
    );
  }
}

class _HadithRunComposer {
  static final _markdownBold = RegExp(r'(\*\*|__)(.+?)\1');
  static final _whitespace = RegExp(r'[ \t\f\v\u00a0]+');
  final List<HadithTextRun> _runs = [];

  void visit(dom.Node node, _HadithFormat format) {
    if (node is dom.Text) {
      _addText(node.text, format);
      return;
    }
    if (node is! dom.Element) return;

    final tag = node.localName;
    if (tag == 'script' || tag == 'style' || tag == 'template') return;
    if (tag == 'br') {
      _addBreak(1);
      return;
    }
    if (tag == 'hr') {
      _addBreak(2);
      return;
    }
    if (tag == 'img') {
      _addText(node.attributes['alt'] ?? '', format);
      return;
    }

    final isParagraph =
        tag == 'p' ||
        tag == 'blockquote' ||
        tag == 'h1' ||
        tag == 'h2' ||
        tag == 'h3' ||
        node.attributes['data-hadith-tag'] == 'commentary';
    final isLine = tag == 'div' || tag == 'li';
    if (isParagraph || isLine) _addBreak(isParagraph ? 2 : 1);
    if (tag == 'li') _addText('• ', format);

    final childFormat = format.withElement(node);
    for (final child in node.nodes) {
      visit(child, childFormat);
    }
    if (isParagraph || isLine) _addBreak(isParagraph ? 2 : 1);
  }

  void _addText(String value, _HadithFormat format) {
    final normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(_whitespace, ' ');
    var cursor = 0;
    for (final breakMatch in RegExp(r'\n+').allMatches(normalized)) {
      _addMarkdownText(normalized.substring(cursor, breakMatch.start), format);
      _addBreak(breakMatch.group(0)!.length > 1 ? 2 : 1);
      cursor = breakMatch.end;
    }
    _addMarkdownText(normalized.substring(cursor), format);
  }

  void _addMarkdownText(String line, _HadithFormat format) {
    var cursor = 0;
    for (final match in _markdownBold.allMatches(line)) {
      _addRun(line.substring(cursor, match.start), format);
      _addRun(
        match[2]!,
        _HadithFormat(
          bold: true,
          italic: format.italic,
          narrator: format.narrator,
          quran: format.quran,
        ),
      );
      cursor = match.end;
    }
    _addRun(line.substring(cursor), format);
  }

  void _addRun(String value, _HadithFormat format) {
    if (value.isEmpty) return;
    var text = value;
    if (_runs.isEmpty || _runs.last.text.endsWith('\n')) {
      text = text.trimLeft();
    } else if (_runs.last.text.endsWith(' ') && text.startsWith(' ')) {
      text = text.substring(1);
    }
    if (text.isEmpty) return;

    final run = HadithTextRun(
      text,
      bold: format.bold,
      italic: format.italic,
      narrator: format.narrator,
      quran: format.quran,
    );
    _runs.add(run);
  }

  void _addBreak(int count) {
    if (_runs.isEmpty) return;
    while (_runs.isNotEmpty &&
        _runs.last.text.trim().isEmpty &&
        !_runs.last.text.contains('\n')) {
      _runs.removeLast();
    }
    if (_runs.isEmpty) return;
    final last = _runs.last;
    if (last.text.endsWith('\n')) {
      if (count == 2 && last.text == '\n') {
        _runs[_runs.length - 1] = const HadithTextRun('\n\n');
      }
      return;
    }
    final trimmed = last.text.trimRight();
    if (trimmed.isEmpty) {
      _runs.removeLast();
    } else if (trimmed != last.text) {
      _runs[_runs.length - 1] = HadithTextRun(
        trimmed,
        bold: last.bold,
        italic: last.italic,
        narrator: last.narrator,
        quran: last.quran,
      );
    }
    if (_runs.isNotEmpty) _runs.add(HadithTextRun('\n' * count));
  }

  List<HadithTextRun> finish() {
    while (_runs.isNotEmpty && _runs.last.text.trim().isEmpty) {
      _runs.removeLast();
    }
    if (_runs.isNotEmpty) {
      final last = _runs.last;
      _runs[_runs.length - 1] = HadithTextRun(
        last.text.trimRight(),
        bold: last.bold,
        italic: last.italic,
        narrator: last.narrator,
        quran: last.quran,
      );
    }
    return List.unmodifiable(_runs);
  }
}
