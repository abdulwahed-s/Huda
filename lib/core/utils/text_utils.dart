class TextUtils {
  static String removeDiacriticsAndNormalize(String input) {
    final diacriticRegex =
        RegExp(r'[\u064B-\u0652\u0653\u0654\u0655\u06D6-\u06ED\u0610-\u061A]');
    String result = input.replaceAll(diacriticRegex, '');

    // Normalize Arabic letters
    result = result.replaceAll('ٱ', 'ا'); // Alef Wasla → Alef
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');
    result = result.replaceAll('ى', 'ي'); // Alif Maqsura → Ya
    result = result.replaceAll('ة', 'ه'); // Ta marbuta → Ha
    result = result.replaceAll('\u0640', ''); // Remove Tatweel (Kashida)
    result = result.replaceAll('ی', 'ي'); // Farsi Yeh → Arabic Yeh
    result = result.replaceAll('ك', 'ك'); // Normalize Kaf (keep as Arabic Kaf)
    result = result.replaceAll('\u0670', 'ا'); // Superscript Alef → Alef

    return result;
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
