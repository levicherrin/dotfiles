---
name: github-actions
description: Author, audit, harden, and optimize GitHub Actions workflows (.github/workflows/*.yaml). Use when writing new workflows, reviewing existing CI configurations, hardening security against script injection and over-privileged tokens, optimizing runner minutes and billing quotas, adding concurrency cancellation, path filtering, or upgrading actions to supported runtimes. Triggers on requests like "/github-actions", "/github-actions:author", "/github-actions:audit", "/github-actions:upgrade", "review workflow", "secure CI", "optimize GitHub Actions", "harden workflow", "reduce CI minutes", "pin actions to SHA", "fix GITHUB_TOKEN permissions", or "is this workflow safe".
---

# GitHub Actions: Authoring, Hardening & Optimization

A unified runbook for authoring, auditing, and maintaining secure, cost-efficient GitHub Actions workflows.

---

## 1. Policy Anchors & Core Principles

All workflows must adhere to centralized dotfiles governance and two simultaneous operational requirements:
- **Separation of Concerns** (`~/.dotfiles/OPINIONS.md`, Section 2): This skill is a procedural runbook defining the "How". Organizational heuristics live in `~/.dotfiles/OPINIONS.md`.
- **The Core Trade-off Principle**: A workflow must never be optimized for speed at the expense of security, nor hardened at the expense of runaway runner costs.
- **File Extension Standard**: Always standardize on `.yaml` (avoid legacy `.yml`).
- **Autonomy & Safety** (`~/.dotfiles/AGENTS.md`): Never push workflow changes to remote repositories or execute git commits autonomously. Present previews for operator consent.
- **Formatting**: Direct, technical voice per `~/.dotfiles/VOICE.md`. Zero emojis. Zero unicode em dashes (use ASCII hyphens `-`).

---

## 2. Operational Modes Overview

This skill supports three distinct operational sub-commands:

```text
1. /github-actions:author   --> Author a production-ready, hardened, efficient workflow
2. /github-actions:audit    --> Run a 5-step adversarial security and efficiency review
3. /github-actions:upgrade  --> Upgrade action runtimes and resolve immutable commit SHAs
```

---

## 3. Mode 1: Authoring Workflows (`/github-actions:author <name>`)

**Objective**: Author a new workflow file under `.github/workflows/<name>.yaml` that is secure by default and optimized against CI minute quotas.

### Step-by-Step Authoring Checklist

1. **Standard Extension**: Save the file as `.github/workflows/<name>.yaml`.
2. **Define Triggers & Path Filtering**:
   - Filter branches: `branches: [main]`.
   - Apply `paths:` filters to limit execution to relevant source directories, dependencies, and the workflow file itself. Consult [references/efficiency-optimization.md](file:///home/levi/repos/dotfiles/skills/github-actions/references/efficiency-optimization.md).
3. **Declare Top-Level Permissions (Deny by Default)**:
   - Add `permissions: {}` at the root, or set `permissions: contents: read` if all jobs only checkout code.
   - Grant write scopes only on specific jobs that require them (e.g. `pull-requests: write`). Consult [references/security-hardening.md](file:///home/levi/repos/dotfiles/skills/github-actions/references/security-hardening.md).
4. **Configure Concurrency Cancellation**:
   - Add `concurrency: group: ${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true` to prevent superseded commits from wasting runner minutes.
5. **Set Job Timeouts**:
   - Add `timeout-minutes: 5` (or `10` for heavy integration jobs) to prevent hung runner processes.
6. **Pin Actions to Empirically Verified 40-Character Commit SHAs**:
   - Discover latest stable release: Run GitHub MCP `github:get_latest_release(owner, repo)` or `gh release view -R {owner}/{repo}` to identify the current upstream stable release tag and check for runtime deprecations.
   - Resolve immutable SHA: Never speculate commit SHAs. Resolve and verify the target release tag to its immutable 40-character commit SHA via GitHub MCP (`github:get_commit`) or `gh api repos/{owner}/{repo}/commits/{tag}` before declaring the pin.
   - Use immutable commit SHAs with a trailing version comment (e.g. `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`).
   - Set `with: persist-credentials: false` on `actions/checkout` unless git push operations are required.
7. **Safe Variable Passing**:
   - Never interpolate `${{ github.event.* }}` or `${{ github.head_ref }}` directly into `run:` or `script:` blocks. Pass them through step-level `env:` variables and reference quoted shell variables (`"$VAR"`).
8. **Fail-Fast Step Sequencing**:
   - Order fast static checks (shellcheck, linters, static typing) before slower unit or integration tests.
9. **Template Reference**:
   - Use [assets/workflow-template.yaml](file:///home/levi/repos/dotfiles/skills/github-actions/assets/workflow-template.yaml) as the baseline starter.

---

## 4. Mode 2: Auditing Existing Workflows (`/github-actions:audit [path]`)

**Objective**: Audit `.github/workflows/*.yaml` against security vulnerabilities and runtime inefficiencies.

### 5-Step Sequential Audit Procedure

#### Step 1: Privilege & Trigger Mapping
- Inspect all `on:` triggers.
- Identify dangerous triggers: `pull_request_target`, `workflow_run`, `issue_comment`, `issues`.
- **CRITICAL Check**: If a `pull_request_target` workflow checks out the PR head commit (`ref: ${{ github.event.pull_request.head.sha }}`) and executes code (`npm install`, `make`, tests), flag immediately as CRITICAL RCE risk. Require the two-workflow pattern.

#### Step 2: Script Injection Hunt
- Search all `run:` blocks and `actions/github-script` steps for `${{ }}`.
- Flag any interpolation of attacker-controllable contexts (`github.event.issue.title`, `github.event.pull_request.title`, `github.head_ref`, etc.).
- Require remediation via step-level `env:` binding.

#### Step 3: Token Scope Audit
- Check for top-level `permissions:`. If missing, flag as MEDIUM (inherits repo defaults).
- Flag `permissions: write-all` as HIGH.
- Verify that jobs declare only the minimal permissions they actually consume.

#### Step 4: Supply Chain Audit
- Inspect all `uses:` entries.
- Flag mutable references: third-party actions using tags (`@v1`, `@v4`) or branches (`@main`) as HIGH.
- Flag first-party actions using tags without SHAs as LOW.
- Confirm all SHA pins include trailing `# vX.Y.Z` version comments.
- **Empirical Resolution Check (MANDATORY)**: Verify every pinned commit SHA exists upstream using GitHub MCP `github:get_commit(owner, repo, sha)` or `gh api repos/{owner}/{repo}/commits/{sha}` (or `git ls-remote`). If the API returns 404 or 422, flag immediately as **CRITICAL: Unresolvable Action Commit SHA (Pipeline Breaking)**.
- **Freshness Check**: Compare pinned `# vX.Y.Z` against latest release via `github:get_latest_release(owner, repo)`. Flag pins trailing major releases behind upstream as MEDIUM (stale action runtime or missing security patches).

#### Step 5: Efficiency & Cost Audit
- Check for `concurrency:` with `cancel-in-progress: true`. Flag if missing.
- Check for `paths:` or `paths-ignore:` on `pull_request` triggers. Flag workflows that trigger on markdown or documentation changes.
- Check for `timeout-minutes:` on all jobs. Flag jobs relying on the 360-minute default.
- Check for matrix expansion: flag multi-OS or multi-version matrices running on routine PRs that could be consolidated into a single representative job.
- Check for dependency caching: confirm lockfile-based caching is configured.

### Audit Report Format

Always present findings using the following structure:

```markdown
## GitHub Actions Audit: <workflow-file>

### Findings Summary
| Severity | Count | Category |
| --- | --- | --- |
| CRITICAL | 0 | Remote Code Execution / Privileged Trigger Sinks |
| HIGH | 1 | Mutable Action References / Script Injection |
| MEDIUM | 1 | Missing Permissions Block |
| LOW | 1 | Missing Timeout Ceilings |
| INFO | 0 | Best Practice Observations |

### Detailed Findings

#### [HIGH] Mutable Third-Party Action Reference
- **Location**: `.github/workflows/ci.yaml:L24`
- **Offending Code**:
  ```yaml
  uses: some-org/some-action@v2
  ```
- **Risk**: Upstream tag mutation can inject malicious code executing with runner privileges.
- **Remediation**:
  ```yaml
  uses: some-org/some-action@3f1e0a9c8b7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f # v2.1.0
  ```

#### [LOW] Missing Job Timeout Ceiling
- **Location**: `.github/workflows/ci.yaml:L15`
- **Risk**: A stalled runner job defaults to 360 minutes, risking private quota exhaustion.
- **Remediation**: Add `timeout-minutes: 5` to the job definition.
```

---

## 5. Mode 3: Runtime Upgrades (`/github-actions:upgrade [path]`)

**Objective**: Address action runtime deprecation warnings (e.g., Node.js migrations) by resolving target release tags to immutable commit SHAs.

### Execution Steps

1. **Scan Deprecation Warnings**: Identify actions emitting runtime warnings in workflow execution logs.
2. **Resolve Commit SHA**:
   Use `gh api` to resolve the latest compatible release tag to its 40-character commit SHA:
   ```bash
   gh api repos/{owner}/{repo}/commits/{tag} --jq '.sha'
   ```
   Or via `git ls-remote`:
   ```bash
   git ls-remote https://github.com/{owner}/{repo}.git refs/tags/{tag} | awk '{print $1}'
   ```
3. **Update Workflow Reference**:
   Replace the `uses:` string with the resolved SHA and trailing `# vX.Y.Z` comment:
   ```yaml
   - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
   ```
4. **Validate and Test**:
   Verify syntax locally and test the action execution on a branch. Upgrade one action per commit to keep history atomic.
   Consult [references/runtime-upgrades.md](file:///home/levi/repos/dotfiles/skills/github-actions/references/runtime-upgrades.md).

---

## 6. Reference and Asset Index

- [Security Hardening Reference](file:///home/levi/repos/dotfiles/skills/github-actions/references/security-hardening.md) (`references/security-hardening.md`)
- [Efficiency & Cost Optimization Reference](file:///home/levi/repos/dotfiles/skills/github-actions/references/efficiency-optimization.md) (`references/efficiency-optimization.md`)
- [Runtime Upgrades Reference](file:///home/levi/repos/dotfiles/skills/github-actions/references/runtime-upgrades.md) (`references/runtime-upgrades.md`)
- [Starter Workflow Template](file:///home/levi/repos/dotfiles/skills/github-actions/assets/workflow-template.yaml) (`assets/workflow-template.yaml`)
