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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 500;

    return Positioned(
      bottom: isSmallScreen ? 10 : 20,
      left: isSmallScreen ? 10 : 20,
      child: Card(
        color: Colors.black54,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 4 : 12,
            vertical: isSmallScreen ? 2 : 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                iconSize: isSmallScreen ? 20 : 24,
                icon: const Icon(Icons.zoom_out, color: Colors.white),
                onPressed: () => onZoomChanged(currentScale - 0.2),
                tooltip: 'Zoom Out',
              ),
              SizedBox(
                width: isSmallScreen ? 80 : 150,
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
                iconSize: isSmallScreen ? 20 : 24,
                icon: const Icon(Icons.zoom_in, color: Colors.white),
                onPressed: () => onZoomChanged(currentScale + 0.2),
                tooltip: 'Zoom In',
              ),
              IconButton(
                iconSize: isSmallScreen ? 20 : 24,
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
