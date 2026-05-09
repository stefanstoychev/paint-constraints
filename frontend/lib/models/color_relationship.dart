import 'color_component.dart';
import 'comparison_operator.dart';

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
