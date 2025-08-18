import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:math' as math;

part 'zakat_calculator_state.dart';

class ZakatCalculatorCubit extends Cubit<ZakatCalculatorState> {
  static const double goldNisabGrams = 87.48;
  static const double silverNisabGrams = 612.36;

  final Map<AssetCategory, double> _assetValues = {
    AssetCategory.cash: 0.0,
    AssetCategory.gold: 0.0,
    AssetCategory.silver: 0.0,
    AssetCategory.business: 0.0,
    AssetCategory.investments: 0.0,
    AssetCategory.receivables: 0.0,
    AssetCategory.debts: 0.0,
  };

  double _goldPricePerGram = 65.0;
  double _silverPricePerGram = 0.85;
  String _selectedCurrency = 'USD';
  NisabType _nisabType = NisabType.gold;

  ZakatCalculatorCubit() : super(ZakatCalculatorInitial()) {
    _initialize();
  }

  void _initialize() {
    emit(ZakatCalculatorLoading());
    _calculateZakat();
  }

  void updateAssetValue(AssetCategory category, double value) {
    _assetValues[category] = value;
    _calculateZakat();
  }

  void updateGoldPrice(double pricePerGram) {
    _goldPricePerGram = pricePerGram;
    _calculateZakat();
  }

  void updateSilverPrice(double pricePerGram) {
    _silverPricePerGram = pricePerGram;
    _calculateZakat();
  }

  void changeCurrency(String currency) {
    _selectedCurrency = currency;

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

      emit(ZakatCalculatorLoaded(
        calculation: calculation,
        selectedCurrency: _selectedCurrency,
        nisabType: _nisabType,
        goldPricePerGram: _goldPricePerGram,
        silverPricePerGram: _silverPricePerGram,
      ));
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

  List<String> getSupportedCurrencies() {
    return ['USD', 'EUR', 'GBP', 'SAR', 'AED', 'QAR', 'KWD', 'BHD', 'EGP'];
  }
}
