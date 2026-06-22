# Worker adapters — exact invocation templates

Copy-paste recipes for dispatching each worker uniformly. Read this when you are
actually about to fan out. The Conductor (the running Claude) writes each worker's
focused prompt, runs these via Bash, and reads the captured output files.

All artifacts go in a throwaway run dir so the repo stays clean. `$SKILL` must
point at this skill's own directory (the `glm.sh` adapter lives under it):

```bash
SKILL="${SKILL:-$HOME/.claude/skills/cross-model-orchestration}"  # this skill's dir
RUN="$(mktemp -d -t cmo-XXXX)"        # plans, reviews, verdicts
REPO="$(git rev-parse --show-toplevel)"
echo "SKILL=$SKILL  RUN=$RUN  REPO=$REPO"
```

Probe the pool once and degrade gracefully (missing GLM = still codex+claude):

```bash
command -v codex >/dev/null && echo "codex: ok"
command -v claude >/dev/null && echo "claude: ok"
# GLM: `--check` reports config without invoking any model (exit 3 = unconfigured).
"$SKILL/scripts/glm.sh" --check || echo "  -> drop glm from the pool, note reduced diversity"
```

> Diversity note: the two genuinely **cross-family** workers are `codex` (GPT) and
> `glm` (GLM). `claude` as a worker is the *same family* as the Conductor — useful
> as a recursive/self worker (test-time scaling) or with a different tier (opus vs
> sonnet) for a little extra spread, but it is not where the diversity payoff lives.

---

## codex (GPT family)

**Plan / reason (read-only — cannot touch files):**

```bash
codex exec \
  --skip-git-repo-check \
  -s read-only \
  -C "$REPO" \
  ${CODEX_MODEL:+-m "$CODEX_MODEL"} \
  -o "$RUN/plan-codex.md" \
  - <<'PROMPT'
<the focused prompt the Conductor wrote for codex>
PROMPT
```

`-o` writes only the final message (clean to parse). Add `--output-schema FILE`
to force a JSON shape (good for verifier verdicts — see below). The heredoc above
is interchangeable with supplying the prompt from a file — `- < "$RUN/prompt-codex.txt"`
— which matches the framing step where the Conductor writes one prompt file per worker.
Use the file form throughout for consistency with the claude/glm adapters.

**Implement (writes files — always inside an isolated worktree):**

```bash
codex exec \
  --skip-git-repo-check \
  -s workspace-write \
  -C "$WT" \
  -o "$RUN/impl-codex.md" \
  - <<'PROMPT'
<implement task X. Edit files. Run the build/tests. Report what you changed.>
PROMPT
```

---

## claude (Claude family — self / recursive worker)

**Plan (read-only via plan mode):**

```bash
( cd "$REPO" && claude -p "$(cat "$RUN/prompt-claude.txt")" \
    --model "${CLAUDE_WORKER_MODEL:-claude-opus-4-8}" \
    --permission-mode plan ) > "$RUN/plan-claude.md"
```

**Implement (inside an isolated worktree):**

```bash
( cd "$WT" && claude -p "$(cat "$RUN/prompt-claude.txt")" \
    --model "${CLAUDE_WORKER_MODEL:-claude-opus-4-8}" \
    --permission-mode acceptEdits ) > "$RUN/impl-claude.md"
```

Use `--output-format json` if you want structured metadata; default text is fine
for plans/diffs. Prefer a *different* model tier than the Conductor for spread.

---

## glm (GLM family) — via `scripts/glm.sh`

The adapter normalizes GLM to the same stdin->stdout shape. It uses your `GLM_CMD`
(e.g. ZCode) if set, else GLM's Anthropic-compatible endpoint via the claude CLI
with `GLM_API_KEY`. See the script header for env vars.

```bash
GLM="$SKILL/scripts/glm.sh"

# Plan (read-only):
( cd "$REPO" && "$GLM" "$(cat "$RUN/prompt-glm.txt")" --permission-mode plan ) \
    > "$RUN/plan-glm.md" || echo "glm unavailable — continuing without it"

# Implement (in a worktree):
( cd "$WT" && "$GLM" "$(cat "$RUN/prompt-glm.txt")" --permission-mode acceptEdits ) \
    > "$RUN/impl-glm.md"
```

> Degradation: decide the worker set up front from the pool probe. If `glm.sh --check`
> failed, **do not** create a glm worktree or issue glm calls — drop glm from every
> loop below and proceed with the remaining families. Same for any worker whose CLI
> is absent. Build the loop list dynamically, e.g. `WORKERS=(codex claude)` when glm
> is out.

---

## Isolated worktrees (deep mode — parallel implementers can't conflict)

Workers leave their edits **uncommitted** in their worktree, so adoption is
**patch-based**, not branch-merge: `git worktree add -b … HEAD` makes a branch at
HEAD with no commits, so `git merge cmo/…` would import nothing and a forced
cleanup would then destroy the only copy of the work. Capture the diff first,
apply it, verify, and only then clean up.

