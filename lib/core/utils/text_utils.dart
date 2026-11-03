class TextUtils {
  static String removeDiacriticsAndNormalize(String input) {
    final diacriticRegex = RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED]');
    String result = input.replaceAll(diacriticRegex, '');

    // Normalize Arabic letters
    result = result.replaceAll('ٱ', 'ا'); // Alef Wasla → Alef
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');
    result = result.replaceAll('ؤ', 'و'); // Waw Hamza Above → Waw
    result = result.replaceAll('ئ', 'ي'); // Ya Hamza Above → Ya
    result = result.replaceAll('ى', 'ي'); // Alif Maqsura → Ya
    result = result.replaceAll('ة', 'ه'); // Ta marbuta → Ha
    result = result.replaceAll('\u0640', ''); // Remove Tatweel (Kashida)
    result = result.replaceAll('ی', 'ي'); // Farsi Yeh → Arabic Yeh
    result = result.replaceAll('ك', 'ك'); // Normalize Kaf (keep as Arabic Kaf)
    result = result.replaceAll(
        '\u0670', ''); // Remove Superscript Alef (diacritical mark)

    // Collapse runs of whitespace left by removed Quranic markers (e.g. ۖ ۞)
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  /// Where [query] matches in [text] the way [removeDiacriticsAndNormalize]
  /// compares them (marks dropped, letters folded, spaces collapsed, Latin
  /// case ignored), as ranges of [text] (start inclusive, end exclusive),
  /// in order and not overlapping. A range takes in the marks that follow
  /// its last letter, so a highlighted word keeps its harakat.
  static List<(int, int)> normalizedMatchRanges(String text, String query) {
    final needle = removeDiacriticsAndNormalize(query.toLowerCase());
    if (needle.isEmpty) return const [];

    bool dropped(int unit) =>
        (unit >= 0x0610 && unit <= 0x061A) ||
        (unit >= 0x064B && unit <= 0x065F) ||
        (unit >= 0x06D6 && unit <= 0x06ED) ||
        unit == 0x0640 ||
        unit == 0x0670;
    const folded = {
      'ٱ': 'ا',
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ؤ': 'و',
      'ئ': 'ي',
      'ى': 'ي',
      'ة': 'ه',
      'ی': 'ي',
    };
    final space = RegExp(r'\s');

    // The normalized text, and for each of its units the unit of [text]
    // it came from.
    final normal = StringBuffer();
    final origin = <int>[];
    var lastWasSpace = true; // drops leading spaces, as trim() does
    final lower = text.toLowerCase();
    if (lower.length != text.length) return const [];
    for (var i = 0; i < lower.length; i++) {
      final unit = lower.codeUnitAt(i);
      if (dropped(unit)) continue;
      final char = lower[i];
      if (space.hasMatch(char)) {
        if (lastWasSpace) continue;
        normal.write(' ');
        origin.add(i);
        lastWasSpace = true;
        continue;
      }
      normal.write(folded[char] ?? char);
      origin.add(i);
      lastWasSpace = false;
    }

    final haystack = normal.toString();
    final ranges = <(int, int)>[];
    var from = 0;
    while (true) {
      final at = haystack.indexOf(needle, from);
      if (at < 0) break;
      final start = origin[at];
      var end = origin[at + needle.length - 1] + 1;
      while (end < text.length && dropped(text.codeUnitAt(end))) {
        end++;
      }
      ranges.add((start, end));
      from = at + needle.length;
    }
    return ranges;
  }

  static int getLevenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s2.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }

      for (int j = 0; j < s2.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }
}
