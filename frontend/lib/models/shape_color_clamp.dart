import 'color_component.dart';
import 'color_relationship.dart';
import 'comparison_operator.dart';

class ShapeColorConstraint {
  final int sourceShapeIndex;
  final ColorComponent component;

  final int max;
  final int min;

  const ShapeColorConstraint(
      this.sourceShapeIndex,
      this.component,
      this.min,
      this.max
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShapeColorConstraint &&
        other.sourceShapeIndex == sourceShapeIndex &&
        other.component == component;
  }

  @override
  int get hashCode =>
      Object.hash(sourceShapeIndex, component);

  Map<String, dynamic> toJson() {
    return {
      'sourceShapeIndex': sourceShapeIndex,
      'component': component.name,
      'max': max,
      'min': min
    };
  }

  factory ShapeColorConstraint.fromJson(Map<String, dynamic> json) {
    final component = ColorComponent.values.firstWhere(
          (e) => e.name == json['component'],
    );

    return ShapeColorConstraint(
      json['sourceShapeIndex'] as int,
      component,
      json['min'] as int,
      json['max'] as int
    );
  }
}