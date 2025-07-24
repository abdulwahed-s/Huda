import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:wave_blob/wave_blob.dart';

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
      width: MediaQuery.sizeOf(context).width * 0.8,
      height: MediaQuery.sizeOf(context).width * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: WaveBlob(
        blobCount: 2,
        amplitude: 500.0,
        scale: 1,
        autoScale: autoScale,
        centerCircle: true,
        overCircle: true,
        circleColors: [
          context.primaryLightColor, // or any other suitable app color
        ],
        colors: [
          context.primaryLightColor.withOpacity(0.3),
          context.accentColor.withOpacity(0.3),
        ],
        child: IconButton(
          icon: const Icon(Icons.add),
          color: Colors.white,
          iconSize: 50.0,
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
