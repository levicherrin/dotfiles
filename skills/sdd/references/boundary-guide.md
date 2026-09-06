# Boundary Commitments & Negative Invariants Guide

## Overview

In systems engineering, infrastructure automation, and GitOps, the most damaging outages occur not from missing features, but from uncontrolled blast radiuses, unintended side effects, and blurred ownership boundaries.

Spec-Driven Development enforces two primary defensive mechanisms before writing code:
1. **Negative Invariants**: Explicit, non-negotiable rules specifying what the implementation is strictly forbidden to do.
2. **Boundary Commitments**: Precise delineation of state ownership, dependency permissions, and revalidation triggers.

---

## 1. Negative Invariants (The Forbidden List)

Negative invariants act as hard safety guardrails for AI coding agents and human implementers alike. They declare anti-goals and unsafe operations upfront.

### Why Negative Invariants Are Mandatory

Without explicit negative invariants, implementations gravitate toward convenient shortcuts that break downstream production state:
- An atomic file replacement routine replaces an inode, inadvertently stripping container subordinate UID/GID mappings (`110000:109999`) and POSIX ACLs, taking down Prometheus and Loki.
- A template synchronization engine copies empty git placeholder files (`automations.yaml: []`), overwriting active Home Assistant automations.
- A service definition defaults to systemd `Requires=`, triggering cascading stops across unrelated service stacks when a leaf container restarts.
- An automation script performs broad recursive cleanup or speculation beyond its intended directory tree.

### Constructing Negative Invariants

Every specification must include a dedicated `## Negative Invariants` section. Frame invariants using direct imperative prohibitions:

```markdown
## Negative Invariants
- NEVER replace target file inodes directly without preserving existing POSIX ACLs, extended attributes, and subordinate UID/GID permissions.
- NEVER overwrite non-empty destination configuration files with empty placeholder structures (`[]` or `{}`).
- NEVER configure systemd `Requires=` on non-essential companion services; use `Wants=` and `After=` to prevent cascading shutdowns.
- NEVER delete or prune directories outside the explicit target root `/opt/app/data`.
- NEVER execute destructive database or storage mutations during `--dry-run` or validation passes.
- NEVER invoke autonomous subagent swarms for execution; keep execution bounded to operator-supervised tasks.
```

---

## 2. The Four Boundary Commitments

Boundary commitments define the exact scope of responsibility. Treat them as an operational contract between the component, the operator, and adjacent systems.

### A. This Spec Owns
Identifies the authoritative single source of truth and the exclusive capabilities of this component.

- **Capabilities**: Specific functions, verbs, and endpoints this component delivers.
- **State & Files**: Concrete filesystem paths, database tables, or configuration keys for which this component is the sole authoritative writer.
- **Contracts**: The external interfaces, CLI arguments, or schemas it stabilizes.

*Rule: Exactly one component must own write authority over a given state file.*

### B. Out of Boundary
Explicitly states related concerns that this component will NOT touch or solve.

- **Non-Goals**: Capabilities intentionally deferred or excluded.
- **Neighbor Systems**: Adjacent components that handle related workflows (e.g., "This spec handles static configuration validation; it does not deploy or restart services").
- **Scope Creep Fences**: Features that must not be added as "quick conveniences" during implementation.

### C. Allowed Dependencies
Constrains what external tools, libraries, files, and services this component may interact with.

- **Upstream Binaries / Tools**: Permitted system utilities (e.g., `systemd-analyze`, `podman`, `zfs`, `jq`).
- **Filesystem Access**: Read-only paths and write-only paths.
- **Network Access**: Local sockets only, localhost HTTP, or no external network access.
- **Import Rules**: Permitted libraries and dependency direction (e.g., core logic imports types, but types never import CLI layers).

### D. Revalidation Triggers
Defines conditions that mandate re-running validation tests, schema audits, or downstream integration checks.

- Changes to configuration schema formats.
- Alterations in file permission models or container UID/GID maps.
- Modifications to CLI exit codes or output parsing contracts.
- Updates to host runtime prerequisites (e.g., Linux kernel version, Podman version).

---

## 3. Operational Runtime & Performance Constraints: Targets vs. Safety Ceilings

When specifying performance constraints or execution budgets (particularly for continuous integration, sync loops, or automated health probes), avoid conflating expected runtime with hard safety timeouts.

