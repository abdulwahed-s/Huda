import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/zakat_calculator/section_header.dart';

class AssetBreakdown extends StatelessWidget {
  final ZakatCalculatorLoaded state;

  const AssetBreakdown({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final calculation = state.calculation;
    final cubit = context.read<ZakatCalculatorCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context)!.assetBreakdown,
          icon: Icons.pie_chart,
        ),
        ...AssetCategory.values.where((category) {
          return category != AssetCategory.debts &&
              (calculation.assets[category] ?? 0.0) > 0;
        }).map((category) {
          final amount = calculation.assets[category] ?? 0.0;
          final percentage = calculation.totalAssets > 0
              ? (amount / calculation.totalAssets * 100)
              : 0.0;

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: _getAssetColor(category).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: _getAssetColor(category),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLocalizedAssetCategoryName(category, context),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: "Amiri",
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                          fontFamily: "Amiri",
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  cubit.getFormattedAmount(amount),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: _getAssetColor(category),
                    fontFamily: "Amiri",
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getAssetColor(AssetCategory category) {
    switch (category) {
      case AssetCategory.cash:
        return Colors.green;
      case AssetCategory.gold:
        return Colors.amber;
      case AssetCategory.silver:
        return Colors.grey;
      case AssetCategory.business:
        return Colors.blue;
      case AssetCategory.investments:
        return Colors.purple;
      case AssetCategory.receivables:
        return Colors.teal;
      case AssetCategory.debts:
        return Colors.red;
    }
  }

  String _getLocalizedAssetCategoryName(
      AssetCategory category, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (category) {
      case AssetCategory.cash:
        return localizations.cashAndBankBalances;
      case AssetCategory.gold:
        return localizations.goldAssets;
      case AssetCategory.silver:
        return localizations.silverAssets;
      case AssetCategory.business:
        return localizations.businessAssets;
      case AssetCategory.investments:
        return localizations.investmentsAssets;
      case AssetCategory.receivables:
        return localizations.moneyOwedToYou;
      case AssetCategory.debts:
        return localizations.debtsAndLiabilities;
    }
  }
}
