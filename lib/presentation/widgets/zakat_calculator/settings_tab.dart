import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/zakat_calculator/dropdown_card.dart';
import 'package:huda/presentation/widgets/zakat_calculator/info_card.dart';
import 'package:huda/presentation/widgets/zakat_calculator/price_input.dart';
import 'package:huda/presentation/widgets/zakat_calculator/section_header.dart';
import 'package:huda/presentation/widgets/zakat_calculator/nisab_type_selector.dart';

class SettingsTab extends StatelessWidget {
  final ZakatCalculatorLoaded state;
  final TextEditingController goldPriceController;
  final TextEditingController silverPriceController;

  const SettingsTab({
    super.key,
    required this.state,
    required this.goldPriceController,
    required this.silverPriceController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppLocalizations.of(context)!.currencySettings,
            icon: Icons.attach_money,
          ),

          // Currency Selection
          DropdownCard(
            title: AppLocalizations.of(context)!.currency,
            value: state.selectedCurrency,
            items:
                context.read<ZakatCalculatorCubit>().getSupportedCurrencies(),
            onChanged: (value) =>
                context.read<ZakatCalculatorCubit>().changeCurrency(value!),
          ),

          SizedBox(height: 24.h),

          SectionHeader(
            title: AppLocalizations.of(context)!.nisabSettings,
            icon: Icons.balance,
          ),

          // Nisab Type Selection
          NisabTypeSelector(state: state),

          SizedBox(height: 24.h),

          SectionHeader(
            title: AppLocalizations.of(context)!.metalPrices,
            icon: Icons.monetization_on,
          ),

          // Gold Price
          PriceInput(
            title: AppLocalizations.of(context)!.goldPricePerGram,
            controller: goldPriceController,
            currency: state.selectedCurrency,
            onChanged: (value) => context
                .read<ZakatCalculatorCubit>()
                .updateGoldPrice(double.tryParse(value) ?? 0.0),
          ),
          SizedBox(height: 12.h),

          // Silver Price
          PriceInput(
            title: AppLocalizations.of(context)!.silverPricePerGram,
            controller: silverPriceController,
            currency: state.selectedCurrency,
            onChanged: (value) => context
                .read<ZakatCalculatorCubit>()
                .updateSilverPrice(double.tryParse(value) ?? 0.0),
          ),

          SizedBox(height: 24.h),

          // Info Cards
          InfoCard(
            title: AppLocalizations.of(context)!.whatIsNisab,
            content: AppLocalizations.of(context)!.nisabDescription,
          ),
        ],
      ),
    );
  }
}