# Implementation Plan: {{FEATURE_NAME}}

## Execution Rules
- Execute sequentially by default. Order implies dependency.
- Every task must produce an observable deliverable before being marked complete.
- Every task must stay strictly within its declared `_Boundary:_`.
- Do NOT spawn autonomous agent swarms. All execution is guided by the human operator.
- Run local dry-runs and automated tests to verify completion criteria.

---

## Phase 1: Foundation & Test Infrastructure

- [ ] 1.0 Foundation Setup
- [ ] 1.1 Create test harness and fixture scaffolding
  - Establish unit and integration test runner configuration
  - Add mock inputs and fixture files for happy and failure paths
  - Observable completion: Test suite executes cleanly against baseline stubs with expected failure signatures
  - _Requirements: AC-01_
  - _Boundary: tests/fixtures/{{FEATURE_NAME}}/_

- [ ] 1.2 Define core data structures and contract interfaces
  - Implement contract types, input validation schemas, or CLI argument parser
  - Enforce strict typing and input validation boundaries
  - Observable completion: Type definitions and validation functions compile or parse without errors
  - _Requirements: AC-01, AC-02_
  - _Boundary: {{FOUNDATION_SOURCE_FILE}}_

---

## Phase 2: Core Implementation

- [ ] 2.0 Core Feature Implementation
- [ ] 2.1 Implement core processing logic
  - Build main algorithmic engine or operational command
  - Implement negative invariant guards (fail-fast assertions)
  - Observable completion: Core engine processes valid fixtures and emits expected structured outputs
  - _Requirements: AC-01, AC-03_
  - _Boundary: {{CORE_SOURCE_FILE}}_
  - _Depends: 1.2_

- [ ] 2.2 Implement negative invariant enforcement and error handling
  - Add explicit checks preventing prohibited state mutations (permissions, empty files, cascading deps)
  - Add informative diagnostic errors with non-zero exit codes on violations
  - Observable completion: Negative invariant test cases actively trigger expected failure exits
  - _Requirements: AC-02, AC-05_
  - _Boundary: {{CORE_SOURCE_FILE}}_
  - _Depends: 2.1_

---

## Phase 3: Integration & CLI Wiring

- [ ] 3.0 System Integration
- [ ] 3.1 Wire core logic into CLI entrypoint or service caller
  - Connect argument parsing, configuration loading, and core processing
  - Add `--dry-run` and `--verbose` flag handling if required
  - Observable completion: End-to-end CLI command runs from terminal and respects dry-run invariants
  - _Requirements: AC-03, AC-04_
  - _Boundary: {{CLI_ENTRYPOINT_FILE}}_
  - _Depends: 2.1, 2.2_

---

## Phase 4: Validation & Hardening

- [ ] 4.0 Verification & Review
- [ ] 4.1 Run full deterministic test suite
  - Execute automated test suite across all positive and negative test cases
  - Verify zero regressions and check code quality (lint, forbidden characters)
  - Observable completion: 100% test pass rate reported by test runner
  - _Requirements: AC-01, AC-02, AC-03, AC-04, AC-05, AC-06_
  - _Boundary: tests/test_{{FEATURE_NAME}}.py_
  - _Depends: 3.1_

- [ ] 4.2 Pre-implementation gap review and sign-off
  - Run `/sdd:review {{FEATURE_NAME}}` to verify all acceptance criteria and negative invariants
  - Present summary to operator for final acceptance
  - Observable completion: Operator confirms spec fulfillment with zero boundary leaks
  - _Requirements: AC-01 through AC-06_
  - _Boundary: research/specs/{{FEATURE_NAME}}/ or docs/specs/{{FEATURE_NAME}}/_

---

## Implementation Notes & Discoveries

*Record unexpected environmental quirks, host behaviors, or design discoveries made during task execution. Subsequent tasks inherit this context.*

- **Task 1.X**: <!-- e.g. Discovered target file requires in-place open(wb) to preserve container subuid ownership -->
- **Task 2.X**: <!-- e.g. systemd user session D-Bus disconnection requires avoiding sudo for user units -->
