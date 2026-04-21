package paintcontraints.backend;

public record Constraint(ColorComponents color, Operation operation, int[] indexes, double offset) {
}
