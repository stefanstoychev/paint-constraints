import 'package:flutter/material.dart';

class ZoomControls extends StatelessWidget {
  final double currentScale;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onZoomReset;

  const ZoomControls({
    super.key,
    required this.currentScale,
    required this.onZoomChanged,
    required this.onZoomReset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Card(
        color: Colors.black54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.zoom_out, color: Colors.white),
                onPressed: () => onZoomChanged(currentScale - 0.2),
                tooltip: 'Zoom Out',
              ),
              SizedBox(
                width: 150,
                child: Slider(
                  value: currentScale,
                  min: 0.3,
                  max: 5.0,
                  divisions: ((5.0 - 0.3) * 10).round(),
                  onChanged: onZoomChanged,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: Colors.white),
                onPressed: () => onZoomChanged(currentScale + 0.2),
                tooltip: 'Zoom In',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: onZoomReset,
                tooltip: 'Reset Zoom',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
