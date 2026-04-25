import 'package:flutter/material.dart';
import 'color_component.dart';
import 'color_relationship.dart';
import 'comparison_operator.dart';

/// Minimum and maximum values for hue (0-360 degrees)
final int minHue = 0;
final int maxHue= 360;

/// Minimum and maximum values for saturation (0-100)
final int minSaturation = 0;
final int maxSaturation = 100;

/// Minimum and maximum values for value/brightness (0-100)
final int minValue = 0;
final int maxValue = 100;

/// Whether hue should wrap around (true) or be clamped (false)
final bool hueWraps = true;

/// A class that defines constraints for HSV color components and relationships between colors.
/// This allows for configurable limits on hue, saturation, and value ranges, plus color relationships.
class ColorConstraints {

  /// Predefined color relationships
  final List<ColorRelationship> relationships;

  const ColorConstraints({
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
        ColorRelationship(
          ColorComponent.hue,
          ComparisonOperator.lessThan,
          -30.0,
        ), // Less than source - 30°
        ColorRelationship(ColorComponent.hue, ComparisonOperator.equal),
        ColorRelationship(
          ColorComponent.hue,
          ComparisonOperator.greaterThan,
          30.0,
        ), // Greater than source + 30°
        ColorRelationship(ColorComponent.hue, ComparisonOperator.greaterThan),

        // Saturation relationships
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.lessThan,
        ),
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.lessThan,
          -10.0,
        ), // Less than source - 10%
        ColorRelationship(ColorComponent.saturation, ComparisonOperator.equal),
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.greaterThan,
          10.0,
        ), // Greater than source + 10%
        ColorRelationship(
          ColorComponent.saturation,
          ComparisonOperator.greaterThan,
        ),

        // Value relationships
        ColorRelationship(ColorComponent.value, ComparisonOperator.lessThan),
        ColorRelationship(
          ColorComponent.value,
          ComparisonOperator.lessThan,
          -10.0,
        ), // Less than source - 10%
        ColorRelationship(ColorComponent.value, ComparisonOperator.equal),
        ColorRelationship(
          ColorComponent.value,
          ComparisonOperator.greaterThan,
          10.0,
        ), // Greater than source + 10%
        ColorRelationship(ColorComponent.value, ComparisonOperator.greaterThan),
      ],
    );
  }

  /// Apply constraints to a hue value
  int constrainHue(int hue) {
    if (hueWraps) {
      // Wrap around like angles
      int normalizedHue = hue % 360;
      if (normalizedHue < 0) normalizedHue += 360;
      return normalizedHue;
    } else {
      // Clamp to range
      return hue.clamp(minHue, maxHue);
    }
  }

  /// Apply constraints to a saturation value
  int constrainSaturation(int saturation) {
    return saturation.clamp(minSaturation, maxSaturation);
  }

  /// Apply constraints to a value/brightness value
  int constrainValue(int value) {
    return value.clamp(minValue, maxValue);
  }

  /// Apply constraints to an HSVColor
  HSVColor constrainColor(HSVColor color) {
    return HSVColor.fromAHSV(
      1.0,
      constrainHue(color.hue.toInt()).toDouble(),
      constrainSaturation(color.saturation.toInt()).toDouble(),
      constrainValue(color.value.toInt()).toDouble(),
    );
  }


  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  int get hashCode {
    return this.relationships.hashCode;
  }
}
