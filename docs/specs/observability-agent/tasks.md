# Implementation Tasks: Observability Specialist Agent

- **Feature**: `observability-agent`
- **Specification**: [`docs/specs/observability-agent/spec.md`](spec.md)
- **Status**: Completed
- **Governing Policies**: `~/.dotfiles/AGENTS.md`, `~/.dotfiles/OPINIONS.md`, `~/.dotfiles/VOICE.md`

---

## Task Matrix & Acceptance Mapping

| Task ID | Phase | Description | Target Files | Mapped Criteria | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TASK-01** | 1: Definition | Author executable specialist agent markdown file | `agents/agy/observability.md` | `AC-01` - `AC-09` | Completed |
| **TASK-02** | 2: Fan-out | Configure declarative fan-out in Home Manager | `home.nix`, `rebuild.sh` | System Discovery | Completed |
| **TASK-03** | 2: Verification | Verify agent registration in Antigravity harness | CLI / `agy` | `AC-01`, `AC-03` | Completed |
| **TASK-04** | 3: Validation | Execute live end-to-end test against Grafana MCP | Fresh `agy` session | `AC-01` - `AC-07` | Completed |
| **TASK-05** | 3: Validation | Test friction feedback bubble-up and fallback | Fresh `agy` session | `AC-04`, `AC-08`, `AC-09` | Completed |
| **TASK-06** | 4: Sign-off | Run SDD Gap Review and commit preview | Repository | Spec Completion | Completed |
| **TASK-07** | 5: Claude Code | Fan out and verify the Claude Code variant | `agents/claude/observability.md`, `home.nix`, `rebuild.sh` | `AC-10` | Completed |
| **TASK-08** | 5: Claude Code | Evaluate `haiku` against `sonnet` for the Claude variant | `agents/claude/observability.md` | `AC-01` - `AC-09` | Completed (`sonnet` retained) |

---

## Phase 1: Executable Agent Definition

### TASK-01: Author `agents/agy/observability.md`
- **Objective**: Create the declarative specialist agent file with frontmatter metadata, tool boundaries, declared datasource topology, and strict output contract instructions.
- **Requirements**:
  - Frontmatter must define `name: observability`, description, Gemini 3.8 Flash model, read-only tools, and `enable_mcp_tools: true`.
  - Must explicitly forbid file modifications, git operations, and recursive subagents (`enable_write_tools: false`, `enable_subagent_tools: false`).
  - Must declare the pinned homelab datasource topology (Loki: `P8E80F9AEF21F6940`, Prometheus: `PBFA97CFB590B2093`).
  - Must instruct strict LogQL adherence to `skills/loki/SKILL.md` and PromQL adherence to `skills/promql/SKILL.md`.
  - Must incorporate the machine-parseable `STATUS:` header and Output Contract from Section 5.2.
  - Must incorporate the Friction-Triggered Feedback Bubble-Up instructions from Section 5.2 (Item 5).
- **Completion Check**:
  - File exists at `agents/agy/observability.md`.
  - Frontmatter parses cleanly as valid YAML.
  - `./tests/validate.sh` passes with zero em dashes.

---

## Phase 2: Fan-out & Harness Discovery

### TASK-02: Configure Declarative Fan-out in `home.nix` & `rebuild.sh`
- **Objective**: Wire the new `agents/` directory into Home Manager so the specialist agent is declaratively installed into Antigravity's discovery paths.
- **Requirements**:
  - Add symlink mapping in `home.nix` for `agents/` (`home.file.".gemini/config/agents"` or `.agents/agents`).
  - Update `rebuild.sh` directory safety checks if necessary.
- **Completion Check**:
  - Run `./rebuild.sh` successfully.
  - Symlink target resolves directly to `~/.dotfiles/agents`.

### TASK-03: Verify Agent Discovery in Antigravity Harness
- **Objective**: Verify that the primary agent recognizes `observability` in its subagent registry.
- **Requirements**:
  - Run non-interactive `agy agents` to verify that `observability` appears under available subagents list.
- **Completion Check**:
  - `agy` recognizes the `observability` agent by name and role.

---

## Phase 3: Live Verification & Acceptance Testing

### TASK-04: End-to-End Baseline Triage Test
- **Objective**: Execute a live telemetry triage investigation against `https://grafana.leebo.net` in a fresh session.
- **Test Prompt**:
  > "Investigate recent error patterns and alerts across our homelab services using the observability specialist subagent. Summarize recurring issues, impacted services, and suggested fixes."
- **Observable Verification Checklist**:
  - [x] Coordinator invokes `observability` instead of making direct MCP calls in the root turn (`AC-01`).
  - [x] Specialist queries Loki UID `P8E80F9AEF21F6940` and Prometheus UID `PBFA97CFB590B2093` without pre-flight `list_datasources` calls (`AC-03`).
  - [x] All LogQL and PromQL queries conform to skill standards without trial-and-error syntax errors (`AC-05`).
  - [x] Report begins with `STATUS: <HEALTHY | DEGRADED | CRITICAL>` (`AC-01`).
  - [x] Raw logs are suppressed (max 2 lines per error pattern) (`AC-02`).
  - [x] Service health reflects evidence (Default-FAIL verification per `AC-07`).

### TASK-05: Friction-Triggered Feedback Verification
- **Objective**: Verify that when a query syntax error or unknown service format occurs, the agent bubbles up actionable feedback.
- **Test Prompt**:
  > "Run a LogQL query against a simulated non-existent service label and report findings."
