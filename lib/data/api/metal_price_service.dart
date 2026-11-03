import 'dart:convert';

import 'package:http/http.dart' as http;

/// Grams in a troy ounce, the unit gold and silver are quoted in.
const double gramsPerTroyOunce = 31.1034768;

/// Gold and silver market prices in every currency the feed has, per troy
/// ounce, keyed by lower-case ISO code, and the day they're from.
class MetalPrices {
  const MetalPrices({
    required this.date,
    required this.gold,
    required this.silver,
  });

  final DateTime date;
  final Map<String, double> gold;
  final Map<String, double> silver;

  double? goldPerGram(String currency) =>
      _perGram(gold[currency.toLowerCase()]);

  double? silverPerGram(String currency) =>
      _perGram(silver[currency.toLowerCase()]);

  static double? _perGram(double? ounce) =>
      ounce == null || ounce <= 0 ? null : ounce / gramsPerTroyOunce;

  Map<String, Object> toJson() => {
    'date': date.toIso8601String(),
    'gold': gold,
    'silver': silver,
  };

  static MetalPrices? fromJson(Object? json) {
    if (json is! Map) return null;
    final date = DateTime.tryParse('${json['date']}');
    final gold = _rates(json['gold']);
    final silver = _rates(json['silver']);
    if (date == null || gold.isEmpty || silver.isEmpty) return null;
    return MetalPrices(date: date, gold: gold, silver: silver);
  }

  static Map<String, double> _rates(Object? raw) => {
    if (raw is Map)
      for (final entry in raw.entries)
        if (entry.value is num && (entry.value as num) > 0)
          '${entry.key}'.toLowerCase(): (entry.value as num).toDouble(),
  };
}

/// Where the zakat calculator gets gold and silver prices.
abstract class MetalPriceSource {
  Future<MetalPrices> fetch();
}

/// The open, keyless fawazahmed0/currency-api: static files updated daily
/// on two CDNs (jsDelivr, then its Cloudflare mirror), so it has no quota
/// to share between users and no key to ship in the app. Each file gives
/// one unit (here a troy ounce of gold, `xau`, or silver, `xag`) in every
/// currency.
class CurrencyApiMetalPriceSource implements MetalPriceSource {
  CurrencyApiMetalPriceSource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _hosts = [
    'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies',
    'https://latest.currency-api.pages.dev/v1/currencies',
  ];

  static const _timeout = Duration(seconds: 12);

  @override
  Future<MetalPrices> fetch() async {
    Object? lastError;
    for (final host in _hosts) {
      try {
        final results = await Future.wait([
          _get('$host/xau.min.json', 'xau'),
          _get('$host/xag.min.json', 'xag'),
        ]);
        final (goldDate, gold) = results[0];
        final (silverDate, silver) = results[1];
        // The older of the two days, so the date never overstates.
        final date = goldDate.isBefore(silverDate) ? goldDate : silverDate;
        return MetalPrices(date: date, gold: gold, silver: silver);
      } catch (error) {
        lastError = error;
      }
    }
    throw MetalPriceException('$lastError');
  }

  Future<(DateTime, Map<String, double>)> _get(String url, String unit) async {
    final response = await _client.get(Uri.parse(url)).timeout(_timeout);
    if (response.statusCode != 200) {
      throw MetalPriceException('HTTP ${response.statusCode} for $unit');
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map) throw MetalPriceException('Bad $unit payload');
    final date = DateTime.tryParse('${json['date']}');
    final rates = MetalPrices._rates(json[unit]);
    if (date == null || rates.isEmpty) {
      throw MetalPriceException('Bad $unit payload');
    }
    return (date, rates);
  }
}

class MetalPriceException implements Exception {
  MetalPriceException(this.message);

  final String message;

  @override
  String toString() => 'MetalPriceException: $message';
}
