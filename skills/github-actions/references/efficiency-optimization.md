# GitHub Actions Efficiency & Cost Optimization

## Overview

Private GitHub accounts have limited monthly CI minute quotas (e.g., 2,000 minutes/month). Workflows must be designed to eliminate wasted executions, cancel superseded runs, prevent hung runner processes, and avoid matrix billing explosions without compromising verification rigor.

---

## 1. Concurrency Control (Cancel In-Progress Runs)

When developers push multiple commits to an open pull request in rapid succession, previous workflow runs continue burning minutes unless explicitly cancelled.

### The Canonical Concurrency Pattern
Add top-level `concurrency` with `cancel-in-progress: true`:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

- **PR Context**: Pushing a new commit immediately cancels the prior build on that branch.
- **Main/Release Context**: If you must prevent cancelling deploys on `main`, use conditional group keys:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref == 'refs/heads/main' && github.run_id || github.ref }}
    cancel-in-progress: true
  ```

---

## 2. Strict Path Filtering

Never execute full build and test pipelines on changes that touch only documentation, markdown notes, scratch files, or unrelated service directories.

### Inclusion Filtering (`paths:`)
Best when workflows are coupled to specific code trees:

```yaml
on:
  push:
    branches: [main]
    paths:
      - "bin/**"
      - "src/**"
      - "pyproject.toml"
      - "poetry.lock"
      - ".github/workflows/ci.yaml"
  pull_request:
    branches: [main]
    paths:
      - "bin/**"
      - "src/**"
      - "pyproject.toml"
      - "poetry.lock"
      - ".github/workflows/ci.yaml"
```

*Rule: Always include the workflow file itself (`.github/workflows/*.yaml`) in `paths:` so workflow syntax updates are verified on PRs.*

### Exclusion Filtering (`paths-ignore:`)
Best when a repository contains mostly code and only isolated non-functional files:

```yaml
on:
  pull_request:
    branches: [main]
    paths-ignore:
      - "docs/**"
      - "scratch/**"
      - "**.md"
      - ".gitignore"
```

*Warning: Do not combine `paths:` and `paths-ignore:` in the same event definition.*

---

## 3. Runner Timeouts (Execution Ceilings)

GitHub Actions defaults to a **360-minute (6-hour)** execution timeout per job. A hanging network request, locked apt command, or infinite loop can consume a substantial portion of your monthly quota in a single run.

### Enforce Job-Level Timeouts
Declare explicit, tight timeouts tailored to expected runtime:

```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    timeout-minutes: 5    # Fast unit tests, linters, shell validation
    steps: [...]

  integration-test:
    runs-on: ubuntu-latest
    timeout-minutes: 10   # Multi-container or complex test suites
    steps: [...]
```

---

## 4. Matrix Billing Control vs. Sequential Jobs

### The Matrix Explosion Problem
A matrix running across 3 OS platforms and 3 runtime versions creates 9 distinct jobs. On private repositories, each job bills runner minutes rounded up to the nearest minute, plus per-job setup and container initialization overhead (30-60 seconds per job).

### Guidelines for Matrix Sizing
1. **Pull Requests (Standard Development)**:
   - Run against a **single representative configuration** (e.g., `ubuntu-latest` with current production Python/Node runtime).
   - Execute lint, static analysis, and unit tests in a single runner job sequentially to reuse checkout and installed dependencies.
2. **Release / Main Merge / Nightly**:
   - Run full compatibility matrices only on `push` to `main`, scheduled nightlies, or release tags.
3. **Sequential Single-Job Optimization**:
   - For fast suites (< 2 minutes total), running lint, typecheck, and unit tests in one job avoids spinning up 3 separate VMs, saving both wall-clock queue time and startup overhead.

---

## 5. Fail-Fast Step Sequencing

Order steps so that the fastest, strictest checks fail first:

```text
[ 1. Syntax / Shellcheck / Linters ]  (< 10s)  --> Fail immediately
                  |
[ 2. Static Type Checks ]              (< 30s)  --> Fail before testing
                  |
[ 3. Unit Tests ]                      (< 2m)
                  |
[ 4. Integration / Container Tests ]   (< 5m)
```

Never run expensive build or integration steps before validating basic syntax and lockfile consistency.

---

## 6. Dependency Caching

Avoid re-downloading packages from PyPI, npm, or crates.io on every workflow run.

### Native Action Caching (Preferred)
Use built-in caching support within setup actions:

```yaml
# Python with pip
- uses: actions/setup-python@42375524e23c412d93fb67b49958b491fce71c38 # v5.4.0
  with:
    python-version: "3.12"
    cache: "pip"

# Node with npm
- uses: actions/setup-node@1d0ff469b7ec7b3cb9d8673fde0c81c44821de2a # v4.2.0
  with:
    node-version: "22"
    cache: "npm"
```

### Generic Cache (`actions/cache`)
For system binaries or complex dependency directories:

```yaml
- uses: actions/cache@d4323d4df104b026a6aa633fdb11d772115b6fe6 # v4.2.2
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements*.txt', '**/pyproject.toml') }}
    restore-keys: |
      ${{ runner.os }}-pip-
```
