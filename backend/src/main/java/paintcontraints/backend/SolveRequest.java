package paintcontraints.backend;

public record SolveRequest(Relationship[] relationships, ColorConstraint[] constraints) {
}
