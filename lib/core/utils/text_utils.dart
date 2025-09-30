class TextUtils {
  static String removeDiacriticsAndNormalize(String input) {
    final diacriticRegex = RegExp(
        r'[\u064B-\u0652\u0653\u0654\u0655\u0670\u06D6-\u06ED\u0610-\u061A]');
    String result = input.replaceAll(diacriticRegex, '');

    // Normalize Arabic letters
    result = result.replaceAll('ٱ', 'ا'); // Alef Wasla → Alef
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');
    result = result.replaceAll('ى', 'ي'); // Alif Maqsura → Ya
    result = result.replaceAll('ة', 'ه'); // Ta marbuta → Ha

    return result;
  }
}