- **Observable Verification Checklist**:
  - [x] Specialist catches the empty or error response.
  - [x] Report includes a structured `### 5. Upstream Knowledge & Skill Feedback` block detailing the friction event and target file (`AC-08`).

---

## Phase 4: Gap Review & Operator Sign-off

### TASK-06: Gap Review & Commit Preview
- **Objective**: Run final SDD Phase 3 gap review against `OPINIONS.md`, present staged git diff and commit preview for explicit operator approval.
- **Requirements**:
  - Confirm radical subtraction (no extra wrappers or unneeded scripts).
  - Confirm separation of concerns (runbooks in skills, contract in spec, policy in `AGENTS.md`).
  - Present concise git commit preview.
- **Completion Check**:
  - [x] Operator explicitly reviews and approves git commit.

---

## Phase 5: Claude Code Fan-out

### TASK-07: Fan Out and Verify the Claude Code Variant
- **Objective**: Install `agents/claude/observability.md` into Claude Code's discovery path and confirm it works end to end.
- **Requirements**:
  - Run `./rebuild.sh` so `~/.claude/agents` links to `~/.dotfiles/agents/claude` and `~/.gemini/config/agents` links to `~/.dotfiles/agents/agy`.
  - Confirm `GRAFANA_URL` and `GRAFANA_SERVICE_ACCOUNT_TOKEN` are present in the shell that launches `claude`.
  - Confirm `${VAR}` expansion works in agent-frontmatter `mcpServers` env (spec Section 3.7). If not, move `grafana` to a user-scope MCP config.
- **Result (2026-09-29)**: `./rebuild.sh` succeeded and both links resolve. `${VAR}` expansion in frontmatter `env` and the map-form `mcpServers` both failed (subagent had no Grafana tools). A first fix relied on inheriting the launching shell's environment, which failed in a fresh terminal session (`533a73db`, subagent had no Grafana tools because the shell lacks the systemd user environment). Final fix: launch `mcp-grafana` through `systemd-run --user --pipe`, which inherits the systemd user manager environment. Verified with an empty launching environment. The unit is per subagent invocation, and `RuntimeMaxSec=1h` caps units orphaned by a hard kill of the client.
- **Completion Check**:
  - [x] `/agents` in a fresh `claude` session lists `observability`.
  - [x] A light monitoring prompt in a fresh operator session delegated to `observability` and returned Grafana data (`AC-10`). The subagent allowlist is `Read, mcp__grafana`.
  - [x] `agy agents` still lists `observability` after the directory move.

### TASK-08: Evaluate `haiku` vs `sonnet` for the Claude Variant
- **Objective**: Decide whether the cheaper model is sufficient. `sonnet` is the default until this passes.
- **Requirements**:
  - Run the TASK-04 prompt and the TASK-05 friction scenario with `model: sonnet`, then with `model: haiku`.
  - Score each run against `AC-01` - `AC-09`: output format, raw-log suppression, no pre-flight `list_datasources`, first-try valid LogQL/PromQL, correct Tier 2 trigger.
  - Record turns and token usage per run.
- **Completion Check**:
  - Switch to `haiku` only if it passes every criterion with fewer turns and tokens. Record the result and the decision in this file.
- **Method**: Headless `claude -p` runs with the coordinator fixed to `sonnet`, subagent model set via frontmatter, and the coordinator told not to pass a model override. Subagent model verified per run from the transcript. Raw subagent reports and tool calls were scored from the subagent transcripts, not the coordinator's paraphrase.
- **Results (2026-09-29)**:

  | Criterion | Sonnet | Haiku |
  | :--- | :--- | :--- |
  | AC-01 `STATUS:` header, contract structure, `<details>` drawer | Pass both tests | Pass TASK-04. Fail TASK-05 (no header, no drawer, UID in body) |
  | AC-02 raw-log suppression, no leaked query syntax | Pass | Pass |
  | AC-03 no pre-flight `list_datasources` | Pass | Pass |
  | AC-05 first-try valid LogQL/PromQL | Pass (0 tool errors in 23 calls) | Pass (0 tool errors in 19 calls). Ran one free-text regex on a single service |
  | AC-06 metric and log correlation | Pass | Pass |
  | AC-07 Default-FAIL calibration | Pass: `DEGRADED`, flagged missing telemetry (restarts, ARC, alert rules) | Fail: header `HEALTHY` while listing `DEGRADED` services |
  | Numeric accuracy | Consistent (jellyfin 61, about 116 errors/day) | Inconsistent (jellyfin 1400, 4k, and 63k/day in one report) |
  | Remediation grounded in repo | Yes | No (advised docker-compose for a Quadlet host) |
  | AC-08 Section 5 on friction | Partial: emitted a minor Section 5 on TASK-04, none on TASK-05 | None |
  | Subagent turns / tool calls (TASK-04) | 24 / 21 | 29 / 17 |
  | Cost, TASK-04 (coordinator + subagent) | $0.231 | $0.238 (subagent alone $0.130) |

- **Decision**: Keep `model: sonnet`. Haiku failed AC-01 (TASK-05), AC-07, and numeric accuracy, and was not cheaper end to end on TASK-04.
- **Open items**:
  - AC-08 is unproven for Claude: neither model emitted Section 5 for the simulated missing service, which is not a tool error. Design a test that produces real friction (malformed selector or a service with unclassified log lines).
  - The Sonnet TASK-05 report set `Overall Status` to "Not applicable", which is outside the contract enum. Consider an explicit rule for probe-only requests.
