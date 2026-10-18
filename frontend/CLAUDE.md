# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run -d chrome    # Run in browser (debug)
flutter analyze          # Static analysis / lint
flutter test             # Run all tests
flutter build web --release --pwa-strategy=offline-first --base-href "/"  # Production build
```

Run a single test file: `flutter test test/some_test.dart`

## Architecture

**Flutter web app** — a canvas-based shape editor where users draw polygons and define color constraints, which are solved by a Spring Boot / Google OR-Tools backend.

### Navigation flow
`ProjectGallery` (home, list/create projects) → `CanvasEditor` (main workspace). No named routes; navigation is done via Provider state + context push/pop.

### State management (Provider / ChangeNotifier)
| Provider | Responsibility |
|---|---|
| `ProjectManager` | Project CRUD, current selection, calls `StorageService` |
| `CanvasController` | Canvas shapes, gesture handling, edit mode, undo/redo dispatch |
| `ConstraintManager` | Color relationships & clamp constraints (owned by `CanvasController`) |
| `ViewportController` | Zoom & pan |
| `SolverService` | HTTP POST to backend `/solve` endpoint |

### Edit modes (enum `EditMode` in `canvas_data.dart`)
`SELECT_SHAPE` · `LINK_SHAPES_COLOR` · `CLAMP_COLOR` · `EDIT_SHAPE_VERTEXES`

### Command pattern (undo/redo)
`lib/commands/` — all mutating operations implement `CanvasCommand` (execute/undo). `CommandHistory` (in `CanvasController`) holds the undo/redo stack. Never mutate shape state directly; always go through a command.

### Key data types
- `ShapeData` (`lib/models/shape_data.dart`) — polygon vertices + HSV color
- `CanvasData` (`lib/models/canvas_data.dart`) — shapes + color relationships + constraints
- `ColorRelationship` / `ShapeColorConstraint` — enums driving what the solver receives

### Services
- `SolverService` — sends current canvas state to backend; result colors are applied via `UpdateShapeColorsCommand`
- `StorageService` — wraps `SharedPreferences` for local project persistence
- `ImageExportService` — PNG export
- `PwaUpdateService` — PWA lifecycle / update prompt

### Geometry
Pure utility functions (centroid, point-in-polygon, distance-to-segment) live in `lib/utils/geometry_utils.dart`.

## Deployment
Docker Compose runs frontend (Flutter + Nginx, port 80) and backend (Spring Boot, port 8080). Backend URL is configured at build time; frontend calls it via `SolverService`.
