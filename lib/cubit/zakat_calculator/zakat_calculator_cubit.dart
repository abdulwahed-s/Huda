import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/data/api/metal_price_service.dart';
import 'package:huda/data/zakat/zakat_currencies.dart';
import 'package:huda/data/zakat/zakat_price_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'zakat_calculator_state.dart';

class ZakatCalculatorCubit extends Cubit<ZakatCalculatorState> {
  static const double goldNisabGrams = 87.48;
  static const double silverNisabGrams = 612.36;

  // Saved between visits: the currency, the last market prices, and a
  // price the person typed (until they choose the market price again or
  // change currency).
  static const _currencyKey = 'zakat_currency';
  static const _marketKey = 'zakat_market_prices_v1';
  static const _goldManualKey = 'zakat_gold_price_manual';
  static const _silverManualKey = 'zakat_silver_price_manual';

  final Map<AssetCategory, double> _assetValues = {
    AssetCategory.cash: 0.0,
    AssetCategory.gold: 0.0,
    AssetCategory.silver: 0.0,
    AssetCategory.business: 0.0,
    AssetCategory.investments: 0.0,
    AssetCategory.receivables: 0.0,
    AssetCategory.debts: 0.0,
  };

  final MetalPriceSource _priceSource;

  /// The newest prices known: saved from the last update, or the snapshot
  /// Huda ships with.
  MetalPrices _market = zakatPriceSnapshot;

  double _goldPricePerGram = 0;
  double _silverPricePerGram = 0;
  bool _goldManual = false;
  bool _silverManual = false;
  String _selectedCurrency = ZakatCurrencies.fallback;
  NisabType _nisabType = NisabType.gold;
  ZakatPriceStatus _priceStatus = ZakatPriceStatus.current;

  /// [priceSource] defaults to the keyless currency-api feed; [locales]
  /// (the device's) pick the first currency when none was saved. With
  /// [fetchPrices] false the prices stay as saved (tests, previews).
  ZakatCalculatorCubit({
    MetalPriceSource? priceSource,
    List<Locale>? locales,
    bool fetchPrices = true,
  }) : _priceSource = priceSource ?? CurrencyApiMetalPriceSource(),
       super(ZakatCalculatorInitial()) {
    _initialize(locales ?? PlatformDispatcher.instance.locales, fetchPrices);
  }

  void _initialize(List<Locale> locales, bool fetchPrices) {
    emit(ZakatCalculatorLoading());
    final prefs = _prefs;
    final saved = prefs?.getString(_currencyKey);
    _selectedCurrency = saved != null && ZakatCurrencies.supports(saved)
        ? saved
        : ZakatCurrencies.forLocales(locales);
    final cached = MetalPrices.fromJson(_decode(prefs?.getString(_marketKey)));
    if (cached != null && !cached.date.isBefore(_market.date)) {
      _market = cached;
    }
    final goldManual = prefs?.getDouble(_goldManualKey);
    final silverManual = prefs?.getDouble(_silverManualKey);
    _goldManual = goldManual != null;
    _silverManual = silverManual != null;
    _applyMarket();
    if (goldManual != null) _goldPricePerGram = goldManual;
    if (silverManual != null) _silverPricePerGram = silverManual;
    if (fetchPrices) {
      _priceStatus = ZakatPriceStatus.updating;
      _calculateZakat();
      _fetchPrices();
    } else {
      _calculateZakat();
    }
  }

  SharedPreferences? get _prefs {
    try {
      return CacheHelper.sharedPreferences;
    } catch (_) {
      return null;
    }
  }

  static Object? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Market prices for the current currency, except a typed one.
  void _applyMarket() {
    if (!_goldManual) {
      _goldPricePerGram =
          _market.goldPerGram(_selectedCurrency) ?? _goldPricePerGram;
    }
    if (!_silverManual) {
      _silverPricePerGram =
          _market.silverPerGram(_selectedCurrency) ?? _silverPricePerGram;
    }
  }

  Future<void> _fetchPrices() async {
    try {
      final prices = await _priceSource.fetch();
      if (isClosed) return;
      _market = prices;
      _prefs?.setString(_marketKey, jsonEncode(prices.toJson()));
      _priceStatus = ZakatPriceStatus.current;
      _applyMarket();
    } catch (_) {
      if (isClosed) return;
      _priceStatus = ZakatPriceStatus.failed;
    }
    _calculateZakat();
  }

  /// Fetches the market prices again after a failure (the person tapped
  /// Retry): "retrying" until it ends.
  Future<void> retryPrices() async {
    if (_priceStatus == ZakatPriceStatus.updating ||
        _priceStatus == ZakatPriceStatus.retrying) {
      return;
    }
    _priceStatus = ZakatPriceStatus.retrying;
    _calculateZakat();
    await _fetchPrices();
  }

