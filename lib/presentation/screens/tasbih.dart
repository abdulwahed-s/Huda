import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/tasbih/add_button.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_card.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_controls_row.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_dialog.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_reset_dialog.dart';

class Tasbih extends StatelessWidget {
  const Tasbih({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? context.darkCardBackground : Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tasbih),
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          color: isDark ? Colors.white : Colors.black,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? context.darkCardBackground : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: BlocBuilder<TasbihCubit, TasbihState>(
        builder: (context, state) {
          if (state is TasbihLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TasbihLoaded) {
            return _TasbihBody(state: state);
          }
          if (state is TasbihError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TasbihBody extends StatelessWidget {
  final TasbihLoaded state;

  const _TasbihBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TasbihCubit>();
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final card = TasbihCard(
          notes: state.notes,
          selectedNoteIndex: state.selectedNoteIndex,
          currentCount: state.currentCount,
          onNoteSelected: cubit.selectNote,
        );
        final controls = TasbihControlsRow(
          isVibrationMode: state.mode,
          onDhikrTap: () => showTasbihDhikrDialog(context),
          onVibrationToggle: () => cubit.changeMode(!state.mode),
          onDecrement: cubit.decrement,
          onReset: () => showTasbihResetDialog(context),
        );

        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: isLandscape
              ? Row(
                  children: [
                    Expanded(flex: 1, child: card),
                    SizedBox(width: 20.w),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          controls,
                          SizedBox(height: 20.h),
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                height: MediaQuery.of(context).size.width / 3,
                                width: MediaQuery.of(context).size.width / 3,
                                child: const AddButton(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 3, child: card),
                    SizedBox(height: 20.h),
                    controls,
                    SizedBox(height: 20.h),
                    const Expanded(flex: 2, child: Center(child: AddButton())),
                    SizedBox(height: 20.h),
                  ],
                ),
        );
      },
    );
  }
}
