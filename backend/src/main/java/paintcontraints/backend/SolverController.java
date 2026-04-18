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
    public ResponseEntity add(@RequestBody SolveRequest request) {
        Loader.loadNativeLibraries();

        CpModel model = new CpModel();
        HashMap<Integer, IntVar> indexes = new HashMap<>();
        for (Constraint constraint : request.constraints()) {
            for (int index : constraint.indexes()) {
                if(!indexes.containsKey(index)) {
                    switch (constraint.color()){
                        case H -> {
                            IntVar intVar = model.newIntVar(0, 360,  "h"+index);
                            indexes.put(index, intVar);
                        }
                        case V -> {
                            IntVar intVar = model.newIntVar(0, 100,  "v"+index);
                            indexes.put(index, intVar);
                        }
                        case S -> {
                            IntVar intVar = model.newIntVar(0, 100,  "s"+index);
                            indexes.put(index, intVar);
                        }
                    }
                }
            }
        }
        for (Constraint constraint : request.constraints()) {
            IntVar intVarA = indexes.get(constraint.indexes()[0]);
            IntVar intVarB = indexes.get(constraint.indexes()[1]);

            switch (constraint.operation()) {
                case GT -> {
                    LinearExpr build = LinearExpr.newBuilder()
                            .add(intVarA)
                            .addTerm(intVarB, -1)
                            .build();
                    model.addLinearConstraint(build, 5, 10);
                }
            }
        }
        model.addAllDifferent(indexes.values());

        CpSolver solver = new CpSolver();
        CpSolverStatus status = solver.solve(model);

        long valueA = solver.value(indexes.get(0));
        long valueB = solver.value(indexes.get(1));

        List<Result> result = List.of(
            new Result(0, (int) valueA, 10, 10),
            new Result(1, (int) valueB, 10, 10));

        return ResponseEntity.of(Optional.of(result));
    }
}
