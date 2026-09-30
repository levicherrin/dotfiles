# Observability Specialist Agent Specification

- **Feature Name**: `observability-agent`
- **Status**: Draft (Phase 2: Handoff Schema & EARS Acceptance Criteria)
- **Target Audience**: Primary Coordinator Agent & Operator
- **Governing Policies**: `~/.dotfiles/AGENTS.md`, `~/.dotfiles/OPINIONS.md`, `~/.dotfiles/VOICE.md`

---

## 1. Overview & Problem Statement

### 1.1 Context
The homelab infrastructure runs distributed services monitored by Grafana, Loki (log aggregation), and Prometheus (metrics). Agents frequently need to inspect service health, investigate error spikes, and triage incidents using the `grafana` Model Context Protocol (MCP) server.

### 1.2 Problem Statement
When the primary coordinator agent is tasked with telemetry investigation without specialization, it encounters three systemic failure modes:
1. **Tool-in-Hand Bias & Severe Context Pollution**: Having 40+ Grafana MCP tools directly available in its active toolset causes the coordinator to execute dozens of sequential queries in the root turn. Raw log lines and JSON payloads flood the primary conversation window, degrading the model's reasoning and planning capabilities.
2. **Trial-and-Error Query Execution & UID Guessing**: Without explicit skill grounding and declared topology, agents repeatedly guess invalid `datasourceUid` strings or malformed LogQL/PromQL expressions, burning turns on API errors before guessing correct parameters.
3. **Shallow Synthesis**: Instead of performing structured root-cause analysis, coordinators overwhelmed by log volume frequently resort to dumping raw, unparsed logs back to the user.

### 1.3 Solution
Introduce an isolated, capability-decoupled specialist subagent (`observability`). The coordinator delegates telemetry investigation to this specialist, which operates in a clean, ephemeral context window. The specialist is bound to curated PromQL and Loki runbooks, holds pre-declared datasource topology, executes targeted queries against Grafana MCP, and returns a structured diagnostic report to the coordinator.

---

## 2. Negative Invariants (Structural Safety & Determinism)

These rules are enforced structurally through capability configurations and prompt constraints:

1. **`NEVER execute environment-mutating tools`**:
   The specialist must have `enable_write_tools: false` (Antigravity) or a `tools` allowlist that omits `Bash`, `Edit`, and `Write` (Claude Code). It cannot create, edit, or delete files on the host filesystem (`write_to_file`, `replace_file_content`, mutating shell scripts). It is strictly read-only.
2. **`NEVER execute git commits or pushes`**:
   The specialist must never stage, commit, or push code. Git authoring authority remains strictly with the human operator per `AGENTS.md`.
3. **`NEVER spawn recursive subagents`**:
   The specialist must have `enable_subagent_tools: false` (Antigravity) or omit `Agent` from its `tools` allowlist (Claude Code). It operates strictly as a leaf worker and cannot define or spawn subordinate agents.
4. **`NEVER dump unparsed raw logs to the coordinator`**:
   The specialist must never return raw log streams or large unstructured JSON payloads to the coordinator. All telemetry must be aggregated, deduplicated, and synthesized before handoff.
5. **`NEVER mutate Grafana or datasource configuration`**:
   The specialist must not create, modify, or delete dashboards, alert rules, notification channels, or datasource definitions.
6. **`NEVER query unverified or guessed datasource UIDs`**:
   The specialist is strictly prohibited from guessing datasource UIDs. It must query against declared homelab datasource topology, falling back to `list_datasources` only when topology drift or connection errors occur.
7. **`NEVER construct speculative queries outside bound skill patterns`**:
   All LogQL and PromQL expressions must adhere strictly to the established patterns in `skills/loki/SKILL.md` and `skills/promql/SKILL.md` (e.g. mandatory stream selectors, range vectors >= 4x scrape interval, divide-by-zero guards).

---

## 3. Boundary Commitments

### 3.1 In-Scope (This Spec Owns)
- **Log Telemetry Execution**: Executing LogQL queries via `query_loki_logs`, discovering recurring log patterns with `query_loki_patterns`, and enumerating stream labels via `list_loki_label_names` and `list_loki_label_values`.
- **Metric Telemetry Execution**: Executing PromQL queries via `query_prometheus` (target health via `up`, alert evaluations via `ALERTS`, error rate calculations, and scrape performance).
- **Incident & Sift Discovery**: Running read-only Sift investigations (`find_error_pattern_logs`, `find_slow_requests`) and inspecting active alert endpoints.
- **Cross-Service Correlation**: Correlating metric anomalies in Prometheus with corresponding error traces in Loki across services.
- **Diagnostic Synthesis**: Packaging findings into a standardized diagnostic handoff contract (Status, Impacted Services, Root Cause Signatures, Actionable Findings).

