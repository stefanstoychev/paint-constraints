import 'color_component.dart';
import 'comparison_operator.dart';

/// Defines a comparative relationship between two HSV color components.
/// For example: target.hue < source.hue + 10.0
/// This class only defines the relationship - the actual implementation is handled elsewhere.
class ColorRelationship {
  final ColorComponent component;
  final ComparisonOperator operator;
  final double offset;

  const ColorRelationship(this.component, this.operator, [this.offset = 0.0]);

  @override
  String toString() {
    final offsetStr = offset == 0
        ? ''
        : (offset > 0 ? ' + $offset' : ' - ${offset.abs()}');
    return '${component.name} ${operator.symbol}$offsetStr';
  }

  /// Get a human-readable description of this relationship
  String getDescription() {
    final componentName = component.name;
    final opSymbol = operator.symbol;
    final offsetStr = offset == 0
        ? ''
        : (offset > 0 ? ' + ${offset.toStringAsFixed(1)}' : ' - ${offset.abs().toStringAsFixed(1)}');

    return 'Target $componentName $opSymbol Source $componentName$offsetStr';
  }
}