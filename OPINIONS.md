# Levi's Engineering Opinions & Architectural Heuristics

When evaluating technical architectures, selecting tools, or designing software systems, align with these default engineering heuristics.

---

## 1. Architectural Philosophy
* **Simplicity Over Complexity**: Choose the simplest architecture that solves the concrete problem today. Avoid speculative abstractions.
* **Boring Technology**: Prefer proven, mature technologies with well-understood failure modes over newly hyped frameworks.
* **Monolith First**: Default to unified, modular architectures before breaking systems into distributed services.
* **Single Source of Truth**: Eliminate configuration drift by managing state declaratively (e.g., Nix, Infrastructure as Code).

---

## 2. Dependencies & Code Ownership
* **Minimal Dependency Footprint**: Prefer writing 20 lines of clean, readable code you own rather than pulling in large external libraries for trivial utility functions.
* **Standard Library First**: Utilize the language runtime's built-in capabilities before looking for third-party packages.
* **Explicit Over Implicit**: Favor clear, explicit code flow over "magic", metaprogramming, or deeply nested abstractions.

---

## 3. Testing & Reliability
* **End-to-End Realism**: Bug fixes must always start with reproducing the issue in an end-to-end setting that mirrors real user experience.
* **Zero Flakiness**: Flaky tests are treated as broken builds. Fix or isolate non-deterministic tests immediately.
* **Fast Feedback Loops**: Keep automated test suites and validation scripts fast and lightweight.

---

## 4. Operational Discipline
* **Direct Path**: For one-off or infrequent operations, take the direct path. Do not build custom wrappers, policy engines, or control planes without concrete repeat demand.
* **Clean History**: Write atomic, descriptive commit messages without automated agent co-author tags.
