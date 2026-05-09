enum ComparisonOperator {
  lt('<'),
  e('=');

  const ComparisonOperator(this.symbol);

  final String symbol;

  @override
  String toString() => symbol;
}
