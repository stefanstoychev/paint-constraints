import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/canvas_controller.dart';

class ZoomControls extends StatefulWidget {
  const ZoomControls({super.key});

  @override
  State<ZoomControls> createState() => _ZoomControlsState();
}

class _ZoomControlsState extends State<ZoomControls> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final CanvasController controller = context.watch<CanvasController>();

    return Card(
      elevation: 4,
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.fit_screen, color: Colors.white),
              onPressed: () => controller.fitToScreen(context),
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
              tooltip: _isExpanded
                  ? 'Hide Zoom Controls'
                  : 'Show Zoom Controls',
            ),
            if (_isExpanded) ...[
              const SizedBox(
                height: 24,
                child: VerticalDivider(color: Colors.white24, width: 16),
              ),
              IconButton(
                iconSize: 24,
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () => controller.updateZoomScale(
                  controller.currentScale - 0.2,
                  MediaQuery.of(context).size,
                ),
                tooltip: 'Zoom Out',
              ),
              SizedBox(
                width: 120,
                child: Slider(
                  value: controller.currentScale,
                  min: 0.3,
                  max: 5.0,
                  divisions: ((5.0 - 0.3) * 10).round(),
                  onChanged: (v) =>
                      () => controller.updateZoomScale(
                        v,
                        MediaQuery.of(context).size,
                      ),
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white24,
                ),
              ),
              IconButton(
                iconSize: 24,
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => controller.updateZoomScale(
                  controller.currentScale + 0.2,
                  MediaQuery.of(context).size,
                ),
                tooltip: 'Zoom In',
              ),
              IconButton(
                iconSize: 24,
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.resetZoomScale,
                tooltip: 'Reset Zoom',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
