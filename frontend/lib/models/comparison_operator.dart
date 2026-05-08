enum ComparisonOperator {
  lessThan('<'),
  equal('=');

  const ComparisonOperator(this.symbol);

  final String symbol;

  @override
  String toString() => symbol;
}
