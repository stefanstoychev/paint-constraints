import 'package:flutter/material.dart';

class ZoomControls extends StatefulWidget {
  final double currentScale;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onZoomReset;
  final VoidCallback onFitToScreen;

  const ZoomControls({
    super.key,
    required this.currentScale,
    required this.onZoomChanged,
    required this.onZoomReset,
    required this.onFitToScreen,
  });

  @override
  State<ZoomControls> createState() => _ZoomControlsState();
}

class _ZoomControlsState extends State<ZoomControls> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 500;

    return Positioned(
      bottom: isSmallScreen ? 10 : 20,
      left: isSmallScreen ? 10 : 20,
      child: Card(
        elevation: 4,
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: widget.onFitToScreen,
                tooltip: 'Fit to Screen',
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.zoom_in : Icons.search,
                  color: _isExpanded ? Colors.blueAccent : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                tooltip: _isExpanded ? 'Hide Zoom Controls' : 'Show Zoom Controls',
              ),
              if (_isExpanded) ...[
                const SizedBox(
                  height: 24,
                  child: VerticalDivider(color: Colors.white24, width: 16),
                ),
                IconButton(
                  iconSize: isSmallScreen ? 20 : 24,
                  icon: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () => widget.onZoomChanged(widget.currentScale - 0.2),
                  tooltip: 'Zoom Out',
                ),
                SizedBox(
                  width: isSmallScreen ? 80 : 120,
                  child: Slider(
                    value: widget.currentScale,
                    min: 0.3,
                    max: 5.0,
                    divisions: ((5.0 - 0.3) * 10).round(),
                    onChanged: widget.onZoomChanged,
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.white24,
                  ),
                ),
                IconButton(
                  iconSize: isSmallScreen ? 20 : 24,
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => widget.onZoomChanged(widget.currentScale + 0.2),
                  tooltip: 'Zoom In',
                ),
                IconButton(
                  iconSize: isSmallScreen ? 20 : 24,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: widget.onZoomReset,
                  tooltip: 'Reset Zoom',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