### The Pitfall of Rigid Micro-Budgets
- **Billing Rounding**: Platforms like GitHub Actions round runner minutes up to the nearest whole integer. An aggressive 60-second limit offers zero billing benefit over a 75-second run (both consume 2 minutes) while dramatically increasing false-positive test failures during transient runner load or container layer pulls.
- **Truncated Coverage**: Forcing entire pipelines into arbitrary micro-budgets tempts developers to strip out thorough integration tests (such as container validation or multi-directory dependency checks).

### The Two-Tier Constraint Pattern
Specifications must clearly distinguish:

1. **Performance Target (Expected Benchmark)**:
   - The anticipated duration under normal execution, warm caches, and steady-state conditions (e.g., Target: ~45-75 seconds).
   - Serves as an architectural baseline for step ordering (fail-fast: cheapest checks first) and regression detection.
2. **Enforceable Safety Ceiling (Circuit Breaker)**:
   - A hard, guaranteed cutoff threshold (e.g., `timeout-minutes: 5` / 300 seconds).
   - Designed strictly to prevent runaway processes, infinite loops, or stalled network pulls from exhausting monthly billing quotas or wedging worker pools.
   - Provides generous headroom (typically 3x-5x target runtime) so operational variance never triggers false failures.

---

## 4. Empirical CLI, Tool & External Dependency Verification

Before formalizing external CLI commands, subcommands, flags, or external dependency pins in a specification contract:
- **Never Speculate**: Do not extrapolate CLI flags or subcommands based on generic tool patterns (e.g., assuming `tool validate` or `tool fmt --check` exists).
- **Inspect `--help`**: Execute `<tool> --help` and `<tool> <subcommand> --help` on the live binary in the local development environment.
- **Match Target Environment Versions**: Ensure sandbox tooling matches the exact version running in the target production environment (as documented in repository configs, ADRs, or service definitions). If undocumented, install the latest stable upstream release. Never validate against arbitrary outdated binaries.
- **Fixture Verification**: Test the command invocation against actual repository files and fixtures to verify exit codes, error streams, and plugin prerequisites before committing them to the specification.
- **External Dependency Resolution (MANDATORY)**: Never speculate or hallucinate commit SHAs, container image digests, or release tags. Every external immutable reference (such as GitHub Actions commit SHAs, container image digests, or third-party artifact hashes) declared in "Allowed Dependencies" or implementation steps MUST be empirically verified against the upstream source of truth (via GitHub MCP `github:get_commit`, `gh api`, or container registry inspection) before entering the specification. Declaring an unverified SHA is a fatal contract defect.
- **Active Upstream Freshness**: Query the upstream source of truth (via GitHub MCP `get_latest_release`, registry CLI, or package index) to confirm that third-party dependencies reflect the active stable release line. Never specify legacy major lines facing runtime deprecation.

---

## 5. Example: Homelab GitOps File Synchronizer

```markdown
## 2. Negative Invariants
- NEVER change file ownership away from container UID `110000:109999` on destination mountpoints.
- NEVER write to destination when `--dry-run` is active.
- NEVER cascade container failures by using systemd `Requires=` on logging agents.
- NEVER overwrite destination files if source payload is zero bytes or empty YAML.

## 3. Boundary Commitments

### This Spec Owns
- Reading declared manifests from `/etc/gitops/manifests/*.yaml`.
- Atomic file deployment into `/srv/containers/config/`.
- Exit code conventions (0 for clean sync, 1 for validation error, 2 for permission fault).

### Out of Boundary
- Building or pulling container images (handled by container-engine spec).
- Restarting systemd units (handled by service-orchestrator).
- Modifying host firewall rules or ZFS dataset properties.

### Allowed Dependencies
- Local binaries: `/usr/bin/podman`, `/usr/bin/systemctl`, `/bin/cp`, `/bin/chmod`.
- Python standard library only; zero external pip dependencies.
- Read-only access to `/etc/gitops/`; write access restricted strictly to `/srv/containers/config/`.

### Revalidation Triggers
- Any change to container subuid/subgid range in `/etc/subuid`.
- New service stack onboarding into `/etc/gitops/manifests/`.
- Schema changes in `manifests/*.yaml`.
```
