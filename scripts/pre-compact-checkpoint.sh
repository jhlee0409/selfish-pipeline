#!/bin/bash
set -euo pipefail
# Pre-Compact Hook: 컨텍스트 압축 전 자동 체크포인트
# 세션 중단/압축 시 진행 상태가 소실되는 것을 방지
#
# Gap 해결: OMC의 자동 상태 저장 -> 물리적 스크립트로 강제

# shellcheck disable=SC2329
cleanup() {
  # 임시 파일 정리 등 필요 시 확장
  :
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Auto-memory 디렉토리를 프로젝트 경로에서 동적 파생
PROJECT_PATH=$(cd "$PROJECT_DIR" 2>/dev/null && pwd || true)
PROJECT_PATH="${PROJECT_PATH:-$PROJECT_DIR}"
ENCODED_PATH="${PROJECT_PATH//\//-}"
MEMORY_DIR="$HOME/.claude/projects/$ENCODED_PATH/memory"
CHECKPOINT="$MEMORY_DIR/checkpoint.md"

# memory 디렉토리 없으면 생성
mkdir -p "$MEMORY_DIR"

# 현재 git 상태 수집
BRANCH=$(cd "$PROJECT_DIR" 2>/dev/null && git branch --show-current 2>/dev/null || echo "unknown")

ALL_MODIFIED=$(cd "$PROJECT_DIR" 2>/dev/null && git diff --name-only 2>/dev/null || true)
MODIFIED=$(echo "$ALL_MODIFIED" | head -10)

ALL_STAGED=$(cd "$PROJECT_DIR" 2>/dev/null && git diff --cached --name-only 2>/dev/null || true)
STAGED=$(echo "$ALL_STAGED" | head -10)

# 파일 수 계산 (wc -l 파이프 대신 변수 캡처)
MODIFIED_COUNT=0
if [ -n "$ALL_MODIFIED" ]; then
  MODIFIED_RAW=$(echo "$ALL_MODIFIED" | wc -l)
  MODIFIED_COUNT=$(echo "$MODIFIED_RAW" | tr -d ' ')
fi

STAGED_COUNT=0
if [ -n "$ALL_STAGED" ]; then
  STAGED_RAW=$(echo "$ALL_STAGED" | wc -l)
  STAGED_COUNT=$(echo "$STAGED_RAW" | tr -d ' ')
fi

# selfish pipeline 활성 상태 확인
PIPELINE_FLAG="$PROJECT_DIR/.claude/.selfish-active"
PIPELINE_FEATURE=""
if [ -f "$PIPELINE_FLAG" ]; then
  PIPELINE_FEATURE=$(cat "$PIPELINE_FLAG")
fi

# tasks.md 진행 상태 확인
TASKS_DONE=0
TASKS_TOTAL=0
if [ -n "$PIPELINE_FEATURE" ] && [ -d "$PROJECT_DIR/specs/$PIPELINE_FEATURE" ]; then
  TASKS_FILE="$PROJECT_DIR/specs/$PIPELINE_FEATURE/tasks.md"
  if [ -f "$TASKS_FILE" ]; then
    TASKS_DONE=$(grep -cE '\[x\]' "$TASKS_FILE" 2>/dev/null || echo 0)
    TASKS_TOTAL=$(grep -cE '\[(x| )\]' "$TASKS_FILE" 2>/dev/null || echo 0)
  fi
fi

# 빈 목록 방어
if [ -n "$MODIFIED" ]; then
  # shellcheck disable=SC2001
  MODIFIED_LIST=$(echo "$MODIFIED" | sed 's/^/  - /')
else
  MODIFIED_LIST="  (없음)"
fi

if [ -n "$STAGED" ]; then
  # shellcheck disable=SC2001
  STAGED_LIST=$(echo "$STAGED" | sed 's/^/  - /')
else
  STAGED_LIST="  (없음)"
fi

# checkpoint.md 작성
cat > "$CHECKPOINT" << EOF
# Auto Checkpoint (Pre-Compact)
> 자동 생성: $(date '+%Y-%m-%d %H:%M:%S')
> 트리거: context compaction

## Git 상태
- 브랜치: $BRANCH
- 수정된 파일: ${MODIFIED_COUNT}개
$MODIFIED_LIST

## Staged 파일 (${STAGED_COUNT}개)
$STAGED_LIST

## Pipeline 상태
- 활성: $([ -f "$PIPELINE_FLAG" ] && echo "Yes ($PIPELINE_FEATURE)" || echo "No")
- 태스크 진행: $TASKS_DONE/$TASKS_TOTAL

## 복원 명령
\`\`\`
/selfish.resume
\`\`\`
EOF

# stdout으로 context 주입 (Claude가 압축 후 이 정보를 볼 수 있음)
echo "Auto-checkpoint saved to memory/checkpoint.md (branch: $BRANCH, pipeline: ${PIPELINE_FEATURE:-inactive})"

exit 0
