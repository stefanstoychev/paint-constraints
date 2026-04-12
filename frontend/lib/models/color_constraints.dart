import 'package:flutter/material.dart';
import 'color_component.dart';
import 'color_relationship.dart';
import 'comparison_operator.dart';

/// A class that defines constraints for HSV color components and relationships between colors.
/// This allows for configurable limits on hue, saturation, and value ranges, plus color relationships.
class ColorConstraints {
  /// Minimum and maximum values for hue (0-360 degrees)
  final double minHue;
  final double maxHue;

  /// Minimum and maximum values for saturation (0.0-1.0)
  final double minSaturation;
  final double maxSaturation;

  /// Minimum and maximum values for value/brightness (0.0-1.0)
  final double minValue;
  final double maxValue;

  /// Whether hue should wrap around (true) or be clamped (false)
  final bool hueWraps;

  /// Predefined color relationships
  final List<ColorRelationship> relationships;

  const ColorConstraints({
    this.minHue = 0.0,
    this.maxHue = 360.0,
    this.minSaturation = 0.0,
    this.maxSaturation = 1.0,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.hueWraps = true,
    this.relationships = const [],
  });

  /// Default constraints matching HSV color space limits
  factory ColorConstraints.defaultConstraints() {
    return const ColorConstraints();
  }

  /// Create constraints with common comparative color relationships
  factory ColorConstraints.withCommonRelationships() {
    return const ColorConstraints(
      relationships: [
        // Hue relationships
        ColorRelationship(ColorComponent.hue, ComparisonOperator.lessThan),
        ColorRelationship(ColorComponent.hue, ComparisonOperator.greaterThan),
        ColorRelationship(ColorComponent.hue, ComparisonOperator.equal),
        ColorRelationship(
          ColorComponent.hue,
          ComparisonOperator.lessThan,
          30.0,
        ), // Less than source + 30°
        ColorRelationship(
          ColorComponent.hue,
          ComparisonOperator.greaterThan,
          30.0,
        ), // Greater than source + 30°
        // Saturation relationships
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.lessThan,
        ),
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.greaterThan,
        ),
        ColorRelationship(ColorComponent.saturation, ComparisonOperator.equal),
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.lessThan,
          0.1,
        ), // Less than source + 0.1
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.greaterThan,
          0.1,
        ), // Greater than source + 0.1
        // Value relationships
        ColorRelationship(ColorComponent.value, ComparisonOperator.lessThan),
        ColorRelationship(ColorComponent.value, ComparisonOperator.greaterThan),
        ColorRelationship(ColorComponent.value, ComparisonOperator.equal),
        ColorRelationship(
          ColorComponent.value,
          ComparisonOperator.lessThan,
          0.1,
        ), // Less than source + 0.1
        ColorRelationship(
          ColorComponent.value,
          ComparisonOperator.greaterThan,
          0.1,
        ), // Greater than source + 0.1
      ],
    );
  }

  /// Apply constraints to a hue value
  double constrainHue(double hue) {
    if (hueWraps) {
      // Wrap around like angles
      double normalizedHue = hue % 360.0;
      if (normalizedHue < 0) normalizedHue += 360.0;
      return normalizedHue;
    } else {
      // Clamp to range
      return hue.clamp(minHue, maxHue);
    }
  }

  /// Apply constraints to a saturation value
  double constrainSaturation(double saturation) {
    return saturation.clamp(minSaturation, maxSaturation);
  }

  /// Apply constraints to a value/brightness value
  double constrainValue(double value) {
    return value.clamp(minValue, maxValue);
  }

  /// Apply constraints to an HSVColor
  HSVColor constrainColor(HSVColor color) {
    return HSVColor.fromAHSV(
      1.0,
      constrainHue(color.hue),
      constrainSaturation(color.saturation),
      constrainValue(color.value),
    );
  }

  /// Create a new HSVColor by applying an offset to a component while respecting constraints
  HSVColor applyOffset(
    HSVColor color,
    ColorComponent component,
    double offset,
  ) {
    switch (component) {
      case ColorComponent.hue:
        return color.withHue(constrainHue(color.hue + offset));
      case ColorComponent.saturation:
        return color.withSaturation(
          constrainSaturation(color.saturation + offset),
        );
      case ColorComponent.value:
        return color.withValue(constrainValue(color.value + offset));
    }
  }

  /// Check if a value is within the constraints for a given component
  bool isWithinConstraints(ColorComponent component, double value) {
    switch (component) {
      case ColorComponent.hue:
        return hueWraps || (value >= minHue && value <= maxHue);
      case ColorComponent.saturation:
        return value >= minSaturation && value <= maxSaturation;
      case ColorComponent.value:
        return value >= minValue && value <= maxValue;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorConstraints &&
        other.minHue == minHue &&
        other.maxHue == maxHue &&
        other.minSaturation == minSaturation &&
        other.maxSaturation == maxSaturation &&
        other.minValue == minValue &&
        other.maxValue == maxValue &&
        other.hueWraps == hueWraps;
  }

  @override
  int get hashCode {
    return Object.hash(
      minHue,
      maxHue,
      minSaturation,
      maxSaturation,
      minValue,
      maxValue,
      hueWraps,
    );
  }

  @override
  String toString() {
    return 'ColorConstraints(hue: $minHue-$maxHue${hueWraps ? "(wraps)" : ""}, '
        'saturation: $minSaturation-$maxSaturation, value: $minValue-$maxValue)';
  }
}