  void updateAssetValue(AssetCategory category, double value) {
    _assetValues[category] = value;
    _calculateZakat();
  }

  /// A price the person typed: it's kept (and saved) instead of the
  /// market price until [useMarketPrice] or a currency change.
  void updateGoldPrice(double pricePerGram) {
    _goldPricePerGram = pricePerGram;
    _goldManual = true;
    _prefs?.setDouble(_goldManualKey, pricePerGram);
    _calculateZakat();
  }

  void updateSilverPrice(double pricePerGram) {
    _silverPricePerGram = pricePerGram;
    _silverManual = true;
    _prefs?.setDouble(_silverManualKey, pricePerGram);
    _calculateZakat();
  }

  /// Back to the market price for [metal].
  void useMarketPrice(NisabType metal) {
    if (metal == NisabType.gold) {
      _goldManual = false;
      _prefs?.remove(_goldManualKey);
    } else {
      _silverManual = false;
      _prefs?.remove(_silverManualKey);
    }
    _applyMarket();
    _calculateZakat();
  }

  /// Amounts are in this currency, and the market prices follow it. A
  /// typed price was in the old currency, so it goes back to the market.
  void changeCurrency(String currency) {
    if (currency == _selectedCurrency) return;
    _selectedCurrency = currency;
    _prefs?.setString(_currencyKey, currency);
    _goldManual = false;
    _silverManual = false;
    _prefs?.remove(_goldManualKey);
    _prefs?.remove(_silverManualKey);
    _applyMarket();
    _calculateZakat();
  }

  void changeNisabType(NisabType type) {
    _nisabType = type;
    _calculateZakat();
  }

  void resetCalculation() {
    _assetValues.updateAll((key, value) => 0.0);
    _calculateZakat();
  }

  void _calculateZakat() {
    try {
      double totalAssets = 0.0;
      _assetValues.forEach((category, value) {
        if (category != AssetCategory.debts) {
          totalAssets += value;
        }
      });

      double totalDebts = _assetValues[AssetCategory.debts] ?? 0.0;

      double netAssets = math.max(0.0, totalAssets - totalDebts);

      double nisabValue;
      if (_nisabType == NisabType.gold) {
        nisabValue = goldNisabGrams * _goldPricePerGram;
      } else {
        nisabValue = silverNisabGrams * _silverPricePerGram;
      }

      bool isZakatDue = netAssets >= nisabValue;

      double zakatAmount = isZakatDue ? netAssets * 0.025 : 0.0;

      final calculation = ZakatCalculation(
        assets: Map.from(_assetValues),
        totalAssets: totalAssets,
        totalDebts: totalDebts,
        netAssets: netAssets,
        nisabValue: nisabValue,
        isZakatDue: isZakatDue,
        zakatAmount: zakatAmount,
      );

      emit(
        ZakatCalculatorLoaded(
          calculation: calculation,
          selectedCurrency: _selectedCurrency,
          nisabType: _nisabType,
          goldPricePerGram: _goldPricePerGram,
          silverPricePerGram: _silverPricePerGram,
          priceStatus: _priceStatus,
          priceDate: _market.date,
          goldIsManual: _goldManual,
          silverIsManual: _silverManual,
        ),
      );
    } catch (error) {
      emit(ZakatCalculatorError(message: error.toString()));
    }
  }

  String getFormattedAmount(double amount) {
    return '$_selectedCurrency ${amount.toStringAsFixed(2)}';
  }

  String getAssetCategoryName(AssetCategory category) {
    switch (category) {
      case AssetCategory.cash:
        return 'Cash & Bank Balances';
      case AssetCategory.gold:
        return 'Gold';
      case AssetCategory.silver:
        return 'Silver';
      case AssetCategory.business:
        return 'Business Assets';
      case AssetCategory.investments:
        return 'Investments';
      case AssetCategory.receivables:
        return 'Money Owed to You';
      case AssetCategory.debts:
        return 'Debts & Liabilities';
    }
  }

  String getAssetCategoryDescription(AssetCategory category) {
    switch (category) {
      case AssetCategory.cash:
        return 'Savings accounts, checking accounts, cash on hand, digital wallets';
      case AssetCategory.gold:
        return 'Value of gold jewelry, coins, and bars (market value)';
      case AssetCategory.silver:
        return 'Value of silver jewelry, coins, and bars (market value)';
      case AssetCategory.business:
        return 'Inventory, business cash, profits held in business';
      case AssetCategory.investments:
        return 'Stocks, bonds, mutual funds, retirement accounts (if zakatable)';
      case AssetCategory.receivables:
        return 'Money owed to you that you expect to receive';
      case AssetCategory.debts:
        return 'Credit card debts, loans, bills due within the year';
    }
  }

  double getAssetValue(AssetCategory category) {
    return _assetValues[category] ?? 0.0;
  }

  List<String> getSupportedCurrencies() => ZakatCurrencies.all;
}
