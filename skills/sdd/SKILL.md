---
name: sdd
description: Author, refine, and review authoritative engineering specifications using Spec-Driven Development (SDD). Use when defining new features, architectural refactors, system scripts, or homelab infrastructure initiatives before writing code. Triggers on requests like "/sdd", "/sdd:quick", "/sdd:discovery", "/sdd:spec", "/sdd:review", "spec-driven development", "write a spec for X", "create a specification for X", "run discovery on X", "audit spec for gaps", or before implementing critical systems changes.
---

# Spec-Driven Development (SDD)

A lightweight, rigorous runbook for authoring authoritative engineering specifications, boundary commitments, negative invariants, and acceptance criteria before writing code.

---

## 1. Policy Anchors & Architecture

All specifications and implementations must strictly adhere to centralized dotfiles governance:
- **Separation of Concerns** (`~/.dotfiles/OPINIONS.md`, Section 2): This skill is a procedural runbook defining the "How". Organizational engineering heuristics (the "Why" and "What") live in `~/.dotfiles/OPINIONS.md`.
- **Operator Autonomy & Safety** (`~/.dotfiles/AGENTS.md`): No autonomous swarms. Never spawn multi-agent implementer/debugger swarms. Execution requires human operator supervision, dry-runs, and deterministic tests.
- **Adaptive Spec Locations**:
  - Diataxis repositories (e.g., homelab): Store discovery briefs and working drafts in `research/specs/<feature-name>/`. Authoritative contracts move to `docs/03_reference/<feature>-specification.md`.
  - Standard repositories: Store specs directly in `docs/specs/<feature-name>/`.
  - No `.kiro/` directories, `spec.json` manifests, or npm dependencies.
- **Tone & Formatting**: Direct, technical voice per `~/.dotfiles/VOICE.md`. Zero emojis. Zero unicode em dashes (use ASCII hyphens `-`).

---

## 2. SDD Workflow Summary

Spec-Driven Development supports two workflows:

1. **Standard Phased Workflow** (for complex, high-risk, or multi-component initiatives):
   Discovery (`/sdd:discovery`) -> Spec & Tasks (`/sdd:spec`) -> Gap Review (`/sdd:review`) -> Implementation

2. **Fast-Path Workflow** (for well-scoped operational tasks, single scripts, or CI/CD pipelines):
   Quick Spec (`/sdd:quick`) -> Gap Review (`/sdd:review`) -> Implementation

---

## 3. Fast-Path: Quick Spec (`/sdd:quick <feature>`)

**Objective**: Generate discovery framing, negative invariants, boundary commitments, EARS acceptance criteria, and implementation tasks in a single streamlined pass for well-scoped or low-complexity initiatives.

### Execution Steps

1. **Context & Repository Scan**:
   - Inspect repository structure and check for Diataxis conventions (`research/`, `docs/03_reference/`).
   - Identify operational constraints, host environment, and blast radius.

2. **Formulate Specification**:
   - Establish explicit **Negative Invariants** ("NEVER ...").
   - Define **Boundary Commitments** (This Spec Owns, Out of Boundary, Allowed Dependencies).
   - **Empirical CLI & Dependency Verification**: If the feature invokes external tools, linters, or generators, inspect the binary's `--help` output in the local development environment and test commands against repository fixtures before declaring CLI contracts. If declaring pinned commit SHAs (e.g., GitHub Actions), container image digests, or release versions, verify them against the upstream API before declaring contracts.
   - **Two-Tier Runtime Limits**: Distinguish between expected steady-state performance targets and enforceable safety ceilings (e.g., `timeout-minutes: 5`).
   - Formulate **EARS Requirements** with numbered acceptance criteria (`AC-01`, `AC-02`, etc.).
   - Build **Implementation Tasks** mapped to AC IDs with observable completion criteria.

3. **Write Deliverables**:
   - Write specification contract (`docs/03_reference/<feature>-specification.md` for Diataxis or `docs/specs/<feature-name>/spec.md` for Standard).
   - Write implementation plan (`research/specs/<feature-name>/tasks.md` for Diataxis or `docs/specs/<feature-name>/tasks.md` for Standard).

4. **Immediate Gap Review**:
   - Run the Phase 3 gap audit immediately and output the review verdict.
   - Suggest next step: Proceed to Phase 4 (Implementation).

---

## 4. Phase 1: Discovery (`/sdd:discovery <feature>`)

**Objective**: Isolate the problem, identify blast radius, establish operational constraints, and evaluate technical trade-offs before designing architecture.

### Execution Steps

1. **Lightweight Scan**:
   - Check existing specifications in `research/specs/` or `docs/specs/` to prevent duplicate boundaries or conflicting ownership.
   - Inspect project root to detect repository conventions (e.g., Diataxis), existing tools, and layout.

