#!/bin/bash
set -euo pipefail

# shellcheck disable=SC2329
cleanup() {
  :
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

CI_COMMAND=""

printf 'Preflight Check:\n'

# Check 1: CI command exists
if [[ -f "$PROJECT_DIR/package.json" ]]; then
  if jq -e '.scripts["test:all"]' "$PROJECT_DIR/package.json" > /dev/null 2>&1; then
    CI_COMMAND="npm run test:all"
  elif jq -e '.scripts["test"]' "$PROJECT_DIR/package.json" > /dev/null 2>&1; then
    CI_COMMAND="npm test"
  fi
fi

if [[ -n "$CI_COMMAND" ]]; then
  printf '  \xe2\x9c\x93 CI command: %s\n' "$CI_COMMAND"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  printf '  \xe2\x9c\x97 CI command: no test script found in package.json\n'
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 2: Dependencies installed
if [[ -f "$PROJECT_DIR/package.json" ]]; then
  if [[ -d "$PROJECT_DIR/node_modules" ]]; then
    printf '  \xe2\x9c\x93 Dependencies: node_modules present\n'
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf '  \xe2\x9a\xa0 Dependencies: node_modules not found (run npm install)\n'
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
else
  printf '  \xe2\x9c\x93 Dependencies: no package.json (non-npm project, skipping)\n'
  PASS_COUNT=$((PASS_COUNT + 1))
fi

# Check 3: Shellcheck available
if command -v shellcheck > /dev/null 2>&1; then
  printf '  \xe2\x9c\x93 Shellcheck: installed\n'
  PASS_COUNT=$((PASS_COUNT + 1))
else
  printf '  \xe2\x9a\xa0 Shellcheck: not installed (lint may fail)\n'
  WARN_COUNT=$((WARN_COUNT + 1))
fi

# Check 4: Git state
if git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  DIRTY_COUNT=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$DIRTY_COUNT" -eq 0 ]]; then
    printf '  \xe2\x9c\x93 Git state: clean\n'
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf '  \xe2\x9a\xa0 Git state: %s uncommitted change(s)\n' "$DIRTY_COUNT"
    WARN_COUNT=$((WARN_COUNT + 1))
  fi
else
  printf '  \xe2\x9a\xa0 Git state: not a git repository\n'
  WARN_COUNT=$((WARN_COUNT + 1))
fi

# Check 5: No active pipeline
ACTIVE_FILE="$PROJECT_DIR/.claude/.selfish-active"
if [[ -f "$ACTIVE_FILE" ]]; then
  ACTIVE_NAME=$(head -1 "$ACTIVE_FILE" 2>/dev/null | tr -d '\n\r' | cut -c1-100 || printf 'unknown')
  printf '  \xe2\x9c\x97 No active pipeline: pipeline already running (%s)\n' "$ACTIVE_NAME"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  printf '  \xe2\x9c\x93 No active pipeline\n'
  PASS_COUNT=$((PASS_COUNT + 1))
fi

# Result
printf '\n'
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  if [[ "$WARN_COUNT" -gt 0 ]]; then
    printf 'Result: FAIL (%d error(s), %d warning(s))\n' "$FAIL_COUNT" "$WARN_COUNT"
  else
    printf 'Result: FAIL (%d error(s))\n' "$FAIL_COUNT"
  fi
  exit 1
else
  if [[ "$WARN_COUNT" -gt 0 ]]; then
    printf 'Result: PASS (%d warning(s))\n' "$WARN_COUNT"
  else
    printf 'Result: PASS\n'
  fi
  exit 0
fi
