---
name: research
description: Research technology options for homelab, home automation, and infrastructure changes with the operator in the loop, before committing to a design with /sdd. Frames the problem, grounds the research in the existing system design, confirms assumptions before researching, sources findings MCP-first, and synthesizes options as a discussion instead of a verdict. Use when the operator says "research ...", "research lightly ...", "research deeply ...", "what are people using for X", "evaluate X vs Y", "should we replace X", "find options for Y", or is weighing unfamiliar or fast-moving tech before writing a spec. Produces an options brief under research/<topic>/ that feeds /sdd:discovery.
---

# Research

Operator-in-the-loop technology research. It sits between problem framing and `/sdd`:

problem framing -> goals and outcomes -> research current solutions (this skill) -> `/sdd` formalizes the chosen direction

## 1. Why This Skill Exists

Default agent research fails in a predictable way: it leans on training data plus a few web searches, stacks unconfirmed assumptions, narrows to one or two options, and presents the result as settled fact. With no steering along the way, the output misses the actual system and takes several expensive iterations to correct. A short check-in early costs one exchange and prevents most of that.

Every step below exists to keep the operator steering. Work the way you would with a fellow engineer, not the way a consultant delivers a report.

## 2. Policy Anchors

- **Empirical lookup over training memory** (`~/.dotfiles/AGENTS.md`, Section 3): anything described as current, latest, recommended, or maintained needs a dated source.
- **Default lens for weighing options** (`~/.dotfiles/OPINIONS.md`): simplicity, boring technology, minimal dependencies.
- **Voice** (`~/.dotfiles/VOICE.md`): direct and technical, no emojis, ASCII hyphens only.
- **No open-ended swarms**: parallel research subagents run only after the operator approves the research plan (Deep track, step 3).

## 3. Choose the Track

| Trigger | Track |
| :--- | :--- |
| "research lightly ..." | Light |
| "research deeply ..." | Deep |
| "research ..." or any other trigger | Pick the track yourself |

Light fits a bounded question with a small blast radius: choosing a component, checking current best practice, comparing two known tools. Deep fits decisions that change architecture, add a long-lived dependency, touch several services, or cover unfamiliar ground.

Do not announce or justify the track in the response; the shape of the response already shows it, and every Light answer ends with an offer to go deeper. The operator can promote Light to Deep at any checkpoint. Carry forward what is already confirmed instead of restarting.

## 4. Guardrails (Both Tracks)

1. **Ground in the existing system first, cheapest context first.** Research against the actual design, not a generic one. If you do not know where the system lives, ask.
   - **Full configs, up front**: read the complete config for every service or host the question touches (container and quadlet units, compose files, service configs under `config/`). They are short and they are the ground truth.
   - **Evidence for the problem**: when the question claims a problem ("keeps breaking", "fighting us", "too slow"), check incidents (`docs/05_incidents/`), runbooks, and `BACKLOG.md` for a record of it. If nothing records it, say so and ask for the concrete symptom before researching. A question can rest on a problem that does not exist, or on the wrong service; one question here saves researching the wrong thing. When the question claims no problem, do not probe why it was asked.
   - **Larger docs, selectively**: ADRs (`docs/01_decision/`), specifications (`docs/03_reference/`), explanations (`docs/04_explanations/`), and prior work under `research/` cost far more context. Skim headings and read only the sections the question touches.
   In check-ins, cite each repo path inline where you use it. Light track answers and the options brief end with a **Local references** list (path plus one line on why it matters), since those are what the operator keeps.
2. **Make assumptions visible.** State the assumptions that shape the research (constraints, scale, tools that must stay, what "good" means) where the operator will see them before relying on the result. On the Deep track they are confirmed before research starts; on the Light track they lead the answer.
3. **Source order.** MCP servers first when one covers the domain (AWS documentation, GitHub, Grafana, and any others available). Then local clones, vendor docs, release notes, and changelogs. Community sources (forums, Reddit, blogs) last, labeled as community. Check publish dates; in fast-moving spaces anything older than about a year is suspect.
4. **Clone repos instead of fetching pieces.** When an open source project is a serious candidate, or its code or issues need more than a glance, ask the operator to clone it to `~/repos/<name>` and investigate locally with grep and file reads. Do not pull files one at a time through web fetches or the API.
5. **Handle pages that will not fetch.** If a fetch returns truncated or incomplete content, download the full HTML once with `curl -sL "<url>" -o "${TMPDIR:-/tmp}/research-<topic>/<name>.html"` and parse the saved file locally. If the content is rendered client-side or blocked, stop retrying and ask the operator to paste it into a file (for example `${TMPDIR:-/tmp}/research-<topic>/<name>.md`) and give you the path.
6. **Present findings as a discussion, not a verdict.** Tag each claim with confidence (confirmed, likely, speculative) and its source. Offer a lean with visible reasoning; the operator decides. Keep options alive until the operator rules them out.
7. **Surface likely backlog additions.** Out-of-scope problems that need a change (a secret committed to git, a service running without a declared config) and high-value documentation gaps (an incident with no writeup, a service with no explanation doc, broken links) go into the next check-in or answer under **Likely backlog additions**: at most five items, one line each, highest value first. Ask which to add to `BACKLOG.md`, then continue on the research question. Do not fix or research them unasked. If nothing outside the current scope needs a change, omit the section entirely.

