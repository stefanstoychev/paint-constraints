package paintcontraints.backend;

import java.util.Arrays;

public record Constraint(ColorComponents color, Operation operation, int[] indexes, int offset) {

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

        String offsetStr = offset == 0 ? "" : (offset > 0 ? " + " + offset : " - " + Math.abs(offset));

        return String.format("%s.%s %s %s.%s%s",
                sourceLabel, color, opSymbol, targetLabel, color, offsetStr);
    }
}
