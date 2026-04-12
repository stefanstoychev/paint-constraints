enum ComparisonOperator {
  lessThan('<'),
  greaterThan('>'),
  equal('='),
  lessThanOrEqual('<='),
  greaterThanOrEqual('>='),
  notEqual('!=');

  const ComparisonOperator(this.symbol);

  final String symbol;

  @override
  String toString() => symbol;
}