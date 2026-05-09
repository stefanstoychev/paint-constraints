package paintcontraints.backend;

// ColorComponents color, Operation operation, int[] indexes
public record ColorConstraint(ColorComponents component,
                              int index,
                              int max,
                              int min) {
}
