# EARS Syntax Guide

## Overview

EARS (Easy Approach to Requirements Syntax) is the standard format for acceptance criteria in Spec-Driven Development (SDD). It eliminates ambiguity by structuring requirements into predictable, verifiable clauses: preconditions, triggers, system subjects, and deterministic responses.

Every acceptance criterion must map directly to a testable condition using the standard numbered format `AC-01`, `AC-02`, etc.

---

## Core EARS Patterns

### 1. Event-Driven Requirements
Triggered by an external action or system event.

- **Pattern**: When [event], the [system] shall [action]
- **Use Case**: Immediate response to a discrete command, signal, or message.
- **Example**:
  - `AC-01`: When `bin/fido apply` is invoked, the fanout engine shall load the target host inventory from `hosts.yaml`.
  - `AC-02`: When a Git commit hook detects a modified systemd unit, the pre-merge validator shall run `systemd-analyze verify` against the file.

### 2. State-Driven Requirements
Active while a specific condition or operational state holds.

- **Pattern**: While [precondition], the [system] shall [action]
- **Use Case**: Continuous behavior, rate limiting, or modal execution.
- **Example**:
  - `AC-03`: While running in `--dry-run` mode, the file synchronization engine shall output proposed filesystem modifications to stdout without mutating destination paths.
  - `AC-04`: While the ZFS snapshot task is running, the backup worker shall buffer incoming write telemetry in local memory.

### 3. Unwanted Behavior (Negative / Error) Requirements
Triggered when an anomaly, invalid input, or boundary violation occurs.

- **Pattern**: If [trigger], the [system] shall [action]
- **Use Case**: Error handling, boundary enforcement, and failure recovery.
- **Example**:
  - `AC-05`: If a source configuration file contains empty YAML collections (`[]` or `{}`), the validator shall abort execution with exit code 1 and output the offending file path.
  - `AC-06`: If the target destination directory lacks POSIX ACL support, the copy routine shall halt before copying file payloads and emit an error log.

### 4. Optional Feature Requirements
Applies only when a specific feature or configuration flag is enabled.

- **Pattern**: Where [feature is enabled], the [system] shall [action]
- **Use Case**: Configurable modules, platform-specific adaptations, or conditional flags.
- **Example**:
  - `AC-07`: Where rootless Podman integration is configured, the engine shall map container UIDs using `subuid(5)` offset allocations.
  - `AC-08`: Where the `--verbose` flag is passed, the CLI shall log each file copy operation with timestamps, source inodes, and destination modes.

### 5. Ubiquitous Requirements
Always-active system invariants and fundamental properties.

- **Pattern**: The [system] shall [action]
- **Use Case**: Baseline security, performance ceilings, and structural invariants.
- **Example**:
  - `AC-09`: The fanout engine shall preserve existing file ownership (UID/GID) and POSIX permissions during atomic copy operations.
  - `AC-10`: The validation script shall return exit code 0 on successful verification.

---

## Combined Patterns

Complex operational scenarios often require combining state preconditions with event triggers or error handling.

### State Precondition + Event Trigger
- **Pattern**: While [precondition], when [event], the [system] shall [action]
- **Example**:
  - `AC-11`: While connected to the staging cluster, when an image deployment is requested, the controller shall verify image signature against the staging key ring.

### State Precondition + Unwanted Behavior
- **Pattern**: While [precondition], if [trigger], the [system] shall [action]
- **Example**:
  - `AC-12`: While running in non-interactive CI mode, if a required environment variable is unset, the runner shall exit immediately with exit code 2.

---

## Acceptance Criteria Quality Standards

1. **Deterministic Testability**: An acceptance criterion must be verifiable by an automated test script, command output check, or deterministic inspection. Avoid fuzzy words like "fast", "graceful", "robust", or "clean".
2. **Discrete Identifiers**: Always assign each criterion a sequential numeric ID (`AC-01`, `AC-02`, etc.) grouped under its parent requirement heading.
3. **Concrete Subjects**: Explicitly name the component, service, or CLI tool (e.g., "The fanout engine shall...", "The validator shall...", "The systemd generator shall..."). Avoid vague pronouns like "it" or "the code".
4. **Active Imperative**: Use "shall" for mandatory contractual behavior.
5. **Technology Independence in Requirements**: The acceptance criterion states WHAT observable behavior occurs, not internal implementation algorithms. Technical design details belong in the design section.
