package paintcontraints.backend;

import com.google.ortools.Loader;
import com.google.ortools.sat.*;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class ConstraintSolverService {

    public List<Result> solve(SolveRequest request) {
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

            IntVar varSource = shapeVars.get(constraint.indexes()[0]).get(constraint.color());
            IntVar varTarget = shapeVars.get(constraint.indexes()[1]).get(constraint.color());
            double offset = constraint.offset();
            long scaledOffset = Math.round(offset);

            // Constraint: Source [op] Target + Offset
            LinearExpr targetWithOffset = LinearExpr.newBuilder().add(varTarget).add(scaledOffset).build();

            switch (constraint.operation()) {
                case GT -> model.addGreaterThan(varSource, targetWithOffset);
                case GTE -> model.addGreaterOrEqual(varSource, targetWithOffset);
                case LT -> model.addLessThan(varSource, targetWithOffset);
                case LTE -> model.addLessOrEqual(varSource, targetWithOffset);
                case E -> model.addEquality(varSource, targetWithOffset);
                case NE -> model.addDifferent(varSource, targetWithOffset);
            }

            // Unless the relationship is "Equal", enforce that the components themselves are different
            if (constraint.operation() != Operation.E) {
                model.addDifferent(varSource, varTarget);
            }
        }

        CpSolver solver = new CpSolver();
        CpSolverStatus status = solver.solve(model);

        if (status == CpSolverStatus.FEASIBLE || status == CpSolverStatus.OPTIMAL) {
            List<Result> results = new ArrayList<>();
            for (int index : allIndices) {
                Map<ColorComponents, IntVar> colorComponentsIntVarMap = shapeVars.get(index);
                long h = solver.value(colorComponentsIntVarMap.get(ColorComponents.H));
                long s = solver.value(colorComponentsIntVarMap.get(ColorComponents.S));
                long v = solver.value(colorComponentsIntVarMap.get(ColorComponents.V));
                results.add(new Result(index, (int) h, (int) s, (int) v));
            }

            for (Constraint constraint : request.constraints()) {
                if (constraint.indexes().length < 2) continue;
                long value = solver.value(shapeVars.get(constraint.indexes()[0]).get(constraint.color()));
                long value2 = solver.value(shapeVars.get(constraint.indexes()[1]).get(constraint.color()));
                System.out.println(constraint.toString(value, value2));
            }
            return results;
        } else {
            return null; // or throw a custom exception
        }
    }
}
