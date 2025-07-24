import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import 'package:wave_blob/wave_blob.dart';

class Tasbih extends StatefulWidget {
  const Tasbih({super.key});

  @override
  State<Tasbih> createState() => _TasbihState();
}

class _TasbihState extends State<Tasbih> with TickerProviderStateMixin {
  @override
  void initState() {
    context.read<TasbihCubit>().loadTasbih();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? context.darkCardBackground : Colors.white,
      appBar: AppBar(
        title: Text('Tasbih'),
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontFamily: 'Tajawal',
          color: isDark ? Colors.white : Colors.black,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? context.darkCardBackground : Colors.white,
      ),
      body: BlocBuilder<TasbihCubit, TasbihState>(
        builder: (context, state) {
          if (state is TasbihLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TasbihLoaded) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  // Top section with counter and note
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      child: Stack(
                        children: [
                          _buildCard(
                            height: double.infinity,
                            backgroundImage: DecorationImage(
                              image: AssetImage('assets/images/mosques.png'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  context.primaryColor, BlendMode.multiply),
                            ),
                            config: CustomConfig(
                              colors: [
                                context.primaryDarkColor,
                                context.primaryColor,
                                context.accentColor,
                                context.primaryLightColor,
                              ],
                              durations: [18000, 8000, 5000, 12000],
                              heightPercentages: [0.75, 0.76, 0.78, 0.80],
                            ),
                          ),
                          // Counter display
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
                                          color: Colors.black.withOpacity(0.7),
                                          offset: Offset(3.0, 3.0),
                                        ),
                                        Shadow(
                                          blurRadius: 5.0,
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(1.0, 1.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  // Note display
                                  if (state.note != null &&
                                      state.note!.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
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
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              offset: Offset(1.0, 1.0),
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
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Control buttons row
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Add Note Button
                        _buildControlButton(
                          icon: Icons.edit_note_rounded,
                          label: 'Note',
                          onPressed: () => _showNoteDialog(context),
                          color: context.accentColor,
                        ),

                        // Vibration Toggle Button
                        _buildControlButton(
                          icon: state.mode
                              ? Icons.vibration
                              : Icons.phone_android,
                          label: state.mode ? 'Vibrate' : 'Silent',
                          onPressed: () {
                            context.read<TasbihCubit>().changeMode(!state.mode);
                          },
                          color:
                              state.mode ? context.primaryColor : Colors.grey,
                          // isToggled: state.mode,
                        ),

                        // Reset Button
                        _buildControlButton(
                          icon: Icons.refresh_rounded,
                          label: 'Reset',
                          onPressed: () => _showResetDialog(context),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Add Button (keeping your design but slightly improved)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AddButton(onPressed: () {
                        context.read<TasbihCubit>().increment();
                      }),
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],
              ),
            );
          } else if (state is TasbihError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: onPressed,
              child: Icon(
                icon,
                color: color,
                size: 28.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: color,
            fontWeight: FontWeight.w500,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  void _showNoteDialog(BuildContext context) {
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
                  context.primaryColor.withOpacity(0.1),
                  context.accentColor.withOpacity(0.05),
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
                  'Edit Note',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: context.primaryColor,
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: tasbihCubit.noteController,
                  decoration: InputDecoration(
                    hintText: 'Enter your dhikr note...',
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
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text('Clear'),
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
                        child: Text('Save'),
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

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8.w),
            Text('Reset Counter'),
          ],
        ),
        content: Text('Are you sure you want to reset the counter to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel'),
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
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  _buildCard({
    required Config config,
    Color? backgroundColor = Colors.transparent,
    DecorationImage? backgroundImage,
    double? height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      child: Card(
        elevation: 16.0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.r)),
        ),
        child: WaveWidget(
          config: config,
          backgroundColor: backgroundColor,
          backgroundImage: backgroundImage,
          size: Size(double.infinity, double.infinity),
          waveAmplitude: 0,
        ),
      ),
    );
  }
}

class AddButton extends StatefulWidget {
  final void Function()? onPressed;
  const AddButton({super.key, required this.onPressed});

  @override
  State<AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<AddButton>
    with SingleTickerProviderStateMixin {
  bool autoScale = true;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      if (autoScale && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width *
          0.6, // Slightly smaller for better fit
      height: MediaQuery.sizeOf(context).width * 0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: WaveBlob(
        blobCount: 2,
        amplitude: 500.0,
        scale: 1,
        autoScale: autoScale,
        centerCircle: true,
        overCircle: true,
        circleColors: [
          context.primaryLightColor,
        ],
        colors: [
          context.primaryLightColor.withOpacity(0.4),
          context.accentColor.withOpacity(0.4),
        ],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 60.sp,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.3),
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
