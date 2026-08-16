---
name: skill-intake
description: Ingest, evaluate, sanitize, and adapt open-source or upstream skills for use in this dotfiles repo. Use when importing a skill from an external source (GitHub repos, Anthropic skill library, AWS, Terraform, or any public skill repository), adapting an existing skill to local conventions, evaluating whether an upstream skill is worth adopting, or building a new domain skill from scratch. Triggers on requests like "import this skill", "adapt this skill", "evaluate this upstream skill", "customize this skill for our setup", "add a skill from X repo", "build a skill for X", or "create a skill that does X".
---

# Skill Intake

A skill for evaluating, ingesting, sanitizing, and adapting upstream open-source skills - and for creating new skills from scratch - for use in this dotfiles repo.

The process has two tracks depending on the origin of the skill:

Lightweight Track (for open-source/upstream skills):
- Evaluate whether the upstream skill is worth adopting
- Sanitize to meet local conventions (strip emojis and em dashes)
- Patch the skill to delete conflicting hardcoded policies
- Insert pointers tying the skill to our centralized dotfiles governance
- Wire the skill into the harness

Heavy Track (for defining new custom skills from scratch):
- Interview the operator to understand requirements
- Write the new skill
- Sanitize to meet local conventions
- Create test cases, run evals, review results with the operator
- Iterate until the operator is satisfied
- Wire the skill into the harness

Your job is to figure out where the operator is in this process and help them move forward. If they bring an upstream skill, start with evaluation and use the Lightweight Track. If they describe a new workflow to capture, start with intent capture and use the Heavy Track. If they already have a draft, go straight to eval and iteration.

---

## Step 0: Evaluate the Upstream Skill (skip if creating from scratch)

Before touching anything, read and assess the upstream skill. The goal is to determine if it provides genuine procedural depth or is superficial prompt text.

Assess against these criteria:

**Worth adopting if it has:**
- Multi-step runbooks with concrete tool invocations (CLI commands, API calls, GraphQL mutations)
- Reference subdirectories that load specialist context on demand (progressive disclosure)
- Scripts that bundle repetitive or deterministic work
- Coverage of non-obvious edge cases and failure modes

**Not worth adopting if it:**
- Duplicates what the agent handles natively without guidance
- Is entirely generic advice with no executable specifics
- Requires proprietary tooling unavailable in Antigravity or Kiro

Report findings to the operator before proceeding. Include:
- What the skill covers and how deeply
- The directory structure and whether it uses progressive disclosure
- Dependencies (MCP servers, CLI tools, auth scopes required)
- A clear recommendation: adopt as-is, adopt with adaptation, or skip

---

## Capture Intent

Start by understanding what the operator needs. If there is an existing conversation workflow to capture, extract answers from it first - tools used, sequence of steps, corrections made, input/output formats observed. The operator may need to fill gaps, and should confirm before you proceed.

1. What should this skill enable the agent to do?
2. When should this skill trigger? What operator phrases or contexts?
3. What is the expected output format?
4. Should test cases be created to verify the skill works? Skills with objectively verifiable outputs (file transforms, data extraction, fixed CLI sequences) benefit from test cases. Skills with subjective outputs often do not. Suggest the appropriate default based on the skill type, but let the operator decide.

---

## Interview and Research

Proactively ask about edge cases, input/output formats, example files, success criteria, and dependencies. Wait to write test prompts until this is clear.

Check available MCPs - if useful for research (searching docs, finding similar skills, looking up best practices), research in parallel via subagents. Come prepared to reduce burden on the operator.

---

## Sanitization (apply before adapting any upstream skill)

Apply these fixes to all files in the skill directory:

**Mandatory formatting corrections:**
- Convert all unicode em dashes to plain ASCII hyphens (`-`)
- Remove all emojis from SKILL.md and any reference markdown files
- Replace sycophantic or filler phrasing with direct, technical language - see `~/.dotfiles/VOICE.md`
- Remove audience-calibration sections not relevant to technical operators

**Structural checks:**
- Confirm SKILL.md is under 500 lines. If over, identify what should move into `references/`
- Confirm the frontmatter `description` covers both what the skill does and when to invoke it
- Confirm any `references/` files are clearly pointed to from SKILL.md with guidance on when to read them

Run `./tests/validate.sh` from `~/repos/dotfiles` after sanitization. It must pass before proceeding. Em dashes in any file under `skills/` will cause a failure.

---

## Write the SKILL.md

Based on the operator interview (and upstream skill review if applicable), fill in these components:

- **name**: Skill identifier
- **description**: When to trigger and what it does. This is the primary triggering mechanism - include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. Claude has a tendency to undertrigger skills, so make descriptions specific and slightly forward-leaning. Instead of "How to manage GitHub issues", write "How to manage GitHub issues using the gh CLI and MCP. Use when creating issues, updating labels, posting daily updates, or verifying issue closure."
- **the rest of the skill**

### Anatomy of a Skill

