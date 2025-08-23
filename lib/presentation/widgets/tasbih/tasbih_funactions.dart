import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

void showNoteDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final tasbihCubit = context.read<TasbihCubit>();
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.primaryColor.withValues(alpha: 0.1),
                context.accentColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 48.sp,
                color: context.primaryColor,
              ),
              SizedBox(height: 16.h),
              Text(
                AppLocalizations.of(context)!.editNote,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: context.primaryColor,
                  fontFamily: 'Amiri',
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: tasbihCubit.noteController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.enterNotesHint,
                  hintStyle: const TextStyle(
                    fontFamily: 'Amiri',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        BorderSide(color: context.primaryColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                maxLines: 3,
                minLines: 1,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        tasbihCubit.clearNote();
                        Navigator.of(dialogContext).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.clear),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        tasbihCubit.setNote();
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context)!.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showResetDialog(BuildContext context) {
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
