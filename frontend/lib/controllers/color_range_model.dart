import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/color_constraint_models.dart';

class ColorRangeModel extends ChangeNotifier {
  ColorRangeModel();

  factory ColorRangeModel.fromCanvasController(CanvasController controller) {
    final model = ColorRangeModel();
    if (controller.selectedIndices.isNotEmpty) {
      final index = controller.selectedIndices.first;
      for (final element in controller.constraints.activeShapeColorConstraint) {
        if (element.sourceShapeIndex == index) {
          final minValue = element.min as double?;
          final maxValue = element.max as double?;
          if (minValue != null && maxValue != null) {
            model.setRange(
              element.component,
              minValue,
              maxValue,
              notify: false,
            );
          }
        }
      }
    }
    return model;
  }
  double _hueStart = 0, _hueEnd = 360;
  double _valueStart = 0, _valueEnd = 60;
  double _saturationStart = 0, _saturationEnd = 60;

  double get hueStart => _hueStart;
  double get hueEnd => _hueEnd;

  double get valueStart => _valueStart;
  double get valueEnd => _valueEnd;

  double get saturationStart => _saturationStart;
  double get saturationEnd => _saturationEnd;

  /// Sets the range for a color component with optional listener notification.
  ///
  /// When [notify] is true (default), listeners are notified of the change.
  /// When false, the change is applied silently (useful for batch updates).
  void setRange(
    ColorComponent component,
    double start,
    double end, {
    bool notify = true,
  }) {
    switch (component) {
      case ColorComponent.hue:
        _hueStart = start;
        _hueEnd = end;
        break;
      case ColorComponent.saturation:
        _saturationStart = start;
        _saturationEnd = end;
        break;
      case ColorComponent.value:
        _valueStart = start;
        _valueEnd = end;
        break;
    }
    if (notify) notifyListeners();
  }

  /// Convenience method to set hue range.
  /// Use [setRange] for programmatic flexibility.
  void updateHue(double start, double end) {
    setRange(ColorComponent.hue, start, end);
  }

  /// Convenience method to set saturation range.
  /// Use [setRange] for programmatic flexibility.
  void updateSaturation(double start, double end) {
    setRange(ColorComponent.saturation, start, end);
  }

  /// Convenience method to set value range.
  /// Use [setRange] for programmatic flexibility.
  void updateValue(double start, double end) {
    setRange(ColorComponent.value, start, end);
  }

  /// Legacy methods for backward compatibility.
  /// Deprecated: Use [setRange] or specific update methods instead.
  @Deprecated('Use setRange() instead')
  void setHue(double start, double end) {
    setRange(ColorComponent.hue, start, end, notify: false);
  }

  @Deprecated('Use setRange() instead')
  void setSaturation(double start, double end) {
    setRange(ColorComponent.saturation, start, end, notify: false);
  }

  @Deprecated('Use setRange() instead')
  void setValue(double start, double end) {
    setRange(ColorComponent.value, start, end, notify: false);
  }
}
