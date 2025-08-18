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

  const ZakatCalculatorLoaded({
    required this.calculation,
    required this.selectedCurrency,
    required this.nisabType,
    required this.goldPricePerGram,
    required this.silverPricePerGram,
  });

  @override
  List<Object?> get props => [
        calculation,
        selectedCurrency,
        nisabType,
        goldPricePerGram,
        silverPricePerGram,
      ];

  ZakatCalculatorLoaded copyWith({
    ZakatCalculation? calculation,
    String? selectedCurrency,
    NisabType? nisabType,
    double? goldPricePerGram,
    double? silverPricePerGram,
  }) {
    return ZakatCalculatorLoaded(
      calculation: calculation ?? this.calculation,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      nisabType: nisabType ?? this.nisabType,
      goldPricePerGram: goldPricePerGram ?? this.goldPricePerGram,
      silverPricePerGram: silverPricePerGram ?? this.silverPricePerGram,
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