```bash
SLUG="taskslug"
WORKERS=(codex claude)        # built from the pool probe; add glm only if --check passed

# 1) One detached worktree per worker (no branch needed for patch-based adoption).
for w in "${WORKERS[@]}"; do
  git -C "$REPO" worktree add --detach "$RUN/wt-$w" HEAD
done

# ... each worker implements in $RUN/wt-$w (uncommitted edits) ...

# 2) Inspect / capture a worker's diff (working tree vs HEAD; no commit required).
#    This is what a cross-family verifier reviews and what gets adopted.
for w in "${WORKERS[@]}"; do
  git -C "$RUN/wt-$w" add -A          # stage so new files show in the diff
  git -C "$RUN/wt-$w" diff --staged > "$RUN/diff-$w.patch"
  echo "$w: $(wc -l < "$RUN/diff-$w.patch") diff lines"
done

# 3) Adopt the WINNER's captured patch onto the main repo (safe; survives cleanup).
WINNER=codex
test -s "$RUN/diff-$WINNER.patch" || { echo "winner patch is empty — abort adopt"; }
git -C "$REPO" apply --3way "$RUN/diff-$WINNER.patch"
( cd "$REPO" && : run the test command here to confirm the adopted patch passes )

# 4) Clean up only AFTER the patch is applied and confirmed.
for w in "${WORKERS[@]}"; do
  git -C "$REPO" worktree remove --force "$RUN/wt-$w" 2>/dev/null || true
done
git -C "$REPO" worktree prune
rm -rf "$RUN"
```

> Grafting hunks from several workers is risky — independent implementations carry
> different invariants. Prefer **one base** (the winning patch) plus **explicitly
> reviewed** additions cherry-picked from the others, not a blind union of hunks.

---

## Verifier verdict — small JSON for parseable pass/fail

Ask the verifier (a **different family** than the implementer) to end with this.
With codex you can enforce it via `--output-schema`; with claude/glm just instruct it.

```json
{
  "pass": true,
  "tests_run": "pytest -q",
  "tests_passed": true,
  "issues": [
    {"severity": "high", "where": "src/foo.py:42", "what": "off-by-one in loop bound"}
  ],
  "summary": "Builds and tests pass; one high-sev edge case to fix."
}
```

`pass=false` with `issues` feeds the next round's focused prompt. Stop when
`pass=true` or the round budget is exhausted (then report the best diff + open issues).

### Verifier invocation (the actual call — verifier family ≠ implementer family)

The verifier **reviews a diff and runs the tests**; it must not rewrite the
implementation. Run the verifier **inside the candidate's own worktree**
(`$RUN/wt-$w`) — that tree already holds the worker's uncommitted edits, so the
tests exercise the *candidate*, not the baseline `$REPO`. (Running in `$REPO`
would test unmodified code and silently pass.) Pick a verifier whose family
differs from whoever produced the patch (see the fallback matrix in SKILL.md).
Examples verifying GLM's work, which lives in `$RUN/wt-glm`:

```bash
TEST_CMD="pytest -q"   # the repo's real test command
WT="$RUN/wt-glm"       # the worktree holding the candidate edits under test

# --- codex as verifier (schema-enforced). Reviews in-place; runs tests on the candidate tree. ---
codex exec --skip-git-repo-check -s workspace-write -C "$WT" \
  --output-schema "$SKILL/references/verdict.schema.json" \
  -o "$RUN/verdict-glm.json" \
  - <<PROMPT
You are in a git worktree that ALREADY contains a candidate change (see \`git diff HEAD\`).
Review it for correctness/regressions; do NOT modify the source.
Run \`$TEST_CMD\` here and report whether it passes. Emit the verdict JSON last.
PROMPT

# --- claude as verifier (instruct the schema; same shape). ---
( cd "$WT" && claude -p "This worktree already contains a candidate change (git diff HEAD).
Review it (do not edit source), run \`$TEST_CMD\` here, and output ONLY the verdict JSON
{pass,tests_run,tests_passed,issues[],summary}." \
    --model "${CLAUDE_WORKER_MODEL:-claude-opus-4-8}" \
    --permission-mode acceptEdits ) > "$RUN/verdict-glm.json"

# --- glm as verifier (via the adapter; same instruction). ---
( cd "$WT" && "$SKILL/scripts/glm.sh" "This worktree already contains a candidate change
(git diff HEAD). Review it (do not edit source), run \`$TEST_CMD\` here, and output ONLY the
verdict JSON {pass,tests_run,tests_passed,issues[],summary}." \
    --permission-mode acceptEdits ) > "$RUN/verdict-glm.json"
```

When the verifier needs the diff as text (e.g. for a focused review comment), it
can read `$RUN/diff-glm.patch` — but tests must run in `$WT`, never `$REPO`.

The schema file `references/verdict.schema.json` ships with this skill so codex's
`--output-schema` works out of the box. Fold each `pass=false` verdict's `issues`
into the next round's prompt, e.g.:

```bash
jq -r '.issues[]? | "- [\(.severity)] \(.where): \(.what)"' "$RUN"/verdict-*.json \
  > "$RUN/open-issues.txt"   # prepend to each worker's R2 prompt
```
