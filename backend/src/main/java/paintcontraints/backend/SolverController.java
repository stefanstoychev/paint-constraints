package paintcontraints.backend;

import com.google.ortools.Loader;
import com.google.ortools.sat.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@RestController
public class SolverController {

    @PostMapping("solve")
    public ResponseEntity<List<Result>> solve(@RequestBody SolveRequest request) {
        Loader.loadNativeLibraries();

        CpModel model = new CpModel();
        
        // Map to store H, S, V variables for each shape index
        Map<Integer, Map<ColorComponents, IntVar>> shapeVars = new HashMap<>();
        
        Set<Integer> allIndices = new HashSet<>();
        for (Constraint constraint : request.constraints()) {
            for (int index : constraint.indexes()) {
                allIndices.add(index);
            }
        }

        // Initialize variables (H: 0-360, S: 0-100, V: 0-100)
        for (int index : allIndices) {
            Map<ColorComponents, IntVar> components = new HashMap<>();
            components.put(ColorComponents.H, model.newIntVar(0, 360, "h" + index));
            components.put(ColorComponents.S, model.newIntVar(0, 100, "s" + index));
            components.put(ColorComponents.V, model.newIntVar(0, 100, "v" + index));
            shapeVars.put(index, components);
        }

        // Apply constraints dynamically
        for (Constraint constraint : request.constraints()) {
            if (constraint.indexes().length < 2) continue;
            
            IntVar varTarget = shapeVars.get(constraint.indexes()[1]).get(constraint.color());
            IntVar varSource = shapeVars.get(constraint.indexes()[0]).get(constraint.color());
            int offset = constraint.offset();

            // Constraint: Target [op] Source + Offset
            LinearExpr sourceWithOffset = LinearExpr.newBuilder().add(varSource).add(offset).build();
            
            switch (constraint.operation()) {
                case GT -> model.addGreaterThan(varTarget, sourceWithOffset);
                case GTE -> model.addGreaterOrEqual(varTarget, sourceWithOffset);
                case LT -> model.addLessThan(varTarget, sourceWithOffset);
                case LTE -> model.addLessOrEqual(varTarget, sourceWithOffset);
                case E -> model.addEquality(varTarget, sourceWithOffset);
                case NE -> model.addDifferent(varTarget, sourceWithOffset);
            }
        }

        CpSolver solver = new CpSolver();
        CpSolverStatus status = solver.solve(model);

        if (status == CpSolverStatus.FEASIBLE || status == CpSolverStatus.OPTIMAL) {
            List<Result> results = new ArrayList<>();
            for (int index : allIndices) {
                long h = solver.value(shapeVars.get(index).get(ColorComponents.H));
                long s = solver.value(shapeVars.get(index).get(ColorComponents.S));
                long v = solver.value(shapeVars.get(index).get(ColorComponents.V));
                results.add(new Result(index, (int) h, (int) v, (int) s));
            }
            return ResponseEntity.ok(results);
        } else {
            return ResponseEntity.status(422).build();
        }
    }
}
