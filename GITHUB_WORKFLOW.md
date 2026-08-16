# GitHub Workflow & Templates

This document governs the standard day-to-day GitHub development lifecycle (GitHub.com and GitHub Enterprise Server), issue tracking, label management, daily status updates, and pull request procedures for agents and operators.

---

## 1. Branch Naming Standard

All feature branches created for development must follow this format:

```text
<type>/<short-description>
```

### Allowed Types:
* `feat`: New user features, capabilities, or major enhancements.
* `fix`: Bug fixes, defect remediation, and regression patches.
* `refactor`: Code improvements that do not alter external behavior.
* `docs`: Documentation, guides, and architectural notes.
* `test`: Adding or refactoring test suites and validation scripts.
* `chore`: Dependency updates, build configurations, and tooling tweaks.

### Examples:
* `feat/sso-saml-auth`
* `fix/session-token-expiration`
* `refactor/api-client-timeout`
* `docs/github-setup-guide`

---

## 2. Commit Message Standards & Cadence

### Commit Message Standard (Conventional Commits)

```text
<type>(<scope>): <short imperative summary>

[optional concise body explaining context/rationale]
```

* **Types**: `feat`, `fix`, `docs`, `refactor`, `perf`, `chore`, `security`.
* **Subject**: Imperative mood ("add", "inject", "refactor", not "added" or "adds"), lowercase, under 72 characters, no trailing period.
* **Body**: Keep concise and technical. Explain context and non-obvious rationale. NEVER write multi-paragraph essay-length commit messages.
* **Rules**: Never use emojis, use plain ASCII hyphens (`-`), and NEVER auto-add agent co-author tags.

### Commit Cadence (Atomic Chunking)

* **Atomic Commits**: Commit immediately after completing and validating a distinct, working unit of work (e.g., adding a Nix module, updating a documentation file, or refactoring a network config).
* **No Mega-Commits**: Do not accumulate multiple unrelated changes into single monolithic commits.
* **Validation Gate**: Run relevant syntax and validation checks (e.g., `./tests/validate.sh`) before committing to ensure the working tree remains green.

### Operator Consent & Push Policy

* **Commit Preview Gate**: Never run `git commit` autonomously without explicit operator confirmation. Stop and present a concise report to obtain consent:
  1. **Staged Files Preview**: List of files to be included in the commit.
  2. **Proposed Commit Message**: Full text (`<type>(<scope>): <summary>` and concise body).
* **Never Push Autonomously**: Never run `git push` to remote origins without explicit operator direction.

---

## 3. Issue Lifecycle, Labels & State Machine

Every task follows a deterministic lifecycle tracked via GitHub labels:

```text
[ status:backlog ] ──► [ status:in-progress ] ──► [ status:in-review ] ──► [ status:done ]
```

### Label Standards:
* **Priority (Mandatory on creation)**:
  * `priority:high`
  * `priority:medium`
  * `priority:low`
* **Status (Mandatory state tracking)**:
  * `status:backlog` (Default upon issue creation)
  * `status:in-progress` (Active development started)
  * `status:in-review` (Pull request open and under review)
  * `status:done` (Completed and closed)

### State Transitions & Label Management:
1. **Task Creation (`status:backlog`)**:
   * Inspect the repository for local `.github/ISSUE_TEMPLATE/` forms. If present, extract and incorporate repo-specific fields; otherwise, use Template A.
   * Create the issue with `status:backlog` and an explicit priority label (`priority:high`, `priority:medium`, or `priority:low`).
2. **Work Started (`status:in-progress`)**:
   * Swap label: remove `status:backlog` and add `status:in-progress`.
   * Create working branch (`<type>/<short-description>`).
3. **Active Development (Daily Updates)**:
   * While the issue remains `status:in-progress`, post a daily status update comment on the issue before ending the session.
4. **Pull Request Opened (`status:in-review`)**:
   * Inspect the repository for `.github/PULL_REQUEST_TEMPLATE.md`; otherwise, use Template C.
   * Open PR referencing the issue (`Resolves #123`).
   * Swap label: remove `status:in-progress` and add `status:in-review`.
5. **Completion & Validation (`status:done`)**:
   * **Linked PR Path**: Once the PR is merged, verify the issue is closed and update the label: remove `status:in-review` and add `status:done`.
   * **Operator-Instructed Path (No PR)**: When an operator instructs that an issue without a PR is complete, update the label to `status:done` and close the issue (`gh issue close <id>`).
   * **Validation Requirement**: Agents must explicitly verify that `state == CLOSED` and `status:done` is present before concluding the task.

