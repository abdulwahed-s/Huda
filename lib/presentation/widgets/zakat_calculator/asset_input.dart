import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class AssetInput extends StatelessWidget {
  final AssetCategory category;
  final ZakatCalculatorLoaded state;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const AssetInput({
    super.key,
    required this.category,
    required this.state,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getAssetColor(category).withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getAssetColor(category).withValues(alpha: 0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
            spreadRadius: 2.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: _getAssetColor(category).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  _getAssetIcon(category),
                  color: _getAssetColor(category),
                  size: 22.sp,
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
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontFamily: "Amiri",
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _getLocalizedAssetCategoryDescription(category, context),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                        fontFamily: "Amiri",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: "Amiri",
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.hintAmount,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15.sp,
                fontFamily: "Amiri",
              ),
              prefixIcon: Container(
                margin: EdgeInsets.only(left: 12.w, right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getAssetColor(category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  state.selectedCurrency,
                  style: TextStyle(
                    color: _getAssetColor(category),
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    fontFamily: "Amiri",
                  ),
                ),
              ),
              filled: true,
              fillColor: _getAssetColor(category).withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: _getAssetColor(category).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: _getAssetColor(category),
                  width: 2.5,
                ),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _getAssetIcon(AssetCategory category) {
    switch (category) {
      case AssetCategory.cash:
        return Icons.account_balance_wallet;
      case AssetCategory.gold:
        return Icons.star;
      case AssetCategory.silver:
        return Icons.stars;
      case AssetCategory.business:
        return Icons.business;
      case AssetCategory.investments:
        return Icons.trending_up;
      case AssetCategory.receivables:
        return Icons.call_received;
      case AssetCategory.debts:
        return Icons.remove_circle_outline;
    }
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

  String _getLocalizedAssetCategoryDescription(
      AssetCategory category, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (category) {
      case AssetCategory.cash:
        return localizations.cashDescription;
      case AssetCategory.gold:
        return localizations.goldDescription;
      case AssetCategory.silver:
        return localizations.silverDescription;
      case AssetCategory.business:
        return localizations.businessDescription;
      case AssetCategory.investments:
        return localizations.investmentsDescription;
      case AssetCategory.receivables:
        return localizations.receivablesDescription;
      case AssetCategory.debts:
        return localizations.debtsDescription;
    }
  }
}

