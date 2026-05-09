package paintcontraints.backend;

public record Relationship(ColorComponents color, Operation operation, int[] indexes) {

    public String toString(long source, long target) {
        String sourceLabel = "" + source;
        String targetLabel = "" + target;

        String opSymbol = switch (operation) {
            case E -> "==";
            case NE -> "!=";
            case GT -> ">";
            case GTE -> ">=";
            case LT -> "<";
            case LTE -> "<=";
        };


        return String.format("%s.%s %s %s.%s",
                sourceLabel, color, opSymbol, targetLabel, color);
    }
}
