import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class NisabTypeSelector extends StatelessWidget {
  final ZakatCalculatorLoaded state;

  const NisabTypeSelector({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.nisabCalculationBasedOn,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              fontFamily: "Amiri",
            ),
          ),
          SizedBox(height: 12.h),
          RadioGroup<NisabType>(
            groupValue: state.nisabType,
            onChanged: (value) {
              context.read<ZakatCalculatorCubit>().changeNisabType(value!);
            },
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<NisabType>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      AppLocalizations.of(context)!.gold,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: "Amiri",
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.goldGrams,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontFamily: "Amiri",
                      ),
                    ),
                    value: NisabType.gold,
                  ),
                ),
                Expanded(
                  child: RadioListTile<NisabType>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      AppLocalizations.of(context)!.silver,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: "Amiri",
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.silverGrams,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontFamily: "Amiri",
                      ),
                    ),
                    value: NisabType.silver,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
