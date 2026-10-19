class VertexRef {
  final int shapeIndex;
  final int vertexIndex;

  const VertexRef(this.shapeIndex, this.vertexIndex);

  VertexRef withVertexIndex(int vertexIndex) =>
      VertexRef(shapeIndex, vertexIndex);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VertexRef &&
        other.shapeIndex == shapeIndex &&
        other.vertexIndex == vertexIndex;
  }

  @override
  int get hashCode => Object.hash(shapeIndex, vertexIndex);

  @override
  String toString() => 'VertexRef($shapeIndex, $vertexIndex)';

  Map<String, dynamic> toJson() {
    return {'shapeIndex': shapeIndex, 'vertexIndex': vertexIndex};
  }

  factory VertexRef.fromJson(Map<String, dynamic> json) {
    return VertexRef(json['shapeIndex'] as int, json['vertexIndex'] as int);
  }
}

/// Two vertices that must always share the same position. Unordered.
class VertexLink {
  final VertexRef a;
  final VertexRef b;

  const VertexLink(this.a, this.b);

  bool contains(VertexRef v) => a == v || b == v;

  VertexRef other(VertexRef v) => a == v ? b : a;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VertexLink &&
        ((other.a == a && other.b == b) || (other.a == b && other.b == a));
  }

  @override
  int get hashCode => a.hashCode ^ b.hashCode;

  Map<String, dynamic> toJson() {
    return {'a': a.toJson(), 'b': b.toJson()};
  }

  factory VertexLink.fromJson(Map<String, dynamic> json) {
    return VertexLink(
      VertexRef.fromJson(json['a'] as Map<String, dynamic>),
      VertexRef.fromJson(json['b'] as Map<String, dynamic>),
    );
  }
}
