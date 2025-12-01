import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/tasbih/add_button.dart';
import 'package:huda/presentation/widgets/tasbih/control_button.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_card.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_funactions.dart';
import 'package:wave/config.dart';

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
          fontFamily: 'Tajawal',
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
          } else if (state is TasbihLoaded) {
            return OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: isLandscape
                      ? Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildTasbihCard(context, state),
                            ),
                            SizedBox(width: 20.w),
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildControls(context, state),
                                  SizedBox(height: 20.h),
                                  Expanded(
                                    child: Center(
                                      child: _buildAddButton(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTasbihCard(context, state),
                            ),
                            SizedBox(height: 20.h),
                            _buildControls(context, state),
                            SizedBox(height: 20.h),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: _buildAddButton(context),
                              ),
                            ),
                            SizedBox(height: 20.h),
                          ],
                        ),
                );
              },
            );
          } else if (state is TasbihError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTasbihCard(BuildContext context, TasbihLoaded state) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          TasbihCard(
            height: double.infinity,
            backgroundImage: DecorationImage(
              image: const AssetImage('assets/images/mosques.png'),
              fit: BoxFit.cover,
              colorFilter:
                  ColorFilter.mode(context.primaryColor, BlendMode.multiply),
            ),
            config: CustomConfig(
              colors: [
                context.primaryDarkColor,
                context.primaryColor,
                context.accentColor,
                context.primaryLightColor,
              ],
              durations: [25000, 15000, 12000, 20000],
              heightPercentages: [0.75, 0.76, 0.78, 0.80],
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.count.toString(),
                    style: TextStyle(
                      fontSize: 64.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 15.0,
                          color: Colors.black.withValues(alpha: 0.7),
                          offset: const Offset(3.0, 3.0),
                        ),
                        Shadow(
                          blurRadius: 5.0,
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (state.note != null && state.note!.isNotEmpty)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        state.note!,
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              blurRadius: 8.0,
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, TasbihLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ControlButton(
            icon: Icons.edit_note_rounded,
            label: AppLocalizations.of(context)!.note,
            onPressed: () => showNoteDialog(context),
            color: context.accentColor,
          ),
          ControlButton(
            icon: state.mode ? Icons.vibration : Icons.phone_android,
            label: state.mode
                ? AppLocalizations.of(context)!.vibrate
                : AppLocalizations.of(context)!.silent,
            onPressed: () {
              context.read<TasbihCubit>().changeMode(!state.mode);
            },
            color: state.mode ? context.primaryColor : Colors.grey,
          ),
          ControlButton(
            icon: Icons.refresh_rounded,
            label: AppLocalizations.of(context)!.reset,
            onPressed: () => showResetDialog(context),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return AddButton(onPressed: () {
      context.read<TasbihCubit>().increment();
    });
  }
}
