# Dotfiles Backlog

## Port Centralized Command Guardrails to Kiro
* **Priority**: Low
* **Context**: We successfully implemented the Centralized Router Pattern (`guard-command.sh`) for Antigravity using `hooks.json`. This enforces Explicit Intent Signaling (e.g., `AGENT_SKILL=git-commit`) so agents don't run rogue, destructive raw bash commands. We need to port this same guardrail pattern to Kiro.

### Technical Findings & Implementation Steps
Kiro's IPC architecture is fundamentally different from Antigravity's:

1. **Schema & Trigger**: Kiro supports a `PreToolUse` trigger that can match the `run_command` tool. However, the configuration must be a `v1` schema file placed at `~/.kiro/hooks/<id>.json`.
2. **Control Flow (Exit Codes vs JSON)**: Antigravity expects JSON printed to `STDOUT` (e.g., `{ "decision": "deny" }`). Kiro completely ignores JSON. To deny a tool execution in Kiro, the hook must print the error reason to `STDERR` and return `Exit Code 2`.
3. **Payload Structure**: The JSON payload Kiro passes to `STDIN` is undocumented. Before writing the Kiro script, we must dump the `STDIN` payload to a text file to see how to properly extract the bash command string using `jq`.

**Action Items**:
- [ ] Dump and analyze Kiro's `PreToolUse` `STDIN` payload.
- [ ] Create `bin/guard-command-kiro.sh` to parse the payload and use Exit Code 2 for denials.
- [ ] Create `.kiro/hooks/command-router.json` with the `v1` schema pointing to the script.
- [ ] Fan-out the Kiro JSON hook configuration via `home.nix`.
