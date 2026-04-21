package paintcontraints.backend;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@RestController
@CrossOrigin
public class SolverController {

    private final ConstraintSolverService solverService;

    public SolverController(ConstraintSolverService solverService) {
        this.solverService = solverService;
    }

    @PostMapping("solve")
    public ResponseEntity<List<Result>> solve(@RequestBody SolveRequest request) {
        List<Result> results = solverService.solve(request);
        if (results != null) {
            return ResponseEntity.ok(results);
        } else {
            return ResponseEntity.status(422).build();
        }
    }
}
