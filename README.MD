# <img src="frontend/web/icons/icon-512x512.png" width="38" height="38" valign="middle" alt="Logo"> Paint Constraints
An experimental canvas application where users can create/edit shapes and define relationships and constraints for colors.

Beyond the app itself, this project is a living laboratory for "vibecoding"—testing different AI agents, multi-model workflows, and cross-language stack generation (Flutter to Spring Boot) while exploring human-in-the-loop strategies to manage comprehension debt.

[👉 Try the Live Demo](https://paint-constraints.devfriday.top/)

---

## ✨ Features (The App Idea)

* **Dynamic Shape Canvas:** Create, edit, and manipulate geometric vectors shapes seamlessly.
* **Constraint-Driven Relationships:** Set boundaries for shape colors.
* **Constraint Solver Backend:** Leverages industrial-grade optimization to solve and enforce layout/color rules instantly.

---

## 📸 Screenshots

Captured by the integration test. Regenerate with `frontend/scripts/update_screenshots.sh`.

<!-- screenshots:start -->
<details open>
<summary>20 screenshots</summary>

<table>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/01_gallery_empty.png"><img src="frontend/screenshots/01_gallery_empty.png" width="400" alt="Gallery empty"></a><br>
      <sub>Gallery empty</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/02_create_dialog.png"><img src="frontend/screenshots/02_create_dialog.png" width="400" alt="Create dialog"></a><br>
      <sub>Create dialog</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/03_create_dialog_filled.png"><img src="frontend/screenshots/03_create_dialog_filled.png" width="400" alt="Create dialog filled"></a><br>
      <sub>Create dialog filled</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/04_canvas_empty.png"><img src="frontend/screenshots/04_canvas_empty.png" width="400" alt="Canvas empty"></a><br>
      <sub>Canvas empty</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/05_one_shape.png"><img src="frontend/screenshots/05_one_shape.png" width="400" alt="One shape"></a><br>
      <sub>One shape</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/06_two_shapes.png"><img src="frontend/screenshots/06_two_shapes.png" width="400" alt="Two shapes"></a><br>
      <sub>Two shapes</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/07_link_mode_active.png"><img src="frontend/screenshots/07_link_mode_active.png" width="400" alt="Link mode active"></a><br>
      <sub>Link mode active</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/08_edit_vertices_mode.png"><img src="frontend/screenshots/08_edit_vertices_mode.png" width="400" alt="Edit vertices mode"></a><br>
      <sub>Edit vertices mode</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/09_after_undo.png"><img src="frontend/screenshots/09_after_undo.png" width="400" alt="After undo"></a><br>
      <sub>After undo</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/10_after_redo.png"><img src="frontend/screenshots/10_after_redo.png" width="400" alt="After redo"></a><br>
      <sub>After redo</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/11_clamp_mode_no_selection.png"><img src="frontend/screenshots/11_clamp_mode_no_selection.png" width="400" alt="Clamp mode no selection"></a><br>
      <sub>Clamp mode no selection</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/12_clamp_panel_open.png"><img src="frontend/screenshots/12_clamp_panel_open.png" width="400" alt="Clamp panel open"></a><br>
      <sub>Clamp panel open</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/13_link_mode_two_selected.png"><img src="frontend/screenshots/13_link_mode_two_selected.png" width="400" alt="Link mode two selected"></a><br>
      <sub>Link mode two selected</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/14_after_save.png"><img src="frontend/screenshots/14_after_save.png" width="400" alt="After save"></a><br>
      <sub>After save</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/15_gallery_with_project.png"><img src="frontend/screenshots/15_gallery_with_project.png" width="400" alt="Gallery with project"></a><br>
      <sub>Gallery with project</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/16_snap_vertices_linked.png"><img src="frontend/screenshots/16_snap_vertices_linked.png" width="400" alt="Snap vertices linked"></a><br>
      <sub>Snap vertices linked</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/17_snap_vertices_dragged.png"><img src="frontend/screenshots/17_snap_vertices_dragged.png" width="400" alt="Snap vertices dragged"></a><br>
      <sub>Snap vertices dragged</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/18_snap_vertices_separated.png"><img src="frontend/screenshots/18_snap_vertices_separated.png" width="400" alt="Snap vertices separated"></a><br>
      <sub>Snap vertices separated</sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="frontend/screenshots/19_split_first_vertex.png"><img src="frontend/screenshots/19_split_first_vertex.png" width="400" alt="Split first vertex"></a><br>
      <sub>Split first vertex</sub>
    </td>
    <td align="center" width="50%">
      <a href="frontend/screenshots/20_split_shape.png"><img src="frontend/screenshots/20_split_shape.png" width="400" alt="Split shape"></a><br>
      <sub>Split shape</sub>
    </td>
  </tr>
</table>

</details>
<!-- screenshots:end -->

---

## 🤖 The Vibecoding Experiment

Building a cross-language app (Dart/Flutter frontend + Java/Spring Boot backend) with algorithmic requirements is a true stress test for AI agents.

### 🛠️ The Agent Toolchain
* **TBD:** Add-hoc usage of agents

### 🧠 Managing "Comprehension Debt"
> **The Core Philosophy:** Pure vibecoding inevitably builds up "comprehension debt"—the gap between what the code does and what the developer actually understands.
>
> To combat this, manual coding was intentionally introduced whenever token limits were hit. This forced pause allowed for manual code review, refactoring, and mental synchronization with the AI-generated architecture, ensuring the project remained maintainable.

---

## 📦 Tech Stack

### Frontend
* **Framework:** Flutter (Web/Desktop)
* **Language:** Dart
* **State Management / Canvas:** Custom interactive vector canvas

### Backend
* **Framework:** Spring Boot (Java)
* **Optimization Engine:** Google OR-Tools (used for solving the shape relationships and color constraints linearly/combinatorially)
* **API:** REST for real-time constraint updates

---

## 🛠️ Local Setup

### Backend (Spring Boot)
Ensure you have Java 17+ and Maven installed.

Run:
```bash
   cd backend
   mvn spring-boot:run
```

### Frontend (Flutter)
Ensure you have the Flutter SDK installed and configured for Web.

Navigate to the frontend directory:

Install:
```bash
  cd frontend
  flutter pub get
```

Run:
```bash
  flutter run -d chrome
```

### 📄 License
Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
