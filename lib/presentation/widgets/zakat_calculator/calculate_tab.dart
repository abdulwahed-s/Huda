import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/zakat_calculator/asset_input.dart';
import 'package:huda/presentation/widgets/zakat_calculator/quick_summary_card.dart';
import 'package:huda/presentation/widgets/zakat_calculator/section_header.dart';

class CalculateTab extends StatelessWidget {
  final Map<AssetCategory, TextEditingController> controllers;
  final ZakatCalculatorLoaded state;
  final VoidCallback onResetAll;

  const CalculateTab({
    super.key,
    required this.controllers,
    required this.state,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppLocalizations.of(context)!.assets,
            icon: Icons.account_balance_wallet,
          ),

          // Cash and Bank Balances
          AssetInput(
            category: AssetCategory.cash,
            state: state,
            controller: controllers[AssetCategory.cash]!,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context
                  .read<ZakatCalculatorCubit>()
                  .updateAssetValue(AssetCategory.cash, amount);
            },
          ),
          SizedBox(height: 12.h),

          // Gold
          AssetInput(
            category: AssetCategory.gold,
            state: state,
            controller: controllers[AssetCategory.gold]!,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context
                  .read<ZakatCalculatorCubit>()
                  .updateAssetValue(AssetCategory.gold, amount);
            },
          ),
          SizedBox(height: 12.h),

          // Silver
          AssetInput(
            category: AssetCategory.silver,
            state: state,
            controller: controllers[AssetCategory.silver]!,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context
                  .read<ZakatCalculatorCubit>()
                  .updateAssetValue(AssetCategory.silver, amount);
            },
          ),
          SizedBox(height: 12.h),

          // Business Assets
          AssetInput(
            category: AssetCategory.business,
            state: state,
            controller: controllers[AssetCategory.business]!,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context
                  .read<ZakatCalculatorCubit>()
                  .updateAssetValue(AssetCategory.business, amount);
            },
          ),
          SizedBox(height: 12.h),

          // Investments
          AssetInput(
            category: AssetCategory.investments,
            state: state,
            controller: controllers[AssetCategory.investments]!,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context
                  .read<ZakatCalculatorCubit>()
                  .updateAssetValue(AssetCategory.investments, amount);
            },
          ),
          SizedBox(height: 12.h),

          // Receivables
          AssetInput(
            category: AssetCategory.receivables,
            state: state,
            controller: controllers[AssetCategory.receivables]!,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context
                  .read<ZakatCalculatorCubit>()
                  .updateAssetValue(AssetCategory.receivables, amount);
            },
          ),
          SizedBox(height: 24.h),

          SectionHeader(
            title: AppLocalizations.of(context)!.liabilities,
            icon: Icons.remove_circle_outline,
          ),

          // Debts
          AssetInput(
            category: AssetCategory.debts,
            state: state,
            controller: controllers[AssetCategory.debts]!,
            onChanged: (value) {
              final amount = double.tryParse(value) ?? 0.0;
              context
                  .read<ZakatCalculatorCubit>()
                  .updateAssetValue(AssetCategory.debts, amount);
            },
          ),
          SizedBox(height: 24.h),

          // Quick Summary Card
          QuickSummaryCard(state: state),
          SizedBox(height: 16.h),

          // Reset Button
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onResetAll,
                icon: Icon(Icons.refresh_rounded, size: 20.sp),
                label: Text(
                  AppLocalizations.of(context)!.resetAll,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Amiri",
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}