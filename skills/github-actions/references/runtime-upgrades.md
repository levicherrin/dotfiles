# GitHub Actions Runtime Upgrades & Action Maintenance

## Overview

GitHub periodically deprecates older action runtime engines (e.g., Node.js 16 to Node.js 20). When deprecation warnings appear in workflow run logs, actions must be upgraded to modern releases while preserving exact workflow behavior and pinning to immutable commit SHAs.

---

## 1. Resolving Tags to Immutable 40-Character Commit SHAs

Never pin an action to a mutable tag (e.g., `@v4`). Always resolve the target release tag to its corresponding 40-character commit SHA.

### Method A: Using the `gh` CLI (Preferred)
```bash
# Query the commit SHA corresponding to a release tag
gh api repos/{owner}/{repo}/commits/{tag} --jq '.sha'

# Example: Resolve actions/checkout v4.2.2
gh api repos/actions/checkout/commits/v4.2.2 --jq '.sha'
# Output: 11bd71901bbe5b1630ceea73d27597364c9af683
```

### Method B: Using `git ls-remote` (No Auth Required)
```bash
git ls-remote https://github.com/{owner}/{repo}.git refs/tags/{tag} | awk '{print $1}'

# Example: Resolve actions/setup-python v5.4.0
git ls-remote https://github.com/actions/setup-python.git refs/tags/v5.4.0 | awk '{print $1}'
# Output: 42375524e23c412d93fb67b49958b491fce71c38
```

---

## 2. Standard Pinning Syntax

Always format the `uses:` line with the 40-character SHA followed by a trailing inline comment indicating the human-readable version:

```yaml
# Correct format
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
- uses: actions/setup-python@42375524e23c412d93fb67b49958b491fce71c38 # v5.4.0
```

This ensures:
1. **Immutability**: Upstream tag re-pointing cannot inject modified code into your workflow.
2. **Readability**: Operators immediately know which major/minor release is active.
3. **Dependabot Compatibility**: Dependabot parses the trailing comment to detect available updates.

---

## 3. Step-by-Step Upgrade Procedure

When upgrading actions to address deprecation notices or modernize dependencies:

1. **Identify the Target Action**: Check workflow logs for warnings such as `Node.js 16 actions are deprecated`.
2. **Review Upstream Release Notes**: Check the action repository's releases page for breaking input/output changes between major versions.
3. **Resolve the New SHA**: Use `gh api` to fetch the commit SHA for the latest stable release.
4. **Update Workflow YAML**: Replace the old SHA and version comment with the new target.
5. **Verify Locally**: Run static validation (`./tests/validate.sh` or action linters) to confirm valid YAML syntax.
6. **Trigger Test Run**: Push to a feature branch or trigger `workflow_dispatch` to verify the step completes cleanly.
7. **One Upgrade per Commit**: Commit one action upgrade at a time with an atomic commit message (e.g., `chore(ci): bump actions/checkout to v4.2.2`).
