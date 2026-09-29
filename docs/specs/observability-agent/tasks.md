# Implementation Tasks: Observability Specialist Agent

- **Feature**: `observability-agent`
- **Specification**: [`docs/specs/observability-agent/spec.md`](spec.md)
- **Status**: Completed
- **Governing Policies**: `~/.dotfiles/AGENTS.md`, `~/.dotfiles/OPINIONS.md`, `~/.dotfiles/VOICE.md`

---

## Task Matrix & Acceptance Mapping

| Task ID | Phase | Description | Target Files | Mapped Criteria | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TASK-01** | 1: Definition | Author executable specialist agent markdown file | `agents/observability-agy.md` | `AC-01` - `AC-09` | Completed |
| **TASK-02** | 2: Fan-out | Configure declarative fan-out in Home Manager | `home.nix`, `rebuild.sh` | System Discovery | Completed |
| **TASK-03** | 2: Verification | Verify agent registration in Antigravity harness | CLI / `agy` | `AC-01`, `AC-03` | Completed |
| **TASK-04** | 3: Validation | Execute live end-to-end test against Grafana MCP | Fresh `agy` session | `AC-01` - `AC-07` | Completed |
| **TASK-05** | 3: Validation | Test friction feedback bubble-up and fallback | Fresh `agy` session | `AC-04`, `AC-08`, `AC-09` | Completed |
| **TASK-06** | 4: Sign-off | Run SDD Gap Review and commit preview | Repository | Spec Completion | Completed |

---

## Phase 1: Executable Agent Definition

### TASK-01: Author `agents/observability-agy.md`
- **Objective**: Create the declarative specialist agent file with frontmatter metadata, tool boundaries, declared datasource topology, and strict output contract instructions.
- **Requirements**:
  - Frontmatter must define `name: observability`, description, Gemini 3.8 Flash model, read-only tools, and `enable_mcp_tools: true`.
  - Must explicitly forbid file modifications, git operations, and recursive subagents (`enable_write_tools: false`, `enable_subagent_tools: false`).
  - Must declare the pinned homelab datasource topology (Loki: `P8E80F9AEF21F6940`, Prometheus: `PBFA97CFB590B2093`).
  - Must instruct strict LogQL adherence to `skills/loki/SKILL.md` and PromQL adherence to `skills/promql/SKILL.md`.
  - Must incorporate the machine-parseable `STATUS:` header and Output Contract from Section 5.2.
  - Must incorporate the Friction-Triggered Feedback Bubble-Up instructions from Section 5.2 (Item 5).
- **Completion Check**:
  - File exists at `agents/observability-agy.md`.
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
