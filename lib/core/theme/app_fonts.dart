class AppFonts {
  AppFonts._();

  static const String system = 'system';
  static const String amiri = 'Amiri';
  static const String tajawal = 'Tajawal';

  static const List<String> selectable = [amiri, tajawal, system];

  static String? resolve(String fontFamily) =>
      fontFamily == system ? null : fontFamily;
}