```
skill-name/
- SKILL.md (required)
  - YAML frontmatter (name, description required)
  - Markdown instructions
- Bundled Resources (optional)
  - scripts/    - Executable code for deterministic/repetitive tasks
  - references/ - Docs loaded into context as needed
  - assets/     - Files used in output (templates, icons, fonts)
  - evals/      - Test cases
```

### Progressive Disclosure

Skills use a three-level loading system:
1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - In context whenever skill triggers (<500 lines)
3. **Bundled resources** - Loaded or executed as needed

- Keep SKILL.md under 500 lines; if approaching this limit, extract into `references/` with clear pointers
- Reference files clearly from SKILL.md with guidance on when to read them
- For large reference files (>300 lines), include a table of contents

**Domain organization**: When a skill supports multiple domains, organize by variant:
```
cloud-deploy/
- SKILL.md (workflow + selection logic)
- references/
  - aws.md
  - gcp.md
  - azure.md
```
The agent reads only the relevant reference file.

### Writing Patterns

Use the imperative form in instructions.

Explain why things matter rather than relying on heavy-handed MUSTs. Use theory of mind. Start with a draft, then read it fresh and improve it.

**Defining output formats:**
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern:**
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

---

## Test Cases

After writing the skill draft, come up with 2-3 realistic test prompts - the kind of thing a real operator would actually say. Share them: "Here are a few test cases I'd like to try. Do these look right, or do you want to add more?" Then run them.

Save test cases to `evals/evals.json`. Don't write assertions yet - just the prompts. Draft assertions while runs are in progress.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "Operator's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema including the `assertions` field.

---

## Running and Evaluating Test Cases

This section is one continuous sequence - do not stop partway through.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Organize by iteration (`iteration-1/`, `iteration-2/`, etc.) and within that, each test case gets a directory. Don't create all directories upfront - create them as you go.

### Step 1: Spawn all runs in the same turn

For each test case, spawn two subagents in the same turn - one with the skill, one without. Do not run with-skill first then come back for baselines. Launch everything at once.

**With-skill run:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the operator cares about>
```

**Baseline run** (same prompt, no skill path, save to `without_skill/outputs/`).
- When improving an existing skill: snapshot the old version first (`cp -r <skill-path> <workspace>/skill-snapshot/`), point baseline at the snapshot.

Write an `eval_metadata.json` for each test case (assertions can be empty for now). Give each eval a descriptive name based on what it tests:

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The operator's task prompt",
  "assertions": []
}
```

### Step 2: Draft assertions while runs are in progress

Don't wait - use this time to draft quantitative assertions for each test case and explain them to the operator.

Good assertions are objectively verifiable and have descriptive names that read clearly in the benchmark viewer. Subjective skills are better evaluated qualitatively - don't force assertions onto things that need human judgment.

Update `eval_metadata.json` and `evals/evals.json` with assertions once drafted.

### Step 3: Capture timing data as runs complete

When each subagent task completes, save timing immediately to `timing.json` in the run directory:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

This data comes through the task notification and is not persisted elsewhere. Process each notification as it arrives.

### Step 4: Grade, aggregate, and launch the viewer

Once all runs are done:

1. **Grade each run** - spawn a grader subagent that reads `agents/grader.md` and evaluates each assertion against the outputs. Save results to `grading.json` in each run directory. Use exact field names: `text`, `passed`, `evidence` (the viewer depends on these).

2. **Aggregate into benchmark** - run from the skill-intake directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   This produces `benchmark.json` and `benchmark.md` with pass rate, time, and tokens per configuration with mean and stddev.

3. **Analyst pass** - read the benchmark data and surface patterns. See `agents/analyzer.md` for what to look for: non-discriminating assertions, high-variance evals, time/token tradeoffs.

4. **Launch the viewer:**
   ```bash
   nohup python <skill-intake-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   Generate the eval viewer BEFORE evaluating inputs yourself. Get results in front of the operator as soon as possible.

   If no browser/display is available, use `--static <output_path>` to write a standalone HTML file.

5. Tell the operator: "I've opened the results in your browser. The 'Outputs' tab lets you click through each test case and leave feedback, the 'Benchmark' tab shows the quantitative comparison. Come back when you're done."

### Step 5: Read the feedback

When the operator says they're done, read `feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the output is missing X", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback means the operator thought it was fine. Focus improvements on test cases where the operator had specific complaints.

Kill the viewer when done: `kill $VIEWER_PID 2>/dev/null`

---

## Improving the Skill

### How to think about improvements

1. **Generalize from feedback.** You and the operator are iterating on a few examples for speed. The skill must work across many different prompts, not just these examples. Avoid narrow, overfitted changes. If there is a stubborn issue, try different metaphors or patterns rather than adding rigid constraints.

2. **Keep the prompt lean.** Remove things that are not pulling their weight. Read transcripts, not just final outputs - if the skill causes the agent to waste time on unproductive steps, cut the parts driving that behavior.

