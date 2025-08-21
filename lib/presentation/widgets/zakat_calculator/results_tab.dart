import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/zakat_calculator/asset_breakdown.dart';
import 'package:huda/presentation/widgets/zakat_calculator/result_card.dart';

class ResultsTab extends StatelessWidget {
  final ZakatCalculatorLoaded state;

  const ResultsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final calculation = state.calculation;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zakat Due Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: calculation.isZakatDue
                    ? [
                        context.primaryColor,
                        context.primaryColor.withValues(alpha: 0.8),
                        context.primaryColor.withValues(alpha: 0.9),
                      ]
                    : [
                        Colors.grey[400]!,
                        Colors.grey[500]!,
                        Colors.grey[600]!,
                      ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: calculation.isZakatDue
                      ? context.primaryColor.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.3),
                  blurRadius: 20.r,
                  offset: Offset(0, 8.h),
                  spreadRadius: 2.r,
                ),
                BoxShadow(
                  color: calculation.isZakatDue
                      ? context.primaryColor.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 40.r,
                  offset: Offset(0, 16.h),
                  spreadRadius: 4.r,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    calculation.isZakatDue
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 36.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  calculation.isZakatDue
                      ? AppLocalizations.of(context)!.zakatIsDue
                      : AppLocalizations.of(context)!.noZakatDue,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Amiri",
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    context
                        .read<ZakatCalculatorCubit>()
                        .getFormattedAmount(calculation.zakatAmount),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Amiri",
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Detailed Breakdown
          ResultCard(
            title: AppLocalizations.of(context)!.totalAssets,
            amount: calculation.totalAssets,
            icon: Icons.trending_up,
            color: Colors.green,
            state: state,
          ),
          SizedBox(height: 12.h),

          ResultCard(
            title: AppLocalizations.of(context)!.totalDebts,
            amount: calculation.totalDebts,
            icon: Icons.trending_down,
            color: Colors.red,
            state: state,
          ),
          SizedBox(height: 12.h),

          ResultCard(
            title: AppLocalizations.of(context)!.netAssets,
            amount: calculation.netAssets,
            icon: Icons.account_balance,
            color: context.primaryColor,
            state: state,
          ),
          SizedBox(height: 12.h),

          ResultCard(
            title: AppLocalizations.of(context)!
                .nisabThreshold(state.nisabType.name.toUpperCase()),
            amount: calculation.nisabValue,
            icon: Icons.insights,
            color: Colors.orange,
            state: state,
          ),
          SizedBox(height: 24.h),

          // Asset Breakdown
          AssetBreakdown(state: state),
        ],
      ),
    );
  }
}