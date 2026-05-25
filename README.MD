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