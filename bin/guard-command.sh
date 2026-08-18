#!/usr/bin/env bash
# Centralized command guardrail for agent workflows

PAYLOAD=$(cat)
COMMAND=$(echo "$PAYLOAD" | jq -r '.toolCall.args.CommandLine')

case "$COMMAND" in
  *"git commit"*)
    if [[ "$COMMAND" != *"AGENT_SKILL=git-commit"* ]]; then
      cat <<EOF
{
  "decision": "deny",
  "reason": "Direct git commits are prohibited. You MUST use the authorized 'git-commit' skill."
}
EOF
      exit 0
    fi
    ;;
  *"gh api "*"/issues"* | *"gh issue "*)
    # Match POST/PATCH operations roughly, or just require handshake for all issue ops
    if [[ "$COMMAND" == *"-X POST"* ]] || [[ "$COMMAND" == *"-X PATCH"* ]] || [[ "$COMMAND" == *"gh issue create"* ]] || [[ "$COMMAND" == *"gh issue edit"* ]]; then
      if [[ "$COMMAND" != *"AGENT_SKILL=github-issues"* ]]; then
        cat <<EOF
{
  "decision": "deny",
  "reason": "Direct GitHub issue modification is prohibited. You MUST use the authorized 'github-issues' skill."
}
EOF
        exit 0
      fi
    fi
    ;;
esac

# If we fall through, the command is allowed
cat <<EOF
{ "decision": "allow" }
EOF
