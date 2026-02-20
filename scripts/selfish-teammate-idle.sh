#!/bin/bash
set -euo pipefail
# TeammateIdle Hook: 파이프라인 활성 중 implement/review Phase에서 idle 차단
# Claude가 작업 도중 멈추는 것을 물리적으로 방지
#
# Gap 해결: "프롬프트는 강제가 아님" → exit 2로 물리적 차단

# trap: 비정상 종료 시 exit code 보존 + stderr 메시지
# shellcheck disable=SC2329
cleanup() {
  local exit_code=$?
  if [ "$exit_code" -ne 0 ] && [ "$exit_code" -ne 2 ]; then
    echo "SELFISH TEAMMATE GATE: 비정상 종료 (exit code: $exit_code)" >&2
  fi
  exit "$exit_code"
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PIPELINE_FLAG="${PROJECT_DIR}/.claude/.selfish-active"
PHASE_FLAG="${PROJECT_DIR}/.claude/.selfish-phase"

# 파이프라인이 활성이 아니면 → 통과
if [ ! -f "$PIPELINE_FLAG" ]; then
  exit 0
fi

FEATURE="$(head -1 "$PIPELINE_FLAG" | tr -d '\n\r')"

# Phase 파일이 있으면 현재 Phase 확인
CURRENT_PHASE=""
if [ -f "$PHASE_FLAG" ]; then
  CURRENT_PHASE="$(cat "$PHASE_FLAG")"
fi
CURRENT_PHASE="${CURRENT_PHASE:-}"

# implement/review Phase에서는 idle 차단 → 작업 계속 강제
case "${CURRENT_PHASE:-}" in
  implement|review)
    echo "SELFISH TEAMMATE GATE: 파이프라인 '${FEATURE:-unknown}' Phase '${CURRENT_PHASE:-unknown}'가 활성입니다. 작업을 완료하세요." >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
