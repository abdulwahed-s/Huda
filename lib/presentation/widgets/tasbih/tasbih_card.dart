import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class TasbihCard extends StatelessWidget {
  final Config config;
  final Color? backgroundColor;
  final DecorationImage? backgroundImage;
  final double? height;

  const TasbihCard({
    super.key,
    required this.config,
    this.backgroundColor = Colors.transparent,
    this.backgroundImage,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          size: const Size(double.infinity, double.infinity),
          waveAmplitude: 0,
        ),
      ),
    );
  }
}