2. **Problem Framing Interview**:
   Ask targeted questions sequentially to clarify intent:
   - **Problem & Pain**: What is broken or missing? Who experiences the failure?
   - **Blast Radius**: What adjacent services, containers, or datasets could break if this fails?
   - **Current State vs. Desired Outcome**: What is the observable delta when complete?
   - **Operational Constraints**: What are host runtime restrictions (e.g., rootless Podman, systemd dependencies, ZFS dataset properties, Python/Bash runtime constraints)?

3. **Approach Evaluation**:
   Propose 2-3 technical approaches adhering to `OPINIONS.md` (Simplicity Over Complexity, Boring Technology, Minimal Dependency Footprint):
   - Contrast architecture, dependencies, risks, and implementation complexity.
   - **Upstream Dependency Discovery**: When evaluating external tools, container base images, or CI actions, query upstream registries/APIs (e.g., GitHub MCP `github:get_latest_release`, registry CLI) to determine active stable release lines and deprecation timelines before proposing approaches.
   - Recommend the simplest viable approach that solves the concrete problem.
   - Confirm selection with the operator.

4. **Write Discovery Brief**:
   - Write `brief.md` in `research/specs/<feature-name>/` (Diataxis) or `docs/specs/<feature-name>/` (Standard) using `assets/brief-template.md`.
   - Ensure explicit `In-Scope` and `Out-of-Scope` (non-goals) sections are populated.
   - Stop and suggest the next step: `/sdd:spec <feature-name>`.

---

## 5. Phase 2: Specification & Contract (`/sdd:spec <feature>`)

**Objective**: Author the authoritative engineering specification (`spec.md`) and phased implementation plan (`tasks.md`).

### Execution Steps

1. **Load Context**:
   - Read `brief.md` from `research/specs/<feature-name>/` or `docs/specs/<feature-name>/`.
   - Read `references/boundary-guide.md` for negative invariant and boundary rules.
   - Read `references/ears-syntax.md` for EARS requirement syntax rules.
   - Read relevant existing codebase modules and tests.

2. **Define Negative Invariants (Mandatory)**:
   Draft explicit, imperative rules stating what the component is forbidden to do.
   - Examples: Inode replacement stripping UID/GID mappings (`110000:109999`) or POSIX ACLs; overwriting production files with empty placeholders (`[]` or `{}`); adding systemd `Requires=` causing cascading restarts; destructive writes during dry-runs.
   - Consult `references/boundary-guide.md` Section 1.

3. **Define Boundary Commitments**:
   Establish unambiguous ownership seams:
   - **This Spec Owns**: Single authoritative writer for specific files, capabilities, and schemas.
   - **Out of Boundary**: Neighboring components, deferred work, and forbidden scope creep.
   - **Allowed Dependencies**: Permitted system binaries, standard library modules, read/write path limits.
   - **Revalidation Triggers**: Conditions requiring consumers or tests to re-evaluate contracts.

4. **Draft Architecture & File Structure Plan**:
   - Architecture summary and pure Mermaid diagrams for non-trivial data/control flows.
   - File Structure Plan: Map every file to a single clear responsibility before task creation.
   - **Empirical CLI & Dependency Verification**: Never speculate CLI subcommands, flags, or configuration syntax based on generic patterns. Inspect the binary's `--help` output on the live tool and verify invocations against real fixtures before formalizing command contracts in the specification. If specifying external actions, container digests, or package versions, verify each against the upstream registry/API before committing to the contract.
   - **Operational Runtime Constraints**: Distinguish between expected steady-state performance targets (e.g., ~45-75s) and enforceable safety ceilings (e.g., `timeout-minutes: 5`) per `references/boundary-guide.md` Section 3.

5. **Draft EARS Requirements & Numbered ACs**:
   - Formulate requirements using EARS patterns (`When`, `While`, `If`, `Where`, `The system shall`).
   - Assign sequential numbered Acceptance Criteria: `AC-01`, `AC-02`, etc.
   - Ensure every criterion is testable deterministically. Consult `references/ears-syntax.md`.

6. **Write Specification Document**:
   - Write specification contract to `docs/03_reference/<feature>-specification.md` (Diataxis) or `docs/specs/<feature-name>/spec.md` (Standard) using `assets/spec-template.md`.

7. **Draft Implementation Plan (`tasks.md`)**:
   - Structure tasks into sequential phases:
     - Phase 1: Foundation (test harness, fixtures, contract schemas)
     - Phase 2: Core Implementation (engine logic, negative invariant guards)
     - Phase 3: Integration & Wiring (CLI entrypoints, host integration)
     - Phase 4: Validation & Hardening (deterministic test suite, gap audit)
   - Format each task:
     - Checkbox: `- [ ] <MAJOR>.<SUB> <Task summary>`
     - Detail bullets with observable completion criterion ("What does done look like?")
     - Mandatory traceability: `_Requirements: AC-01, AC-02_` (numeric AC IDs only)
     - Mandatory boundary scope: `_Boundary: <path/or/component>_`
     - Cross-task dependencies if non-obvious: `_Depends: 1.1_`
   - Write `tasks.md` to `research/specs/<feature-name>/` (Diataxis) or `docs/specs/<feature-name>/` (Standard) using `assets/tasks-template.md`.
   - Stop and suggest the next step: `/sdd:review <feature-name>`.

