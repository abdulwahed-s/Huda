import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/settings/preset_button.dart';
import 'package:huda/presentation/widgets/settings/reset_button.dart';

class PresetButtonsAndReset extends StatelessWidget {
  const PresetButtonsAndReset({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = context.watch<ThemeCubit>().state.textScaleFactor;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 10.w,
            runSpacing: 8.h,
            children: [
              PresetButton(
                value: 0.8,
                label: l10n.small,
                isSelected: scale == 0.8,
              ),
              PresetButton(
                value: 1.0,
                label: l10n.normal,
                isSelected: scale == 1.0,
              ),
              PresetButton(
                value: 1.3,
                label: l10n.large,
                isSelected: scale == 1.3,
              ),
              PresetButton(
                value: 1.6,
                label: l10n.extraLarge,
                isSelected: scale == 1.6,
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        ResetButton(scale: scale),
      ],
    );
  }
}