---

## 4. Standard Writing Templates

When authoring issues, comments, or PRs, follow these templates unless the target repository provides specific `.github/` templates. Maintain Levi's voice: direct, technical, clear, and free of generic AI clichés.

### Template A: Issue Creation

```markdown
### Objective
[2-3 sentences explaining the concrete problem, business driver, or feature objective.]

### Acceptance Criteria
- [ ] [Criterion 1: Concrete and testable behavior]
- [ ] [Criterion 2: Error handling or edge case validation]
- [ ] [Criterion 3: Tests or documentation updated]

### Technical Approach
- **Affected Components**: [Modules, repositories, or services involved]
- **Proposed Architecture**: [Brief notes on implementation strategy, interfaces, or libraries]
- **Verification Plan**: [How this work will be reproduced and tested end-to-end]
```

---

### Template B: Daily Standup / In-Progress Comment

```markdown
### Daily Status Update - [YYYY-MM-DD]

#### Today's Progress
- [Concrete achievement grounded in actual commits/diffs made today]
- [Second concrete achievement or architectural milestone reached]

#### Next Steps
- [Immediate task scheduled for the next session]
- [Follow-up verification or test coverage to complete]

#### Blockers & Dependencies
- [State "None" or describe technical blockers, waiting reviews, or API access needs]
```

---

### Template C: Pull Request Description

```markdown
### Summary of Changes
[Concise paragraph explaining what was implemented, modified, or fixed, and why.]

### Linked Issues
- Resolves #[Issue Number]

### Key Modifications
* **[Module / Subsystem]**: [Detailed bullet point of changes]
* **[Module / Subsystem]**: [Detailed bullet point of changes]

### Verification & Testing
- [x] End-to-end bug reproduction and fix verified.
- [x] Unit/Integration tests passing: `[command run]`
- [x] Static analysis / Linting passing: `[command run]`

### Risk & Deployment Considerations
* **Rollback Plan**: [How to revert if issues arise]
* **Dependencies**: [Any migration scripts, env vars, or external services needed]
```

---

### Template D: Code Review Comment Response

```markdown
### Review Feedback Response

Thanks for the feedback. 

#### Changes Made:
1. **[Concern / Recommendation 1]**: Addressed in commit [`[short-sha]`](link). [1-2 sentences explaining technical adjustments made].
2. **[Concern / Recommendation 2]**: [Brief explanation of resolution or rationale].
```

---

## 5. Security & Least-Privilege PAT Scoping

When generating a Personal Access Token (PAT) for Kiro or automated agent tools on GitHub, apply least-privilege scoping to prevent destructive actions:

### Required Scopes:
* `repo` (Full repository access for cloning, branch creation, issues, PRs, and commits).
* `project` (Read and write access to GitHub Projects v2 boards).

### Prohibited / Omitted Scopes:
* `delete_repo` (DO NOT grant repo deletion permissions).
* `admin:org` (DO NOT grant organization admin permissions).
* `admin:enterprise` (DO NOT grant enterprise admin permissions).
* `admin:repo_hook` (DO NOT grant webhook management).

---

## 6. Tooling Reference (`gh` CLI & MCP)

### Useful `gh` CLI Commands:

```bash
# Authenticate against GitHub.com or GHES
gh auth login
# For GitHub Enterprise Server:
# gh auth login --hostname ghes.yourdomain.com

# Create issue with mandatory labels
gh issue create \
  --title "feat: user saml auth" \
  --body-file issue.md \
  --label "status:backlog,priority:medium"

# Transition to In Progress
gh issue edit 104 --remove-label "status:backlog" --add-label "status:in-progress"

# Post daily update comment
gh issue comment 104 --body-file daily-update.md

# Open PR linking issue and transition to In Review
gh pr create --title "feat: implement saml auth" --body-file pr-body.md
gh issue edit 104 --remove-label "status:in-progress" --add-label "status:in-review"

# Monitor CI checks
gh pr checks --watch

# Complete work & close issue (Validation)
gh issue edit 104 --remove-label "status:in-review" --add-label "status:done"
gh issue close 104
gh issue view 104 --json state,labels
```

### GitHub MCP Server Configuration (`~/.kiro/mcp_config.json`):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<YOUR_GITHUB_TOKEN>",
        "GITHUB_API_URL": "https://api.github.com"
      }
    }
  }
}
```
*(For GHES instances, set `"GITHUB_API_URL": "https://ghes.yourdomain.com/api/v3"`)*
