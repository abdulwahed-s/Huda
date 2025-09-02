import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/presentation/widgets/qiblah/compass.dart';
import 'package:huda/presentation/widgets/qiblah/instructions.dart';
import 'package:huda/presentation/widgets/qiblah/loading_state.dart';
import 'package:huda/presentation/widgets/qiblah/status_indicator.dart';
import 'package:vibration/vibration.dart';

class QiblahCompass extends StatefulWidget {
  final bool isDark;
  final AnimationController pulseController;
  final AnimationController rotationController;
  final Animation<double> pulseAnimation;
  final Animation<double> scaleAnimation;
  final bool isAligned;
  final bool hasVibrated;
  final ValueChanged<bool> onAlignmentChanged;
  final ValueChanged<bool> onVibrationChanged;

  const QiblahCompass({
    super.key,
    required this.isDark,
    required this.pulseController,
    required this.rotationController,
    required this.pulseAnimation,
    required this.scaleAnimation,
    required this.isAligned,
    required this.hasVibrated,
    required this.onAlignmentChanged,
    required this.onVibrationChanged,
  });

  @override
  State<QiblahCompass> createState() => QiblahCompassState();
}

class QiblahCompassState extends State<QiblahCompass> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingState(isDark: widget.isDark);
        }

        final qiblahDirection = snapshot.data!;
        double angle = ((qiblahDirection.qiblah) * (math.pi / 180) * -1);
        bool isAligned = angle >= -6.35 && angle <= -6.1;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleAlignment(angle, isAligned);
        });

        return Column(
          children: [
            SizedBox(height: 40.h),
            StatusIndicator(isAligned: isAligned, isDark: widget.isDark),
            SizedBox(height: 60.h),
            Expanded(
              child: Compass(
                qiblahDirection: qiblahDirection,
                angle: angle,
                isAligned: isAligned,
                isDark: widget.isDark,
                pulseAnimation: widget.pulseAnimation,
                scaleAnimation: widget.scaleAnimation,
              ),
            ),
            Instructions(isAligned: isAligned, isDark: widget.isDark),
            SizedBox(height: 40.h),
          ],
        );
      },
    );
  }

  void _handleAlignment(double angle, bool currentlyAligned) async {
    if (currentlyAligned != widget.isAligned) {
      widget.onAlignmentChanged(currentlyAligned);

      if (currentlyAligned) {
        widget.pulseController.repeat();
        widget.rotationController
            .forward()
            .then((_) => widget.rotationController.reverse());
      } else {
        widget.pulseController.stop();
      }
    }

    await _handleVibration(angle);
  }

  Future<void> _handleVibration(double angle) async {
    if ((angle >= -6.35 && angle <= -6.1)) {
      if (!widget.hasVibrated) {
        if (await Vibration.hasVibrator()) {
          if (await Vibration.hasCustomVibrationsSupport()) {
            if (await Vibration.hasAmplitudeControl()) {
              Vibration.vibrate(duration: 200, amplitude: 128);
            } else {
              Vibration.vibrate(duration: 200);
            }
          } else {
            Vibration.vibrate();
          }
        }
        widget.onVibrationChanged(true);
      }
    } else {
      if (widget.hasVibrated) {
        widget.onVibrationChanged(false);
      }
    }
  }
}
