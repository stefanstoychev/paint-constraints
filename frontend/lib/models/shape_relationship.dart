import 'color_component.dart';
import 'color_relationship.dart';
import 'comparison_operator.dart';

class ShapeRelationship {
  final int sourceShapeIndex;
  final int targetShapeIndex;
  final ColorRelationship relationship;

  const ShapeRelationship(
      this.sourceShapeIndex,
      this.targetShapeIndex,
      this.relationship,
      );

  bool hasSameType(ShapeRelationship other) {
    return other.sourceShapeIndex == sourceShapeIndex &&
        other.targetShapeIndex == targetShapeIndex &&
        other.relationship.component == relationship.component;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShapeRelationship &&
        other.sourceShapeIndex == sourceShapeIndex &&
        other.targetShapeIndex == targetShapeIndex &&
        other.relationship == relationship;
  }

  @override
  int get hashCode =>
      Object.hash(sourceShapeIndex, targetShapeIndex, relationship);

  Map<String, dynamic> toJson() {
    return {
      'sourceShapeIndex': sourceShapeIndex,
      'targetShapeIndex': targetShapeIndex,
      'component': relationship.component.name,
      'operator': relationship.operator.name
    };
  }

  factory ShapeRelationship.fromJson(Map<String, dynamic> json) {
    final component = ColorComponent.values.firstWhere(
          (e) => e.name == json['component'],
    );
    final operator = ComparisonOperator.values.firstWhere(
          (e) => e.name == json['operator'],
    );
    final relationship = ColorRelationship(
        component,
        operator
    );
    return ShapeRelationship(
      json['sourceShapeIndex'] as int,
      json['targetShapeIndex'] as int,
      relationship,
    );
  }
}