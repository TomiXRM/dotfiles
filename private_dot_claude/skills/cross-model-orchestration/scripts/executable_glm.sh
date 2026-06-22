#!/usr/bin/env bash
# GLM worker adapter for cross-model-orchestration.
#
# Gives GLM the SAME stdin->stdout interface as `codex exec` / `claude -p`,
# so the Conductor can dispatch all three workers uniformly.
#
# Resolution order (first match wins):
#   1. $GLM_CMD   - a custom command (e.g. your ZCode CLI). Receives the prompt
#                   as its last argument. Use this if you drive GLM some other way.
#   2. $GLM_API_KEY / $ZAI_API_KEY / $ZHIPU_API_KEY - call GLM's Anthropic-
#                   compatible endpoint by REUSING the already-installed `claude`
#                   CLI (this is exactly what the "ZCode" / GLM Coding Plan does:
#                   the claude binary is just an Anthropic-protocol client; the
#                   model answering is GLM on Z.ai's servers, a different family).
#   3. nothing configured -> exit 3 with a hint, so the Conductor can drop GLM
#                   from the pool and continue with reduced diversity.
#
# Usage:
#   scripts/glm.sh "<prompt>" [extra claude flags...]
#   echo "<prompt>" | scripts/glm.sh [extra claude flags...]
#
# Examples:
#   scripts/glm.sh "Plan an approach to X" --permission-mode plan
#   ( cd "$WORKTREE" && scripts/glm.sh "Implement Y" --permission-mode acceptEdits )
#
# Env overrides:
#   GLM_MODEL     (default: glm-4.6)
#   GLM_BASE_URL  (default: https://api.z.ai/api/anthropic;
#                  bigmodel users: https://open.bigmodel.cn/api/anthropic)
set -euo pipefail

# `--check`: report configuration without invoking any model. Exit 0 if GLM is
# reachable (GLM_CMD or an API key set), 3 if not. Used by the Conductor's probe.
if [ "${1:-}" = "--check" ]; then
  if [ -n "${GLM_CMD:-}" ]; then echo "glm: ok (GLM_CMD)"; exit 0; fi
  if [ -n "${GLM_API_KEY:-${ZAI_API_KEY:-${ZHIPU_API_KEY:-}}}" ]; then
    echo "glm: ok (API key)"; exit 0
  fi
  echo "glm: NOT configured" >&2; exit 3
fi

# First arg is the prompt unless it looks like a flag; otherwise read stdin.
prompt=""
if [ "$#" -gt 0 ] && [ "${1#-}" = "$1" ]; then
  prompt="$1"; shift
else
  prompt="$(cat)"
fi

# 1) Custom command escape hatch (e.g. ZCode). Extra flags ("$@", e.g.
#    --permission-mode) are forwarded too; a GLM_CMD that ignores them is fine.
if [ -n "${GLM_CMD:-}" ]; then
  # shellcheck disable=SC2086  # GLM_CMD is intentionally word-split.
  exec ${GLM_CMD} "$prompt" "$@"
fi

# 2) API key via Anthropic-compatible endpoint, reusing the claude CLI.
key="${GLM_API_KEY:-${ZAI_API_KEY:-${ZHIPU_API_KEY:-}}}"
if [ -n "$key" ]; then
  exec env \
    ANTHROPIC_BASE_URL="${GLM_BASE_URL:-https://api.z.ai/api/anthropic}" \
    ANTHROPIC_AUTH_TOKEN="$key" \
    ANTHROPIC_API_KEY="$key" \
    claude -p "$prompt" --model "${GLM_MODEL:-glm-4.6}" "$@"
fi

# 3) Not configured.
echo "glm.sh: GLM not configured." >&2
echo "  set GLM_CMD='<your ZCode command>'  OR  export GLM_API_KEY=<z.ai/zhipu key>" >&2
exit 3
