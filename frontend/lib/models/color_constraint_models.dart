enum ColorComponent { hue, saturation, value }

enum ComparisonOperator {
  lt('<'),
  e('=');

  const ComparisonOperator(this.symbol);

  final String symbol;

  @override
  String toString() => symbol;
}

class ColorRelationship {
  final ColorComponent component;
  final ComparisonOperator operator;

  const ColorRelationship(this.component, this.operator);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorRelationship &&
        other.component == component &&
        other.operator == operator;
  }

  @override
  int get hashCode => Object.hash(component, operator);
}

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
      'operator': relationship.operator.name,
    };
  }

  factory ShapeRelationship.fromJson(Map<String, dynamic> json) {
    final component = ColorComponent.values.firstWhere(
      (e) => e.name == json['component'],
    );
    final operator = ComparisonOperator.values.firstWhere(
      (e) => e.name == json['operator'],
    );
    final relationship = ColorRelationship(component, operator);
    return ShapeRelationship(
      json['sourceShapeIndex'] as int,
      json['targetShapeIndex'] as int,
      relationship,
    );
  }
}

class ShapeColorConstraint {
  final int sourceShapeIndex;
  final ColorComponent component;

  final int max;
  final int min;

  const ShapeColorConstraint(
    this.sourceShapeIndex,
    this.component,
    this.min,
    this.max,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShapeColorConstraint &&
        other.sourceShapeIndex == sourceShapeIndex &&
        other.component == component;
  }

  @override
  int get hashCode => Object.hash(sourceShapeIndex, component);

  Map<String, dynamic> toJson() {
    return {
      'sourceShapeIndex': sourceShapeIndex,
      'component': component.name,
      'max': max,
      'min': min,
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
      json['max'] as int,
    );
  }
}
