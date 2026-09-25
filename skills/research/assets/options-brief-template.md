# Options Brief: {{TOPIC}}

- **Date**: {{DATE}}
- **Track**: Light | Deep
- **Status**: Draft | Converged
- **Notes**: `research/{{TOPIC}}/notes/` (Deep track only)

## 1. Problem and Goals
- **Problem**: {{PROBLEM_DESCRIPTION}}
- **Why Now**: {{TRIGGER_FOR_CHANGE}}
- **Desired Outcome**: {{OBSERVABLE_END_STATE}}
- **Non-Goals**: {{WHAT_THIS_RESEARCH_DOES_NOT_DECIDE}}

## 2. Existing System Context
- **Where the Change Lands**: {{AFFECTED_SERVICES_HOSTS_DATASETS}}
- **Constraints**: {{HOST_RUNTIME_BUDGET_SECURITY_CONSTRAINTS}}

## 3. Confirmed Assumptions
- {{ASSUMPTION}} - confirmed | corrected by operator: {{CORRECTION}}

## 4. Options Evaluated

### Option A: {{OPTION_A_NAME}}
- **Summary**: {{WHAT_IT_IS}}
- **Fit With Our System**: {{HOW_IT_LANDS_AGAINST_CONSTRAINTS_AND_DESIGN}}
- **Pros**: {{PROS}}
- **Cons**: {{CONS}}
- **Maturity and Maintenance**: {{LAST_RELEASE_CADENCE_PROJECT_HEALTH}}
- **Confidence**: {{CONFIRMED_LIKELY_SPECULATIVE_AND_WHY}}
- **Key Sources**: {{LINKS_WITH_DATES}}

### Option B: {{OPTION_B_NAME}}
- **Summary**: {{WHAT_IT_IS}}
- **Fit With Our System**: {{HOW_IT_LANDS_AGAINST_CONSTRAINTS_AND_DESIGN}}
- **Pros**: {{PROS}}
- **Cons**: {{CONS}}
- **Maturity and Maintenance**: {{LAST_RELEASE_CADENCE_PROJECT_HEALTH}}
- **Confidence**: {{CONFIRMED_LIKELY_SPECULATIVE_AND_WHY}}
- **Key Sources**: {{LINKS_WITH_DATES}}

## 5. Ruled Out
- **{{OPTION_NAME}}**: {{REASON}} (ruled out by: operator | constraint)

## 6. Decision
- **Chosen Direction**: {{OPTION_OR_NONE_FIT}}
- **Decided By**: Operator, {{DATE}}
- **Rationale**: {{WHY_THIS_DIRECTION}}
- **Trade-offs Accepted**: {{ACCEPTED_COMPROMISES}}

## 7. Open Questions and Known Gaps
- {{OPEN_QUESTION}}

## 8. Local References
- `{{REPO_PATH}}` - {{WHY_IT_MATTERS}}

## 9. Next Action
Run `/sdd:discovery {{FEATURE_NAME}}` (or `/sdd:quick {{FEATURE_NAME}}` for small, well-scoped work) with this brief as input.
