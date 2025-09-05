import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfFloatingButtons extends StatelessWidget {
  final Animation<double> fabAnimation;
  final VoidCallback addRedMarker;
  final VoidCallback addGreenMarker;
  final VoidCallback addOrangeMarker;
  final PdfViewerController pdfViewerController;
  final ColorScheme colorScheme;
  final bool isHorizontalLayout;

  const PdfFloatingButtons({
    super.key,
    required this.fabAnimation,
    required this.addRedMarker,
    required this.addGreenMarker,
    required this.addOrangeMarker,
    required this.pdfViewerController,
    required this.colorScheme,
    required this.isHorizontalLayout,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: fabAnimation.value,
                child: Opacity(
                  opacity: fabAnimation.value,
                  child: Column(
                    children: [
                      _buildMarkerFab(Colors.red, addRedMarker),
                      const SizedBox(height: 8),
                      _buildMarkerFab(Colors.green, addGreenMarker),
                      const SizedBox(height: 8),
                      _buildMarkerFab(Colors.orange, addOrangeMarker),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: "zoom_out",
                onPressed: () {
                  if (pdfViewerController.isReady) {
                    pdfViewerController.zoomDown();
                  }
                },
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                child: const Icon(Icons.zoom_out),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: "zoom_in",
                onPressed: () {
                  if (pdfViewerController.isReady) {
                    pdfViewerController.zoomUp();
                  }
                },
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                child: const Icon(Icons.zoom_in),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerFab(Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 40,
      height: 40,
      child: FloatingActionButton(
        heroTag: "marker_${color.toARGB32()}",
        onPressed: onPressed,
        backgroundColor: color,
        mini: true,
        child:
            const Icon(Icons.format_color_fill, color: Colors.white, size: 16),
      ),
    );
  }
}