### 3.2 Out-of-Scope (Non-Goals)
- **Remediation & Fix Execution**: Modifying systemd unit files, restarting containers, applying code patches, or editing deployment manifests. (Owned by the primary coordinator or human operator).
- **Dashboard & Alert Authoring**: Provisioning or modifying Grafana dashboards or Prometheus rules. (Owned by the `dashboarding` skill or operator).
- **Direct User Interaction**: The specialist does not converse directly with the human operator; it communicates strictly via the subagent handoff interface to the coordinator.

### 3.3 Skill Authority Binding
The specialist agent is structurally bound to the knowledge and query patterns codified in local dotfiles skills:
- **Loki Authority**: `skills/loki/SKILL.md` (Log stream selectors, structured metadata filtering, label formatting, and pattern extraction).
- **PromQL Authority**: `skills/promql/SKILL.md` (Rate/increase range vector calculations, `histogram_quantile` outer aggregations, instant vs range queries, and divide-by-zero protections).
- **Alloy Pipeline Authority**: `skills/alloy/SKILL.md` (OpenTelemetry Collector processing, OTTL statement syntax `ExtractPatterns`/`merge_maps`/`replace_pattern`, and pipeline topology for diagnosing classification drift).

### 3.4 Declared Homelab Datasource Topology
To eliminate trial-and-error round-trips against Grafana MCP, the specialist is configured with the active homelab datasource topology:
- **Loki Datasource UID**: `P8E80F9AEF21F6940` (Default log aggregation endpoint)
- **Prometheus Datasource UID**: `PBFA97CFB590B2093` (Default metrics endpoint)
- **Drift Fallback Protocol**: If a query against a declared UID returns `404` or `datasource not found`, the agent executes `list_datasources` once to discover the new UID and proceeds.

### 3.5 Homelab OpenTelemetry Pipeline Specification
Our homelab infrastructure routes all logs through Grafana Alloy (`repos/homelab/config/system/config.alloy`). The pipeline executes a 10-tier normalization waterfall (`otelcol.processor.transform "enrich"`) that strips ANSI codes, parses JSON/logfmt/bracketed levels/syslog severities, and attaches canonical OpenTelemetry attributes to every log line exported to Loki's `/otlp` endpoint:

1. **Indexed Loki Stream Labels**:
   - `service_name`: Canonical workload identifier (`jellyfin`, `caddy`, `alloy`, `qbit`, `seerr`, etc.).
   - `service_namespace`: Origin classification (`container`, `kernel`, `network`, `system`).
   - `deployment_environment`: Environment tag (`production`).

2. **Native OTel Structured Metadata Keys**:
   - `level`: Normalized severity in lowercase (`error`, `warn`, `info`, `debug`, `trace`).
   - `severity_text`: Normalized uppercase severity string (`ERROR`, `WARN`, `INFO`, `DEBUG`).
   - `severity_number`: Canonical OTel severity number (`17` for ERROR, `13` for WARN, `9` for INFO).
   - Infrastructure metadata: `host_name` (`gravedigger`, `opnsense`), `container_name`, `user_unit`, `pid`, `service_instance_id`.

3. **Authoritative LogQL Query Standards**:
   - **Primary Error Triage (Fast Path)**: Filter on structured metadata: `{service_name=~".+"} | level = "error"` or `{service_name="<service>"} | level = "error"`.
   - **Severity Thresholding**: Filter by severity number: `{service_name=~".+"} | severity_number >= 17`.
   - **Multi-Service Volume Aggregation**: `sum by (service_name) (count_over_time({service_name=~".+"} | level = "error" [24h]))`.
   - **Negative Invariant**: The agent is strictly prohibited from running broad, unindexed free-text regexes (e.g. `{service_name=~".+"} |~ "(?i)error"`) across multi-service streams, as this causes false positives from HTML/CSS tags, informational JSON fields, and status strings.

