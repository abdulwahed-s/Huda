part of 'zakat_calculator_cubit.dart';

sealed class ZakatCalculatorState extends Equatable {
  const ZakatCalculatorState();

  @override
  List<Object?> get props => [];
}

final class ZakatCalculatorInitial extends ZakatCalculatorState {}

final class ZakatCalculatorLoading extends ZakatCalculatorState {}

final class ZakatCalculatorLoaded extends ZakatCalculatorState {
  final ZakatCalculation calculation;
  final String selectedCurrency;
  final NisabType nisabType;
  final double goldPricePerGram;
  final double silverPricePerGram;

  /// Whether the market prices are current, updating, or failed to update
  /// (then [priceDate] says how old they are).
  final ZakatPriceStatus priceStatus;

  /// The day the market prices are from.
  final DateTime? priceDate;

  /// A price the person typed instead of the market price.
  final bool goldIsManual;
  final bool silverIsManual;

  const ZakatCalculatorLoaded({
    required this.calculation,
    required this.selectedCurrency,
    required this.nisabType,
    required this.goldPricePerGram,
    required this.silverPricePerGram,
    this.priceStatus = ZakatPriceStatus.current,
    this.priceDate,
    this.goldIsManual = false,
    this.silverIsManual = false,
  });

  /// Whether the price the nisab is weighed with was typed.
  bool get nisabPriceIsManual =>
      nisabType == NisabType.gold ? goldIsManual : silverIsManual;

  @override
  List<Object?> get props => [
    calculation,
    selectedCurrency,
    nisabType,
    goldPricePerGram,
    silverPricePerGram,
    priceStatus,
    priceDate,
    goldIsManual,
    silverIsManual,
  ];

  ZakatCalculatorLoaded copyWith({
    ZakatCalculation? calculation,
    String? selectedCurrency,
    NisabType? nisabType,
    double? goldPricePerGram,
    double? silverPricePerGram,
    ZakatPriceStatus? priceStatus,
    DateTime? priceDate,
    bool? goldIsManual,
    bool? silverIsManual,
  }) {
    return ZakatCalculatorLoaded(
      calculation: calculation ?? this.calculation,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      nisabType: nisabType ?? this.nisabType,
      goldPricePerGram: goldPricePerGram ?? this.goldPricePerGram,
      silverPricePerGram: silverPricePerGram ?? this.silverPricePerGram,
      priceStatus: priceStatus ?? this.priceStatus,
      priceDate: priceDate ?? this.priceDate,
      goldIsManual: goldIsManual ?? this.goldIsManual,
      silverIsManual: silverIsManual ?? this.silverIsManual,
    );
  }
}

final class ZakatCalculatorError extends ZakatCalculatorState {
  final String message;

  const ZakatCalculatorError({required this.message});

  @override
  List<Object?> get props => [message];
}

enum NisabType { gold, silver }

/// The market prices: [current] after an update this visit; [updating]
/// while the automatic update runs; [failed] when it didn't (the prices
/// shown are the last ones known); [retrying] after the person taps Retry.
enum ZakatPriceStatus { current, updating, failed, retrying }

enum AssetCategory {
  cash,
  gold,
  silver,
  business,
  investments,
  receivables,
  debts,
}

class ZakatCalculation {
  final Map<AssetCategory, double> assets;
  final double totalAssets;
  final double totalDebts;
  final double netAssets;
  final double nisabValue;
  final bool isZakatDue;
  final double zakatAmount;
  final double zakatRate;

  const ZakatCalculation({
    required this.assets,
    required this.totalAssets,
    required this.totalDebts,
    required this.netAssets,
    required this.nisabValue,
    required this.isZakatDue,
    required this.zakatAmount,
    this.zakatRate = 0.025,
  });

  ZakatCalculation copyWith({
    Map<AssetCategory, double>? assets,
    double? totalAssets,
    double? totalDebts,
    double? netAssets,
    double? nisabValue,
    bool? isZakatDue,
    double? zakatAmount,
    double? zakatRate,
  }) {
    return ZakatCalculation(
      assets: assets ?? this.assets,
      totalAssets: totalAssets ?? this.totalAssets,
      totalDebts: totalDebts ?? this.totalDebts,
      netAssets: netAssets ?? this.netAssets,
      nisabValue: nisabValue ?? this.nisabValue,
      isZakatDue: isZakatDue ?? this.isZakatDue,
      zakatAmount: zakatAmount ?? this.zakatAmount,
      zakatRate: zakatRate ?? this.zakatRate,
    );
  }
}