---

## 6. Phase 3: Pre-Implementation Review (`/sdd:review <feature>`)

**Objective**: Adversarially audit the specification contract, negative invariants, and task plan *before* writing code.

### Execution Steps

1. **Load Artifacts**:
   - Read specification contract (`docs/03_reference/<feature>-specification.md` or `docs/specs/<feature-name>/spec.md`) and `tasks.md` (`research/specs/<feature-name>/tasks.md` or `docs/specs/<feature-name>/tasks.md`).

2. **Run Mechanical Audits**:
   - **AC Coverage Audit**: Extract all `AC-NN` identifiers from the specification contract. Verify every single `AC-NN` appears in at least one task's `_Requirements:_` tag. Flag any unmapped AC.
   - **Negative Invariant Audit**: Confirm that every negative invariant ("NEVER ...") has a corresponding enforcement check in the design and an explicit verification task in `tasks.md`.
   - **Boundary Leak Audit**: Scan `tasks.md` for tasks touching files or components listed in "Out of Boundary". Verify no task absorbs deferred scope.
   - **Single Responsibility Audit**: Verify that each task operates within a single `_Boundary:_`. Flag tasks attempting cross-boundary coordination without explicit integration designation.
   - **Deliverable Audit**: Confirm that every task specifies an observable completion criterion (e.g., test output, exit code, file artifact) rather than vague activity phrases ("wire up", "handle logic").
   - **External Dependency & Freshness Audit**: Verify that all pinned external commit SHAs (e.g., GitHub Actions), container image digests, and release versions specified in the contract or tasks resolve upstream via API and reflect active stable release lines rather than trailing major versions. Flag any unverified, hallucinated, or obsolete references.

3. **Render Verdict**:
   Output review results in the following format:

```markdown
## Pre-Implementation Review: <feature-name>

- **VERDICT**: PASS | REMEDIATE
- **AC Coverage**: COMPLETE | GAPS DETECTED (<list unmapped ACs>)
- **Negative Invariants**: ENFORCED | UNGUARDED (<list unguarded invariants>)
- **Boundary Check**: CLEAN | LEAKS DETECTED (<list out-of-boundary items>)
- **Task Executability**: READY | REVISIONS REQUIRED (<list vague tasks>)
- **External Dependencies**: RESOLVED & CURRENT | ISSUES DETECTED (<list unresolvable or stale pins>)

### Findings & Required Remediation
1. <Concrete finding with section reference>
2. <Action required before implementation>
```

- If `REMEDIATE`: Update specification or `tasks.md` and re-run `/sdd:review <feature-name>`.
- If `PASS`: Proceed to Phase 4 (Implementation).

---

## 7. Phase 4: Implementation Guidance

1. **Operator Supervision**:
   - Do NOT run autonomous agent swarms. Implement task-by-task or in small cohesive slices.
   - Confirm completion of each task with the human operator.

2. **Test-First Discipline & Invariant Evidence**:
   - Implement foundation test harnesses before core logic.
   - Capture failing tests (RED evidence) before implementing functionality, then verify passing tests (GREEN).
   - **Negative Invariant Proof**: For every negative invariant ("NEVER ..."), author a test case that actively attempts the prohibited mutation and assert that the implementation halts or raises the expected error. Never assume a guard works without negative test evidence.

3. **Deterministic Verification**:
   - Validate negative invariants using negative test cases (confirming forbidden mutations are blocked).
   - Verify dry-run safety (`--dry-run` leaves target state untouched).
   - Execute the project's canonical test suite and linters before closing tasks.

---

## 8. Reference and Asset Index

- [EARS Syntax Guide](file:///home/levi/repos/dotfiles/skills/sdd/references/ears-syntax.md) (`references/ears-syntax.md`)
- [Boundary Commitments & Negative Invariants Guide](file:///home/levi/repos/dotfiles/skills/sdd/references/boundary-guide.md) (`references/boundary-guide.md`)
- [Discovery Brief Template](file:///home/levi/repos/dotfiles/skills/sdd/assets/brief-template.md) (`assets/brief-template.md`)
- [Specification Contract Template](file:///home/levi/repos/dotfiles/skills/sdd/assets/spec-template.md) (`assets/spec-template.md`)
- [Implementation Tasks Template](file:///home/levi/repos/dotfiles/skills/sdd/assets/tasks-template.md) (`assets/tasks-template.md`)
