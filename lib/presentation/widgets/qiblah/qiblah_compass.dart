import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/qiblah/qiblah_service.dart';
import 'package:huda/presentation/widgets/qiblah/calibration_banner.dart';
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
  late final Stream<QiblahReading> _stream;

  @override
  void initState() {
    super.initState();
    _stream = QiblahService.qiblahStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahReading>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.hasHeading) {
          return LoadingState(isDark: widget.isDark);
        }

        final reading = snapshot.data!;
        final isAligned = reading.isAligned;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleAlignment(isAligned);
        });

        return Column(
          children: [
            SizedBox(height: 40.h),
            StatusIndicator(isAligned: isAligned, isDark: widget.isDark),
            CalibrationBanner(
              show: reading.shouldCalibrate,
              isDark: widget.isDark,
            ),
            SizedBox(height: 60.h),
            Expanded(
              child: Compass(
                reading: reading,
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

  void _handleAlignment(bool currentlyAligned) async {
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

    await _handleVibration(currentlyAligned);
  }

  Future<void> _handleVibration(bool aligned) async {
    if (aligned) {
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
