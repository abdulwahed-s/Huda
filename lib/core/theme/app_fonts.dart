class AppFonts {
  AppFonts._();

  static const String system = 'system';
  static const String amiri = 'Amiri';

  static const List<String> selectable = [amiri, system];

  static String? resolve(String fontFamily) =>
      fontFamily == system ? null : fontFamily;

  static String sanitize(String fontFamily) =>
      selectable.contains(fontFamily) ? fontFamily : amiri;
}

