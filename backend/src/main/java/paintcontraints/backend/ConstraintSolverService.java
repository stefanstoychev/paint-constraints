package paintcontraints.backend;

import com.google.ortools.Loader;
import com.google.ortools.sat.*;
import com.google.ortools.util.Domain;
import org.springframework.stereotype.Service;
import org.yaml.snakeyaml.util.Tuple;

import java.util.*;

@Service
public class ConstraintSolverService {

    public List<Result> solve(SolveRequest request) {
        Loader.loadNativeLibraries();

        CpModel model = new CpModel();

        // Map to store H, S, V variables for each shape index
        Map<Integer, Map<ColorComponents, IntVar>> shapeVars = new HashMap<>();

        Set<Integer> allIndices = new HashSet<>();
        for (Relationship relationship : request.relationships()) {
            for (int index : relationship.indexes()) {
                allIndices.add(index);
            }
        }

        Map<Integer, Map<ColorComponents, ColorConstraint>> colorComponentsMapMap = new HashMap<>();
        for (ColorConstraint constraint : request.constraints()) {
            colorComponentsMapMap.computeIfAbsent(constraint.index(), k -> new HashMap<>()).put(constraint.component(), constraint);
            allIndices.add(constraint.index());
        }

        for (int index : allIndices) {
            Map<ColorComponents, IntVar> components = new HashMap<>();

            Tuple<Integer, Integer> range = getRange(colorComponentsMapMap, index, ColorComponents.H);
            if (range._1() > range._2()) {
                Domain multiRangeDomain = Domain.fromIntervals(
                        new long[][]{
                                {range._1(), 360},
                                {0, range._2()}
                        }
                );

                // Create IntVar with multi-range domain
                IntVar x = model.newIntVarFromDomain(multiRangeDomain, "h" + index);
                components.put(ColorComponents.H, x);
            } else {
                components.put(ColorComponents.H, model.newIntVar(range._1(), range._2(), "h" + index));
            }
            range = getRange(colorComponentsMapMap, index, ColorComponents.S);
            components.put(ColorComponents.S, model.newIntVar(range._1(), range._2(), "s" + index));

            range = getRange(colorComponentsMapMap, index, ColorComponents.V);
            components.put(ColorComponents.V, model.newIntVar(range._1(), range._2(), "v" + index));
            shapeVars.put(index, components);
        }

        // Apply constraints dynamically
        for (Relationship relationship : request.relationships()) {
            if (relationship.indexes().length < 2) continue;

            IntVar varSource = shapeVars.get(relationship.indexes()[0]).get(relationship.color());
            IntVar varTarget = shapeVars.get(relationship.indexes()[1]).get(relationship.color());

            LinearExprBuilder linearExprBuilder = LinearExpr.newBuilder().add(varTarget);

            if (relationship.operation() != Operation.E) {
                linearExprBuilder.add(-10);
            }

            LinearExpr targetWithOffset = linearExprBuilder.build();
            switch (relationship.operation()) {
                case GT -> model.addGreaterThan(varSource, targetWithOffset);
                case GTE -> model.addGreaterOrEqual(varSource, targetWithOffset);
                case LT -> model.addLessThan(varSource, targetWithOffset);
                case LTE -> model.addLessOrEqual(varSource, targetWithOffset);
                case E -> model.addEquality(varSource, targetWithOffset);
                case NE -> model.addDifferent(varSource, targetWithOffset);
            }

            // Unless the relationship is "Equal", enforce that the components themselves are different
            if (relationship.operation() != Operation.E) {
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

            for (Relationship relationship : request.relationships()) {
                if (relationship.indexes().length < 2) continue;
                long value = solver.value(shapeVars.get(relationship.indexes()[0]).get(relationship.color()));
                long value2 = solver.value(shapeVars.get(relationship.indexes()[1]).get(relationship.color()));
                System.out.println(relationship.toString(value, value2));
            }
            return results;
        } else {
            return null; // or throw a custom exception
        }
    }

    private Tuple<Integer, Integer> getRange(Map<Integer, Map<ColorComponents, ColorConstraint>> colorComponentsMapMap,
                                             int index,
                                             ColorComponents colorComponents) {
        Map<ColorComponents, ColorConstraint> colorComponentsColorConstraintMap = colorComponentsMapMap.get(index);
        if (colorComponentsColorConstraintMap == null)
            return getRange(colorComponents);

        ColorConstraint colorConstraint = colorComponentsColorConstraintMap.get(colorComponents);
        return new Tuple<>(colorConstraint.min(), colorConstraint.max());
    }

    private Tuple<Integer, Integer> getRange(ColorComponents colorComponents) {
        if (colorComponents == ColorComponents.H) {
            return new Tuple<>(0, 360);
        }
        return new Tuple<>(0, 100);
    }
}
