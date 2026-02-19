#!/bin/bash
set -euo pipefail
# PostToolUse Hook: 파일 변경 추적
# Edit/Write 도구 사용 후 변경된 파일을 기록
# CI 게이트에서 어떤 파일이 변경되었는지 추적

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PIPELINE_FLAG="$PROJECT_DIR/.claude/.selfish-active"
CHANGES_LOG="$PROJECT_DIR/.claude/.selfish-changes.log"
CI_FLAG="$PROJECT_DIR/.claude/.selfish-ci-passed"

# shellcheck disable=SC2329
cleanup() {
  # 임시 자원 정리가 필요한 경우를 위한 placeholder
  :
}
trap cleanup EXIT

# 파이프라인 비활성이면 → 스킵
if [ ! -f "$PIPELINE_FLAG" ]; then
  exit 0
fi

# stdin에서 tool input 파싱
INPUT=$(cat)

# stdin이 비어있으면 스킵
if [ -z "$INPUT" ]; then
  exit 0
fi

# jq가 있으면 jq로, 없으면 grep/sed fallback으로 file_path 추출
if command -v jq &> /dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)
fi

if [ -n "$FILE_PATH" ]; then
  # 변경 로그에 추가 (중복 제거)
  echo "$FILE_PATH" >> "$CHANGES_LOG"
  sort -u -o "$CHANGES_LOG" "$CHANGES_LOG"

  # 파일이 변경되었으므로 CI 결과 무효화
  rm -f "$CI_FLAG"
fi

exit 0
