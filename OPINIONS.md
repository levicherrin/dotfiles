# Levi's Engineering Opinions & Architectural Heuristics

When evaluating technical architectures, selecting tools, or designing software systems, align with these default engineering heuristics.

---

## 1. Architectural Philosophy
* **Simplicity Over Complexity**: Choose the simplest architecture that solves the concrete problem today. Avoid speculative abstractions.
* **Boring Technology**: Prefer proven, mature technologies with well-understood failure modes over newly hyped frameworks.
* **Monolith First**: Default to unified, modular architectures before breaking systems into distributed services.
* **Single Source of Truth**: Eliminate configuration drift by managing state declaratively (e.g., Nix, Infrastructure as Code).
* **Idempotency Over Pre-Orchestration**: When an underlying tool is idempotent and fast, invoke it directly. Never write wrapper scripts, pre-flight gatekeepers, or diff-checking logic to decide whether to invoke an idempotent tool. The tool itself is the state checker.

---

## 2. Agent Skill Architecture (Execution vs. Policy)
* **Separation of Concerns**: Agent skills (`skills/`) exist strictly as procedural runbooks (the "How": CLI commands, APIs, tool usage). Organizational governance (the "Why" and "What": templates, labels, state machines) must live centrally in `~/.dotfiles/` (e.g., `GITHUB_WORKFLOW.md`).
* **Lightweight Upstream Patches**: Do not deeply customize or rewrite open-source skills to fit our organization. Instead, lightly patch them by sanitizing formatting (e.g., removing emojis/em dashes), stripping conflicting hardcoded rules, and injecting pointers to our centralized `.dotfiles` policies.

---

## 3. Dependencies & Code Ownership
* **Current Stable Upstream**: When introducing external dependencies, tools, or container runtimes, always build against the active stable upstream release line. Never institutionalize legacy major versions or obsolete runtimes into new architecture.
* **Minimal Dependency Footprint**: Prefer writing 20 lines of clean, readable code you own rather than pulling in large external libraries for trivial utility functions.
* **Standard Library First**: Utilize the language runtime's built-in capabilities before looking for third-party packages.
* **Explicit Over Implicit**: Favor clear, explicit code flow over "magic", metaprogramming, or deeply nested abstractions.

---

## 4. Testing & Reliability
* **End-to-End Realism**: Bug fixes must always start with reproducing the issue in an end-to-end setting that mirrors real user experience.
* **Zero Flakiness**: Flaky tests are treated as broken builds. Fix or isolate non-deterministic tests immediately.
* **Fast Feedback Loops**: Keep automated test suites and validation scripts fast and lightweight.

---

## 5. Operational Discipline
* **Direct Path**: Start with the simplest direct end-to-end path for all software, services, and automation, regardless of execution frequency. Do not build custom wrappers, policy engines, pre-flight orchestrators, or control planes unless the direct native path (e.g., native systemd directives invoking a tool directly) exposes a concrete, reproducible blocker that justifies the added machinery.
* **Radical Subtraction Before Scoping**: Before architecting, estimating, or implementing any feature or backlog item, perform a radical subtraction test: eliminate every intermediate script, abstraction, and wrapper. If native OS primitives (systemd, git, POSIX shell) and existing tools can execute the workflow directly, build only that minimal configuration.
* **Clean History**: Write atomic, descriptive commit messages without automated agent co-author tags.