### 3.6 Allowed Capabilities & Runtime Parameters
- **Target Artifacts** (one directory per harness; each is fanned out as a whole directory symlink, so a harness never discovers another harness's definition):
  - Antigravity Harness: `agents/agy/observability.md` (`name: observability`), fanned out to `~/.gemini/config/agents`.
  - Claude Code Harness: `agents/claude/observability.md` (`name: observability`), fanned out to `~/.claude/agents`.
- **Shared Parameters**:
  - **Body**: The prompt body (Sections 1-5 of the agent definition) is identical across harnesses. Only frontmatter differs.
  - **Bound Skills**: `skills: [loki, promql, alloy]` (bare skill names, resolved from each harness's skills fan-out).
  - **MCP Servers**: `grafana` only (excludes foreign MCP servers like `github` or `aws`).
- **Claude Model Rationale**: `sonnet` is the default because the agent must author valid LogQL/PromQL first try, honor seven invariants and a rigid output contract, and apply Default-FAIL reasoning. `haiku` was evaluated in TASK-08 and failed the output contract and numeric accuracy criteria, so `sonnet` remains the default.
- **Per-Harness Parameters**:

  | Parameter | Antigravity (`agents/agy/`) | Claude Code (`agents/claude/`) |
  | :--- | :--- | :--- |
  | Model | `flash` (Gemini 3.8 Flash) | `sonnet` |
  | Execution symmetry | `mainAgent: true`, `subagent: true` | n/a (subagent only) |
  | Shell / write disablement | `commandExecutionPolicy: off` | Allowlist omits `Bash`, `Edit`, `Write` |
  | Native tools | `tools: [view_file]` | `tools: Read, mcp__grafana` |
  | Recursive subagents | `enable_subagent_tools: false` | `Agent` omitted from `tools` |
  | MCP declaration | `mcpServers:` list (`- name: grafana`) with `env` block | `mcpServers:` list of single-key maps (`- grafana:`), launched through `systemd-run --user --pipe` with `RuntimeMaxSec=1h` |
  | Invocation | `invoke_subagent` | `Agent` tool, `subagent_type: observability` |

- **Query Guardrails**: Relies directly on `mcp-grafana` native server limits (`-max-loki-log-limit 100`, `-loki-guardrail-max-range`, `-loki-guardrail-max-bytes`).

### 3.7 Linux-Native Environment Prerequisites & Secret Isolation
Per repository security policy and `OPINIONS.md`, sensitive credentials (such as Grafana service account tokens) must NEVER be committed to Git or embedded in declarative Nix expressions (which risk leaking secrets into the world-readable `/nix/store` or triggering repository push protection):

1. **Host Configuration (`environment.d`)**:
   - Environment variables are managed using the Linux-native `systemd environment.d` specification.
   - Secrets file: `~/.config/environment.d/secrets.conf` with restricted permissions (`chmod 600 ~/.config/environment.d/secrets.conf`).
   - Declared variables:
     ```bash
     GRAFANA_URL="https://grafana.leebo.net"
     GRAFANA_SERVICE_ACCOUNT_TOKEN="glsa_..."
     ```
2. **Session Persistence & Activation**:
   - On systemd-managed Linux environments (including WSL2 Debian with systemd enabled), `systemd-environment-d-generator(8)` reads `~/.config/environment.d/*.conf` at user login.
   - For live application without rebooting or logging out, variables are imported immediately into the active user session manager:
     ```bash
     systemctl --user set-environment GRAFANA_URL="https://grafana.leebo.net" GRAFANA_SERVICE_ACCOUNT_TOKEN="glsa_..."
     ```
3. **Dynamic Harness Expansion**:
   - Agent harness configurations (`~/.gemini/config/mcp_config.json`) and agent definitions (`agents/agy/observability.md`, `agents/claude/observability.md`) dynamically expand `${GRAFANA_URL}` and `${GRAFANA_SERVICE_ACCOUNT_TOKEN}` from the environment at process execution time, preventing any static credential leakage.
   - **Antigravity**: agy resolves `${VAR}` in its MCP `env` block from the systemd user environment (`environment.d`) itself, so it works from any terminal.
   - **Claude Code (verified 2026-09-29)**: Claude Code does not read `environment.d`. It only passes on its own process environment, and WSL terminals do not carry the systemd user environment. Launched from a plain terminal, `mcp-grafana` starts without `GRAFANA_URL`, falls back to `localhost:3000`, stalls on datasource discovery, and Claude's connect times out, leaving the subagent with zero Grafana tools. Agent-frontmatter `env:` blocks with `${VAR}` and the map form of `mcpServers` also fail silently.
   - **Claude Code resolution**: The Claude definition launches the server as a transient user unit, `systemd-run --user --pipe --quiet --collect mcp-grafana`. The unit inherits the systemd user manager environment, so systemd remains the single source of truth. No shell init, no `home.nix` env, and no token in the `claude` process or its shell. Verified with an empty environment in the launching shell: a live `up` query returned 15 series.
   - **Unit lifecycle (verified)**: One unit per subagent invocation. The unit starts when the subagent starts and stops when it finishes (about 5 to 7 seconds for a single query); five subagents produced five start/stop cycles with none left over. A hard kill of the `systemd-run` client (`kill -9`) orphans the unit, so `--property=RuntimeMaxSec=1h` caps any stray server at one hour. A subagent that legitimately runs longer than one hour would lose its Grafana tools.
   - **Model override**: A coordinator may pass a `model` parameter when it invokes the subagent, which overrides the frontmatter `model`. The frontmatter value is a default, not an enforced binding.

---

## 4. Knowledge Evolution & Continuous Improvement

To ensure the specialist agent improves over time as new homelab services, log formats, and metric patterns emerge, the agent follows a continuous codification loop adhering to `~/.dotfiles/OPINIONS.md`:

### 4.1 Separation of Procedural Knowledge
Per Section 2 of `OPINIONS.md`, operational know-how lives in skills, not in agent code or prompt clutter:
- Generic PromQL/LogQL syntax rules remain in `skills/loki/` and `skills/promql/`.
- Homelab-specific OTel contracts and pipeline topology are codified directly in this agent specification.

### 4.2 Datasource Topology Evolution
If Grafana datasources are re-provisioned or migrated (changing their UIDs):
- The authoritative UIDs in Section 3.4 of this specification are updated.
- The corresponding agent definitions in `agents/agy/observability.md` and `agents/claude/observability.md` are updated and fanned out declaratively via `home.nix`.

### 4.3 Incident Feedback Ingestion
When a post-incident analysis in the homelab surfaces an unindexed label or slow query pattern:
1. An issue or backlog item is logged.
2. The recommended query pattern is added to the PromQL/Loki pattern libraries.
3. The specialist immediately utilizes the improved query structure without modifying underlying agent orchestration.

### 4.4 Telemetry Pipeline Feedback Loop (Log Classification Drift)
As homelab services evolve or new applications are onboarded, log formats can drift:
1. **Classification Drift Detection**: If an operator reports a service issue or Prometheus metrics reveal service distress (`up == 0`, restarts, elevated 5xx), but the primary OTel query (`| level = "error"`) returns zero results, the agent executes the Classification Drift Fallback Protocol (Tier 2).
2. **Fallback Analysis**: The agent queries the raw stream using line filters (`|~ "(?i)(error|exception|fail|fatal|panic|traceback)"`) to locate unclassified error lines.
3. **Actionable Pipeline Codification**: When an unparsed error format is found (e.g. marked as `level="info"`), the specialist leverages `skills/alloy/SKILL.md` to author the exact `config.alloy` OTTL transformation statement required to patch Alloy's extraction waterfall, surfacing it in Section 5 of its report for operator action.

---

## 5. Handoff Contract

The handoff contract defines the boundary interface between the Primary Coordinator and the Observability Specialist.

### 5.1 Input Contract (Coordinator -> Specialist)
The primary coordinator invokes the specialist via `invoke_subagent` (Antigravity) or the `Agent` tool with `subagent_type: observability` (Claude Code) using structured parameters:

```markdown
Role: "Observability Specialist"
Prompt:
  - Target Services: <comma-separated service names, regex, or "all">
  - Namespace: <"container" | "kernel" | "network" | "system" | "all"> (Default: "all")
  - Time Range: <e.g., "now-1h", "now-24h", "now-7d"> (Default: "now-24h")
  - Investigation Focus: <"error_spike" | "service_health" | "alert_triage" | "latency">
  - Minimum Severity: <"error" | "warn" | "info"> (Default: "error")
  - Specific Symptoms: <optional user reports, failing endpoints, or expected error strings triggering Tier 2 fallback>
```

### 5.2 Output Contract (Specialist -> Coordinator)
The specialist operates in an ephemeral context and terminates by returning a single markdown message adhering strictly to this schema.

The output contract follows a two-tier visual structure:
1. **Executive Triage Report (Human-First)**: Friendly relative timestamps with UTC context, plain English alert summaries without leaked PromQL syntax, high-density scannable tables, and actionable file/line remediation.
2. **Diagnostic Metadata Drawer (`<details>` block)**: Machine-exact datasource UIDs, ISO-8601 evaluation bounds, and exact PromQL/LogQL query expressions sequestered into a collapsed block at the bottom of the report to preserve context for AI agents without cluttering human review.

```text
STATUS: <HEALTHY | DEGRADED | CRITICAL> [Optional Scope Qualifier]

## Observability Triage Report

- **Overall Status**: `HEALTHY` | `DEGRADED` | `CRITICAL`
- **Time Window Evaluated**: `<e.g. Last 24 Hours (ending HH:MM UTC)>`
- **Datasources Queried**: Loki, Prometheus
- **Fleet Summary**: `<1-2 sentences summarizing fleet health, distinguishing core infrastructure health from localized media or telemetry churn>`

### 1. Active Alerts & Target Health
- **Active Alerts**: `<count> firing across <window>` or `None firing across the last 24h`
- **Scrape Targets**: `<count> / <total> UP` (Host systemd state: `clean` or `<failed count> failed units`)
- **Transient Drops**:
  - `<service list>`: `<duration>s drop at <HH:MM UTC (~Xh ago)> (<reason if known, e.g. scheduled GitOps / container restart>)`
  - *(or `None observed`)*

### 2. Error Spikes & Degraded Services
| Service | Error Count / Rate | Status | Failure Category | Root Cause Summary |
| :--- | :--- | :--- | :--- | :--- |
| `<service_name>` | `<count or req/sec>` | `OK` / `DEGRADED` / `DOWN` | `<e.g. JSONPath Extraction, SQLite Lock>` | `<Concise 1-line root cause summary>` |

### 3. Root Cause Analysis
For each impacted service (suppress raw logs; max 2 representative lines per signature):
#### <Service Name> (<failure_category>)
- **Impact**: `<Direct operational effect on workload or telemetry ingestion>`
- **Root Cause**: `<Technical explanation with exact config or code references>`
- **Representative Excerpt** (Sanitized of tokens/secrets):
  ```text
  <single or max 2-line error log showing root cause>
  ```

### 4. Actionable Findings & Recommended Next Steps
1. `<Specific service, file, or configuration to inspect with exact file and line references>`
2. `<Suggested remediation, drop rule, or operational command for operator/coordinator>`

### 5. Upstream Knowledge & Skill Feedback (Conditional)
*(Included IF AND ONLY IF operational friction occurred: query retry, topology fallback, or log classification drift)*
- **Friction Event**: `<Query Error | Topology Drift | OTel Classification Drift>`
- **Observed Issue**: `<Exact error message, unexpected log snippet, or unhandled format>`
- **Working Resolution**: `<The working query, correct UID, or raw regex that overcame the issue>`
- **Target Codification**: `<Exact path: repos/homelab/config/system/config.alloy, skills/loki/SKILL.md, or spec.md>`
- **Proposed Entry**:
  ```alloy
  // OTTL statement for otelcol.processor.transform.enrich in config.alloy
  merge_maps(log.attributes, ExtractPatterns(log.body, "^(?P<level>FATAL|ERROR|WARN):\\s+"), "upsert") where log.attributes["level"] == nil
  ```

<details>
<summary>Diagnostic Telemetry & Query Metadata</summary>

- **Datasource UIDs**: Loki (`<loki_uid>`), Prometheus (`<prom_uid>`)
- **Evaluation Bounds (UTC ISO-8601)**: `<startTime>` to `<endTime>`
- **PromQL Queries Executed**:
  - `ALERTS{alertstate="firing"}`
  - `up == 1`
  - `node_systemd_unit_state{state="failed"}`
- **LogQL Queries Executed**:
  - `{service_name=~".+"} | level = "error"`
  - `sum by (service_name) (count_over_time({service_name=~".+"} | level = "error" [<window>]))`
</details>
```

---

## 6. EARS Acceptance Criteria

Requirements are formalized using Easy Approach to Requirements Syntax (EARS):

- **AC-01 [Ubiquitous - Output Schema Adherence]**:  
  The specialist agent shall format its final handoff response conforming strictly to the Output Contract in Section 5.2, beginning with the standardized machine-parseable `STATUS:` header, employing human-friendly relative timestamps with UTC context in executive sections, sequestering machine telemetry into the `<details>` metadata drawer, and omitting conversational filler, preamble, and sign-offs.

- **AC-02 [Event-Driven - Raw Log Suppression & Executive Scannability]**:  
  WHEN processing LogQL query results with high line counts, the specialist agent shall aggregate lines into counts and pattern signatures, shall include no more than two representative log lines per distinct error signature in the final report, and shall not leak raw PromQL or LogQL syntax strings into executive summary bullets.

- **AC-03 [State-Driven - Declared Datasource Resolution]**:  
  WHILE querying Loki or Prometheus, the specialist agent shall utilize the declared UIDs in Section 3.4 (`P8E80F9AEF21F6940` for Loki, `PBFA97CFB590B2093` for Prometheus) without issuing pre-flight `list_datasources` calls.

- **AC-04 [Unwanted Behavior - Datasource Drift Recovery]**:  
  IF a query against a declared datasource UID returns an HTTP 404 or `datasource not found` error, THEN the specialist agent shall execute `list_datasources` once to discover the updated UID, log the drift warning in the report header, and re-execute the query.

- **AC-05 [Ubiquitous - OpenTelemetry Query Conformance]**:  
  The specialist agent shall construct all LogQL queries utilizing indexed stream selectors (`{service_name="..."}`, `{service_namespace="..."}`) and native OpenTelemetry structured metadata filters (`| level = "error"` or `| severity_number >= 17`) rather than broad unindexed free-text regexes, and all PromQL queries conforming to `skills/promql/SKILL.md` (range vectors >= 4x scrape interval).

- **AC-06 [Event-Driven - Multi-Service Correlation]**:  
  WHEN the investigation focus is `error_spike` or `alert_triage`, the specialist agent shall query both Prometheus (active alerts and `up` status) and Loki (error pattern counts) to correlate metric anomalies with log signatures before determining the overall status.

- **AC-07 [State-Driven - Default-FAIL Health Verification & Liveness Correlation]**:  
  WHILE evaluating service health, the specialist agent shall require positive evidence (`up == 1` in Prometheus and active log streams in Loki) before declaring a service `HEALTHY`. IF zero error logs are returned, the specialist shall correlate with Prometheus `up` metrics and scrape targets to verify the service is actively running and monitored. IF telemetry is absent or scrape targets are unreachable, THEN the specialist agent shall designate the status as `UNKNOWN / DEGRADED` and explicitly flag missing telemetry.

- **AC-08 [Event-Driven - Friction-Triggered Feedback Bubble-Up]**:  
  WHEN a tool invocation returns an error requiring a retry, WHEN an unscoped query is required due to missing topology, or WHEN a service's log stream requires custom parsing not covered in `skills/loki/SKILL.md`, the specialist agent shall append a structured `Upstream Knowledge & Skill Feedback` block to its report documenting the friction event, the working resolution, the target dotfiles file, and the proposed codification entry.

- **AC-09 [Event-Driven - Classification Drift Fallback & Pipeline Codification]**:  
  WHEN the coordinator provides `Specific Symptoms` or Prometheus metrics signal service degradation, but the primary OTel query (`| level = "error"`) returns zero matching lines, THEN the specialist agent shall execute a Tier 2 classification drift query (`|~ "(?i)(error|exception|fatal|panic)"`). IF unclassified error logs are discovered, THEN the specialist agent shall analyze the raw log structure and append an `Upstream Knowledge & Skill Feedback` block to its report proposing the exact `config.alloy` OTTL transformation statement required to resolve the misclassification in Alloy's extraction waterfall.

- **AC-10 [Ubiquitous - Multi-Harness Definition Parity & Isolation]**:  
  The specialist agent shall be defined once per supported harness under `agents/<harness>/observability.md` with an identical prompt body, shall be fanned out declaratively via `home.nix` such that each harness discovers only its own directory, and the Claude Code definition shall expose no write-capable tools (its `tools` allowlist contains only `Read` and `mcp__grafana`).
