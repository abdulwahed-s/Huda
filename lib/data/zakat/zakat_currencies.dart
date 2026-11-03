import 'dart:ui';

import 'package:huda/data/zakat/zakat_currency_data.dart';

/// The zakat calculator's currencies: which exist, what they're called in
/// the app's language, which one a device starts with, and which to
/// suggest first.
abstract final class ZakatCurrencies {
  static const String fallback = 'USD';

  /// Currencies whose world rate can be far from the local gold market
  /// (a redenomination, an official rate beside a market one). The ledger
  /// asks people to check their local price.
  static const Set<String> unsteady = {
    'SYP',
    'SDG',
    'LBP',
    'EGP',
    'ARS',
    'VES',
    'YER',
  };

  static List<String> get all => zakatCurrencyCodes;

  static bool supports(String code) => zakatCurrencyCodes.contains(code);

  /// The currency's name in [languageCode] (CLDR), or English, or the code.
  static String name(String code, String languageCode) =>
      zakatCurrencyNames[languageCode]?[code] ??
      zakatCurrencyNames['en']?[code] ??
      code;

  /// The currency of the first device locale whose region has one we
  /// offer, by region rather than language (Arabic alone spans 18).
  static String forLocales(List<Locale> locales) {
    for (final locale in locales) {
      final region = locale.countryCode?.toUpperCase();
      final code = region == null ? null : zakatRegionCurrency[region];
      if (code != null) return code;
    }
    return fallback;
  }

  /// A short list to start from: the current one, the device region's,
  /// then the app language's most usual currencies, at most [limit].
  static List<String> suggested({
    required String current,
    required String languageCode,
    String? region,
    int limit = 5,
  }) {
    final list = <String>[current];
    void add(String? code) {
      if (code != null && supports(code) && !list.contains(code)) {
        list.add(code);
      }
    }

    add(region == null ? null : zakatRegionCurrency[region.toUpperCase()]);
    for (final code in zakatLanguageCurrencies[languageCode] ?? const []) {
      if (list.length >= limit) break;
      add(code);
    }
    return list;
  }
}
