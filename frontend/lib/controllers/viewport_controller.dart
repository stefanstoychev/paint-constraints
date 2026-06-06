import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ViewportController extends ChangeNotifier {
  double currentScale = 1.0;
  Offset currentOffset = Offset.zero;

  double _previousScale = 1.0;
  Offset _previousOffset = Offset.zero;
  Offset _previousFocalPoint = Offset.zero;

  Offset screenToWorld(Offset screenPoint) {
    return (screenPoint - currentOffset) / currentScale;
  }

  Offset clampPoint(Offset point, Rect canvasRect) {
    return Offset(
      point.dx.clamp(canvasRect.left, canvasRect.right),
      point.dy.clamp(canvasRect.top, canvasRect.bottom),
    );
  }

  void updateZoomScale(double newScale, Size screenSize) {
    currentScale = newScale.clamp(0.3, 5.0);
    final Offset screenCenter = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );
    final Offset centerWorldAtPrevScale =
        (screenCenter - _previousOffset) / _previousScale;
    currentOffset = screenCenter - centerWorldAtPrevScale * currentScale;
    _previousScale = currentScale;
    _previousOffset = currentOffset;
    _previousFocalPoint = screenCenter;
    notifyListeners();
  }

  void resetZoomScale() {
    currentScale = 1.0;
    currentOffset = Offset.zero;
    _previousScale = 1.0;
    _previousOffset = Offset.zero;
    _previousFocalPoint = Offset.zero;
    notifyListeners();
  }

  void handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double zoomDelta = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      final double newScale = (currentScale * zoomDelta).clamp(0.3, 5.0);

      if (newScale != currentScale) {
        final Offset localFocalPoint = event.localPosition;
        final Offset focalPointWorld =
            (localFocalPoint - currentOffset) / currentScale;

        currentScale = newScale;
        currentOffset = localFocalPoint - focalPointWorld * currentScale;

        _previousScale = currentScale;
        _previousOffset = currentOffset;
        _previousFocalPoint = localFocalPoint;

        notifyListeners();
      }
    }
  }

  void fitToScreen(Rect canvasRect, Size screenSize) {
    // Subtract kToolbarHeight if this is representing the full screen height
    double availableHeight = screenSize.height - kToolbarHeight;
    double availableWidth = screenSize.width;

    final double scaleX = availableWidth / canvasRect.width;
    final double scaleY = availableHeight / canvasRect.height;

    currentScale = math.min(scaleX, scaleY).clamp(0.3, 5.0);

    final double centeredX =
        (availableWidth - canvasRect.width * currentScale) / 2 -
        canvasRect.left * currentScale;
    final double centeredY =
        (availableHeight - canvasRect.height * currentScale) / 2 -
        canvasRect.top * currentScale;

    currentOffset = Offset(centeredX, centeredY);

    _previousScale = currentScale;
    _previousOffset = currentOffset;
    notifyListeners();
  }

  // Viewport gesture state preparation/updates called by parent controller
  void prepareScaleStart(Offset localFocalPoint) {
    _previousScale = currentScale;
    _previousOffset = currentOffset;
    _previousFocalPoint = localFocalPoint;
  }

  void applyScaleUpdate(ScaleUpdateDetails details) {
    final Offset localFocalPoint = details.localFocalPoint;
    currentScale = (_previousScale * details.scale).clamp(0.3, 5.0);

    final Offset focalPointAtStartWorld =
        (_previousFocalPoint - _previousOffset) / _previousScale;
    currentOffset = localFocalPoint - focalPointAtStartWorld * currentScale;
    notifyListeners();
  }

  void finishScale() {
    _previousScale = currentScale;
    _previousOffset = currentOffset;
    notifyListeners();
  }
}
