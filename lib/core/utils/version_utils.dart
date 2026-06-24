class VersionUtils {
  static bool isNewer(String a, String b) {
    final aParts = _parse(a);
    final bParts = _parse(b);
    final maxLen =
        aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < maxLen; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av > bv) return true;
      if (av < bv) return false;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final core = version.split(RegExp(r'[+\-\s]')).first;
    return core.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  }
}
