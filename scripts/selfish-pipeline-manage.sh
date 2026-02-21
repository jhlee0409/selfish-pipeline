#!/bin/bash
set -euo pipefail

# Pipeline Management: Manage selfish pipeline state flags
# Manages flag files referenced by other hook scripts
#
# Usage:
#   selfish-pipeline-manage.sh start <feature-name>
#   selfish-pipeline-manage.sh phase <phase-name>
#   selfish-pipeline-manage.sh ci-pass
#   selfish-pipeline-manage.sh end [--force]
#   selfish-pipeline-manage.sh status
#   selfish-pipeline-manage.sh log <event_type> <message>
#   selfish-pipeline-manage.sh phase-tag <phase_number>
#   selfish-pipeline-manage.sh phase-tag-clean

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
FLAG_DIR="$PROJECT_DIR/.claude"
PIPELINE_FLAG="$FLAG_DIR/.selfish-active"
PHASE_FLAG="$FLAG_DIR/.selfish-phase"
CI_FLAG="$FLAG_DIR/.selfish-ci-passed"
CHANGES_LOG="$FLAG_DIR/.selfish-changes.log"

# shellcheck disable=SC2329
cleanup() {
  local exit_code=$?
  if [ "$exit_code" -ne 0 ]; then
    echo "selfish-pipeline-manage: exited with code $exit_code" >&2
  fi
  exit "$exit_code"
}
trap cleanup EXIT

mkdir -p "$FLAG_DIR"

COMMAND="${1:-}"
if [ -z "$COMMAND" ]; then
  echo "Usage: $0 {start|phase|ci-pass|end|status} [args]" >&2
  exit 1
fi

case "$COMMAND" in
  start)
    if [ -z "${2:-}" ]; then
      echo "Feature name required" >&2
      exit 1
    fi
    # Sanitize feature name (strip newlines, path traversal, limit length)
    FEATURE=$(printf '%s' "$2" | tr -d '\n\r/' | cut -c1-100)
    if [ -z "$FEATURE" ]; then
      echo "Feature name invalid after sanitization" >&2
      exit 1
    fi

    # Prevent duplicate execution
    if [ -f "$PIPELINE_FLAG" ]; then
      EXISTING=$(cat "$PIPELINE_FLAG")
      echo "WARNING: Pipeline already active: $EXISTING" >&2
      echo "Use '$0 end --force' to clear, or '$0 status' to check." >&2
      exit 1
    fi

    printf '%s\n' "$FEATURE" > "$PIPELINE_FLAG"
    printf '%s\n' "spec" > "$PHASE_FLAG"
    rm -f "$CI_FLAG" "$CHANGES_LOG"

    # Safety snapshot
    if cd "$PROJECT_DIR" 2>/dev/null; then
      git tag -f "selfish/pre-auto" 2>/dev/null || true
    fi

    echo "Pipeline started: $FEATURE (safety tag: selfish/pre-auto)"
    ;;

  phase)
    PHASE="${2:?Phase name required}"
    case "$PHASE" in
      spec|plan|tasks|implement|review|clean)
        printf '%s\n' "$PHASE" > "$PHASE_FLAG"
        rm -f "$CI_FLAG"  # Reset CI for new Phase
        echo "Phase: $PHASE"
        ;;
      *)
        echo "Invalid phase: $PHASE (valid: spec|plan|tasks|implement|review|clean)" >&2
        exit 1
        ;;
    esac
    ;;

  ci-pass)
    date +%s > "$CI_FLAG"
    echo "CI passed at $(date '+%H:%M:%S')"
    ;;

  end)
    FORCE="${2:-}"
    FEATURE=""
    if [ -f "$PIPELINE_FLAG" ]; then
      FEATURE=$(cat "$PIPELINE_FLAG")
    elif [ "$FORCE" != "--force" ]; then
      echo "No active pipeline to end." >&2
      exit 0
    fi

    rm -f "$PIPELINE_FLAG" "$PHASE_FLAG" "$CI_FLAG" "$CHANGES_LOG"
    rm -f "$FLAG_DIR/.selfish-failures.log" "$FLAG_DIR/.selfish-task-results.log" "$FLAG_DIR/.selfish-config-audit.log"

    # Clean up safety tag and phase tags (on successful completion)
    if cd "$PROJECT_DIR" 2>/dev/null; then
      git tag -d "selfish/pre-auto" 2>/dev/null || true
      for TAG in $(git tag -l 'selfish/phase-*' 2>/dev/null || true); do
        git tag -d "$TAG" 2>/dev/null || true
      done
    fi

    echo "Pipeline ended: ${FEATURE:-unknown}"
    ;;

  status)
    if [ -f "$PIPELINE_FLAG" ]; then
      echo "Active: $(cat "$PIPELINE_FLAG")"
      [ -f "$PHASE_FLAG" ] && echo "Phase: $(cat "$PHASE_FLAG")"
      [ -f "$CI_FLAG" ] && echo "CI: passed ($(cat "$CI_FLAG"))"
      if [ -f "$CHANGES_LOG" ]; then
        CHANGE_COUNT=$(wc -l < "$CHANGES_LOG" | tr -d ' ')
        echo "Changes: $CHANGE_COUNT files"
      fi
    else
      echo "No active pipeline"
    fi
    ;;

  log)
    EVENT="${2:-}"
    MSG="${3:-}"
    if [ -z "$EVENT" ]; then
      echo "Usage: $0 log <event_type> <message>" >&2
      exit 1
    fi
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    "$SCRIPT_DIR/selfish-timeline-log.sh" "$EVENT" "$MSG"
    ;;

  phase-tag)
    PHASE_NUM="${2:?Phase number required}"
    # Sanitize to digits only
    PHASE_NUM=$(printf '%s' "$PHASE_NUM" | tr -dc '0-9' | cut -c1-2)
    if [ -z "$PHASE_NUM" ]; then
      echo "Invalid phase number" >&2
      exit 1
    fi
    if cd "$PROJECT_DIR" 2>/dev/null; then
      git tag -f "selfish/phase-${PHASE_NUM}" 2>/dev/null || true
      echo "Phase tag created: selfish/phase-${PHASE_NUM}"
    else
      echo "Cannot create tag: not a git repo" >&2
      exit 1
    fi
    ;;

  phase-tag-clean)
    if cd "$PROJECT_DIR" 2>/dev/null; then
      TAGS=$(git tag -l 'selfish/phase-*' 2>/dev/null || true)
      if [ -n "$TAGS" ]; then
        COUNT=0
        for TAG in $TAGS; do
          git tag -d "$TAG" 2>/dev/null || true
          COUNT=$((COUNT + 1))
        done
        echo "Removed $COUNT phase tags"
      else
        echo "No phase tags to remove"
      fi
    else
      echo "Cannot clean tags: not a git repo" >&2
      exit 0
    fi
    ;;

  *)
    echo "Usage: $0 {start|phase|ci-pass|end|status|log|phase-tag|phase-tag-clean} [args]" >&2
    exit 1
    ;;
esac

exit 0
