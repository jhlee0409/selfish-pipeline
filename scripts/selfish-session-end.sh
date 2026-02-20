#!/bin/bash
set -euo pipefail
# Session End Hook: 세션 종료 시 파이프라인 미완료 경고
# 사용자가 세션을 떠날 때 진행 중인 작업을 인식하도록 알림
#
# Gap 해결: 세션 종료 후에도 /selfish:resume로 재개 가능함을 보장

# shellcheck disable=SC2329
cleanup() {
  # 임시 파일 정리 등 필요 시 확장
  :
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PIPELINE_FLAG="${PROJECT_DIR}/.claude/.selfish-active"

# 파이프라인이 활성이 아니면 → 조용히 종료
if [ ! -f "$PIPELINE_FLAG" ]; then
  exit 0
fi

FEATURE=$(head -1 "$PIPELINE_FLAG" | tr -d '\n\r')

# stdin에서 JSON 읽기
INPUT=$(cat)

# reason 파싱: jq 우선, grep/sed 폴백
REASON=""
if command -v jq &>/dev/null; then
  REASON=$(echo "$INPUT" | jq -r '.reason // empty' 2>/dev/null || true)
else
  REASON=$(echo "$INPUT" | grep -o '"reason"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null \
    | sed 's/.*:[[:space:]]*"//;s/"$//' || true)
fi

# 경고 메시지 구성 (stderr → SessionEnd에서 사용자에게 표시됨)
MSG="SELFISH PIPELINE: Feature '${FEATURE}' 미완료 상태로 세션이 종료됩니다. /selfish:resume로 재개하세요."
if [ -n "$REASON" ]; then
  MSG="${MSG} (종료 사유: ${REASON})"
fi

echo "$MSG" >&2

exit 0
