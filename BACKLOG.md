# Dotfiles Backlog

## Port Centralized Command Guardrails to Claude Code
* **Priority**: Low
* **Context**: `hooks.json` + `bin/guard-command.sh` implement the Centralized Router Pattern for Antigravity. Claude Code supports the same `PreToolUse` hook concept but with a materially different contract, and its global `settings.json` mixes live app state (model, theme, effort level) with declarative config, which is why `home.nix` currently leaves it unmanaged (see `README.md`).

### Technical Findings & Implementation Steps
1. **No standalone hooks.json**: Claude Code only reads hooks from the `"hooks"` key inline in `settings.json` (global: `~/.claude/settings.json`, project: `.claude/settings.json`). There is no separate hooks file to symlink the way `~/.gemini/config/hooks.json` is.
2. **Stdin payload shape** (differs from Antigravity's `.toolCall.args.CommandLine`): for a `PreToolUse` hook matching the `Bash` tool, stdin JSON is `{"session_id": "...", "cwd": "...", "hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "..."}}`. Extract the command with `jq -r '.tool_input.command'`.
3. **Blocking contract** (differs from Antigravity's `{"decision": "deny", "reason": "..."}`): print to stdout with exit 0:
   ```json
   {
     "hookSpecificOutput": {
       "hookEventName": "PreToolUse",
       "permissionDecision": "deny",
       "permissionDecisionReason": "..."
     }
   }
   ```
   (`permissionDecision` values: `allow` / `deny` / `ask`.) Exit code 2 with a reason on stderr also blocks, as a simpler alternative.
4. **settings.json ownership blocker**: `~/.claude/settings.json` is written to directly by the app (e.g. `/model`, `/effort` persist there), so it cannot be a straight `mkOutOfStoreSymlink` target like `hooks.json` is for Antigravity without clobbering live state. Needs a merge step (e.g. a `home.activation` script that runs `jq -s '.[0] * .[1]'` to merge only the `hooks` key from a dotfiles-owned fragment into the live file) rather than full-file ownership.

**Action Items**:
- [ ] Create `bin/guard-command-claude.sh` implementing the `tool_input.command` extraction and `hookSpecificOutput.permissionDecision` output above.
- [ ] Add a `home.activation` script in `home.nix` that idempotently merges a dotfiles-owned hooks fragment into `~/.claude/settings.json` via `jq`, without touching `model`/`theme`/`modelSettings`.
- [ ] Validate the guardrail actually blocks a raw `git commit` in a live Claude Code session before considering this done.

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

## Evaluate Global Context Mounts for Agent Workspaces
* **Priority**: Low
* **Context**: When agents manually lookup skills using `view_file` on `~/.gemini/antigravity-cli/skills/...`, the sandbox resolves the symlink to `~/repos/dotfiles` and flags it as an out-of-workspace read, burying the operator in approval requests.
* **Action Item**: Investigate if Antigravity/Kiro support configuring `~/repos/dotfiles` as a globally trusted read-only mount to prevent these sandbox interruptions.

## Evaluate Nix Store Immutability for Skills
* **Priority**: Low
* **Context**: We currently use `mkOutOfStoreSymlink` in `home.nix` for skills to allow live-editing without a rebuild. However, this triggers symlink sandbox warnings. If we switch to standard Nix store copying (which places skills in the immutable `/nix/store`), security sandboxes typically whitelist these paths automatically.
* **Action Item**: Once the rate of skill creation slows down, weigh the tradeoff of requiring a `rebuild.sh` for skill updates vs. gaining native sandbox whitelisting.

## Codify Skill Lifecycle to Prevent Frankenstein Bloat
* **Priority**: Medium
* **Context**: Iteratively patching agent skills on-the-fly during domain/project work leads to prompt creep, conflicting instructions, and bloated "Frankenstein" skill files. We need to formally codify a lifecycle process that enforces strict separation between procedural tool execution (the "How" in `skills/`) and architectural policy/heuristics (the "What & Why" in central dotfiles rules or project research docs), coordinating cross-project skill improvements through a structured batch-refinement queue.
* **Action Items**:
  - [ ] Document the 3-tier skill evolution model in `OPINIONS.md`: (1) Project-local discovery in `research/`, (2) Strict boundary between tool execution runbooks and domain design heuristics, (3) Central queueing in `BACKLOG.md` for curated batch refinement.
  - [ ] Define strict structural bounds for `SKILL.md` files (100-150 lines target, procedural CLI/API commands only, fanning out large schemas to `references/`).
  - [ ] Author guidelines detailing when an operational discovery warrants an `OPINIONS.md` update, a skill reference addition (`references/`), or a project-local runbook.

## Native macOS Spotlight Indexing for Nix Applications
* **Priority**: Medium
* **Context**: Applications installed through `nix-darwin` via `environment.systemPackages` (such as `WezTerm.app`) are placed into `/Applications/Nix Apps/` rather than the top-level `/Applications/` directory. macOS Spotlight and Finder search do not index this subfolder by default due to normalized Nix store timestamps (epoch 0), read-only permissions, and Spotlight skipping non-standard directory trees to prevent recursion. Consequently, WezTerm does not appear in Spotlight searches (`Cmd + Space`) or in Finder's primary Applications folder view.
* **Technical Findings & Solutions**:
  1. **`mkalias` Activation Script**: Use `pkgs.mkalias` in `darwin.nix` within `system.activationScripts.applications` to generate native macOS aliases in `/Applications/` or `~/Applications/`. Unlike Unix symlinks, macOS aliases are natively indexed by Spotlight and launch directly from Finder.
  2. **`mac-app-util` Flake**: Integrate the community `mac-app-util` flake, which generates lightweight trampoline `.app` bundles that forward execution to the Nix store while remaining discoverable in Spotlight and stable across Dock updates.
* **Action Items**:
  - [ ] Evaluate `mkalias` vs `mac-app-util` for native Spotlight discovery without unnecessary build complexity.
  - [ ] Implement an activation script in `darwin.nix` to link Nix-managed `.app` bundles to `/Applications/` or `~/Applications/`.
  - [ ] Validate Spotlight indexing and Launch Services registration on fresh rebuilds.