3. **Explain the why.** Try hard to explain the reasoning behind instructions rather than issuing opaque commands. If you find yourself writing ALWAYS or NEVER in all caps, treat that as a flag - try to reframe and explain why the constraint matters instead.

4. **Look for repeated work across test cases.** If multiple test case transcripts show the agent independently writing the same helper script, that script belongs in `scripts/`. Write it once, bundle it, and tell the skill to use it.

### The iteration loop

After improving the skill:
1. Apply improvements
2. Rerun all test cases into a new `iteration-<N+1>/` directory, including baselines
3. Launch the reviewer with `--previous-workspace` pointing at the previous iteration
4. Wait for operator review
5. Read new feedback, improve, repeat

Keep going until:
- The operator says they're happy
- Feedback is empty across all test cases
- No meaningful progress between iterations

---

## Advanced: Blind Comparison

For rigorous comparison between two skill versions (e.g., "is the new version actually better?"), use the blind comparison system. Read `agents/comparator.md` and `agents/analyzer.md`. An independent agent evaluates both outputs without knowing which is which, then analyzes why the winner won.

This is optional and most operators won't need it. The human review loop is usually sufficient.

---

## Description Optimization

The description field is the primary mechanism determining whether the agent invokes a skill. After creating or improving a skill, offer to optimize it for better triggering accuracy.

### Step 1: Generate trigger eval queries

Create 20 eval queries - a mix of should-trigger and should-not-trigger. Save as JSON:

```json
[
  {"query": "the operator prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

Queries must be realistic and specific - include file paths, personal context, column names, company names, URLs, and a bit of backstory. Some should be lowercase, contain abbreviations, or use casual speech. Focus on edge cases rather than clear-cut examples.

Bad: `"Format this data"`, `"Extract text from PDF"`

Good: `"ok so I need to update the status on issue 142 in the platform-auth repo to in-progress and post a daily standup comment, the issue was opened last sprint"`

For should-trigger queries (8-10): different phrasings of the same intent - formal and casual, explicit and implicit, common and uncommon use cases.

For should-not-trigger queries (8-10): near-misses that share keywords but need something different. These are the most valuable - don't make them obviously irrelevant.

### Step 2: Review with operator

Present the eval set using the HTML template:
1. Read `assets/eval_review.html`
2. Replace `__EVAL_DATA_PLACEHOLDER__` with the JSON array, `__SKILL_NAME_PLACEHOLDER__` with the skill name, `__SKILL_DESCRIPTION_PLACEHOLDER__` with the current description
3. Write to a temp file and open it: `open /tmp/eval_review_<skill-name>.html`
4. The operator can edit queries, toggle should-trigger, add/remove entries, then click "Export Eval Set"
5. The file downloads to `~/Downloads/eval_set.json`

### Step 3: Run the optimization loop

Note: the optimization loop (`scripts/run_loop.py`) calls `claude -p` as a subprocess, which requires the Claude CLI and is not available in Antigravity or Kiro. Skip this step and optimize the description manually based on the trigger eval results if running in those harnesses.

If using Claude Code: save the eval set to the workspace, then:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

The script splits evals 60/40 train/test, evaluates the current description (running each query 3 times), proposes improvements, and iterates up to 5 times. It selects the best description by test score to avoid overfitting.

### Step 4: Apply the result

Take the best description and update the skill's SKILL.md frontmatter. Show the operator before/after and report the scores.

---

## Wire into Harness

Once the skill passes operator review and `./tests/validate.sh` passes:

1. Confirm the skill is placed under `~/repos/dotfiles/skills/<domain>/<skill-name>/SKILL.md`
2. Check whether `~/.gemini/config/skills` and `~/.kiro/skills` are already symlinked to `~/repos/dotfiles/skills/`. If they are, the new skill is immediately discoverable.
3. If the symlinks do not yet exist, add them to `home.nix` and run `./rebuild.sh`:

```nix
home.file.".gemini/config/skills".source =
  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/skills";

home.file.".kiro/skills".source =
  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/skills";
```

4. Run `./tests/validate.sh` one final time. It must pass cleanly before the skill is considered complete.

---

## Reference files

The `agents/` directory contains instructions for specialized subagents. Read them when spawning the relevant subagent.

- `agents/grader.md` - How to evaluate assertions against outputs
- `agents/comparator.md` - How to do blind A/B comparison between two outputs
- `agents/analyzer.md` - How to analyze why one version beat another

The `references/` directory has additional documentation:
- `references/schemas.md` - JSON structures for evals.json, grading.json, benchmark.json

---

Core loop for reference:

- Evaluate the upstream skill (or define a new skill from scratch)
- Draft or adapt the skill
- Sanitize: em dashes, emojis, voice alignment, validate.sh gate
- Run test cases with the skill (and baseline without)
- Generate the eval viewer - get results in front of the operator before making revisions yourself
- Run quantitative evals and grade
- Repeat until the operator is satisfied
- Wire into harness, confirm validate.sh passes
