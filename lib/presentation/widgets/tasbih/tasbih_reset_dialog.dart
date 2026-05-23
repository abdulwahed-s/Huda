import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

void showTasbihResetDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8.w),
          Text(AppLocalizations.of(context)!.resetCounter),
        ],
      ),
      content: Text(AppLocalizations.of(context)!.resetCounterConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<TasbihCubit>().reset();
            Navigator.of(dialogContext).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context)!.reset),
        ),
      ],
    ),
  );
}
