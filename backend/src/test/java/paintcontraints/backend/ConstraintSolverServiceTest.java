package paintcontraints.backend;

import org.junit.jupiter.api.Test;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class ConstraintSolverServiceTest {

    private final ConstraintSolverService solverService = new ConstraintSolverService();

    @Test
    void testSimpleEquality() {
        // Target H = Source H + 10
        Constraint constraint = new Constraint(
                ColorComponents.H,
                Operation.E,
                new int[]{0, 1},
                10
        );
        SolveRequest request = new SolveRequest(List.of(constraint).toArray(Constraint[]::new));

        List<Result> results = solverService.solve(request);
        
        assertNotNull(results);
        Result r0 = results.stream().filter(r -> r.index() == 0).findFirst().orElseThrow();
        Result r1 = results.stream().filter(r -> r.index() == 1).findFirst().orElseThrow();
        
        assertEquals(r0.h() + 10, r1.h());
    }

    @Test
    void testGreaterThanWithOffset() {
        // Target S > Source S + 50
        Constraint constraint = new Constraint(
                ColorComponents.S,
                Operation.GT,
                new int[]{0, 1},
                50
        );
        SolveRequest request = new SolveRequest(List.of(constraint).toArray(Constraint[]::new));

        List<Result> results = solverService.solve(request);
        
        assertNotNull(results);
        Result r0 = results.stream().filter(r -> r.index() == 0).findFirst().orElseThrow();
        Result r1 = results.stream().filter(r -> r.index() == 1).findFirst().orElseThrow();
        
        assertTrue(r1.s() > r0.s() + 50);
    }

    @Test
    void testMultipleConstraints() {
        // Shape 1.H = Shape 0.H + 20
        // Shape 2.H = Shape 1.H + 20
        Constraint c1 = new Constraint(ColorComponents.H, Operation.E, new int[]{0, 1}, 20);
        Constraint c2 = new Constraint(ColorComponents.H, Operation.E, new int[]{1, 2}, 20);
        SolveRequest request = new SolveRequest(List.of(c1, c2).toArray(Constraint[]::new));

        List<Result> results = solverService.solve(request);
        
        assertNotNull(results);
        Result r0 = results.stream().filter(r -> r.index() == 0).findFirst().orElseThrow();
        Result r1 = results.stream().filter(r -> r.index() == 1).findFirst().orElseThrow();
        Result r2 = results.stream().filter(r -> r.index() == 2).findFirst().orElseThrow();
        
        assertEquals(r0.h() + 20, r1.h());
        assertEquals(r1.h() + 20, r2.h());
    }

    @Test
    void testInfeasibleConstraint() {
        // H = 10 AND H = 20
        Constraint c1 = new Constraint(ColorComponents.H, Operation.E, new int[]{0, 1}, 10);
        Constraint c2 = new Constraint(ColorComponents.H, Operation.E, new int[]{0, 1}, 20);
        SolveRequest request = new SolveRequest(List.of(c1, c2).toArray(Constraint[]::new));

        List<Result> results = solverService.solve(request);
        
        assertNull(results);
    }
}