## 5. Light Track

Light questions get answered in one turn. Grounding in the repo is what makes the answer useful; an extra round trip usually is not.

1. **Ground** (Guardrail 1): full configs for the affected services and only the design context the question touches.
2. **Stop first only if one of these holds**; otherwise go straight to step 3:
   - The question claims a problem that nothing in the repo records
   - An assumption would change the answer and the repo cannot confirm it
   - You need the operator to clone a repo or paste a page (Guardrails 4 and 5)
   When you stop, send one message covering the blocker, what grounding showed, and any likely backlog additions (Guardrail 7), then wait.
3. **Research inline**: no subagents. Follow the sourcing and honesty rules in `agents/researcher.md`.
4. **Answer**: open with the assumptions you made ("Assumed: ... - tell me if any are wrong"), then the synthesis (Section 7), then any likely backlog additions (Guardrail 7), then **Local references**. Close by asking how to proceed: done, go deeper (promote to Deep), or write a brief (Section 8). Do not ask what prompted the question; if the motivation would change the answer, state your assumption about it instead.

The Light track writes no files unless the operator asks for a brief.

## 6. Deep Track

State lives under `research/<topic>/` at the root of the repo that owns the system, using a kebab-case topic (for example `research/zigbee-coordinator/`). If that directory already exists, read its notes and brief and resume where they stop instead of restarting.

1. **Ground in the existing system** (Guardrail 1) before asking anything, so the first questions are informed by the real design.
2. **Frame the problem.** Open with a short playback of the current design and where the change lands, including any missing evidence for the problem and any likely backlog additions (Guardrail 7). Hold hypotheses and likely causes until the operator has answered; offered before the questions, they anchor the answers. Then interview in short rounds, a few questions at a time:
   - Problem: the concrete symptom, where and when it was observed, and why it matters now
   - Goals and outcomes: what the observable end state looks like
   - Constraints: host, runtime, budget, hardware, security posture, tools that must stay
   - Non-goals: what this research will not decide
3. **Plan the research and get approval.** Present in one message:
   - Confirmed assumptions
   - 2-4 research facets, each with key questions and planned sources. Split by facet (for example candidate landscape, integration with our stack, operational burden, security), not one researcher per option, so every option is compared on the same axes.
   - Repos to clone and pages likely to need a manual paste
   Research starts only after the operator approves or edits the plan.
4. **Dispatch.** If the harness can spawn subagents, run one per facet in parallel. Otherwise work through the facets yourself, one at a time. Each research unit reads `agents/researcher.md` first and receives the facet, key questions, confirmed assumptions, a short summary of the existing design, and its output path `research/<topic>/notes/<facet>.md`.
5. **Checkpoint.** Read the notes and present an interim synthesis (Section 7). Research units do not downselect; that happens here, with the operator. Run further rounds only when the operator asks, scoped to the gaps they choose.
6. **Converge.** Repeat step 5 until the operator picks a direction or decides none of the options fit.
7. **Write the brief** (Section 8).

## 7. Synthesis Format

Keep it conversational and short enough to answer. Every factual claim carries a confidence tag and a source, option summaries included; assumptions, questions, and backlog items do not.

- **What I found**: each live option in 2-4 lines, with claims tagged by confidence and source
- **Fit with our system**: how each option lands against the constraints and existing design
- **Unsure about**: gaps, conflicting sources, blocked pages, unverified claims
- **Current lean**: one option (or "none yet") with the reasoning, labeled as a lean, not a decision
- **Questions for you**: what would change the picture

Skip polished-report structure (title, executive summary, narrative sections). Polish makes an unfinished conclusion look settled and discourages pushback.

## 8. Options Brief and Handoff to /sdd

Once the operator has converged, write `research/<topic>/options-brief.md` from `assets/options-brief-template.md`. Record the decision as the operator's, including rejected options and why they were rejected, so `/sdd` does not re-litigate them.

Hand off by suggesting `/sdd:discovery <feature>` (or `/sdd:quick <feature>` for small, well-scoped work) with the brief as input.

## 9. Reference and Asset Index

- `agents/researcher.md`: sourcing, honesty, and output rules for each research unit. Read it before researching on either track, whether a subagent does the work or you do.
- `assets/options-brief-template.md`: structure for the handoff brief.
