#!/bin/bash
set -euo pipefail
# PostToolUseFailure Hook: 도구 실패 시 에러 패턴에 맞는 힌트 출력

# shellcheck disable=SC2329
cleanup() {
  # 임시 자원 정리가 필요한 경우를 위한 placeholder
  :
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PIPELINE_FLAG="$PROJECT_DIR/.claude/.selfish-active"
FAILURES_LOG="$PROJECT_DIR/.claude/.selfish-failures.log"

# stdin에서 입력 파싱
INPUT=$(cat)

# tool_name 추출
if command -v jq &> /dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  ERROR=$(echo "$INPUT" | jq -r '.error // empty' 2>/dev/null)
else
  TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)
  ERROR=$(echo "$INPUT" | grep -o '"error"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)
fi

TOOL_NAME="${TOOL_NAME:-unknown}"
ERROR="${ERROR:-}"

# 파이프라인 활성 중이면 실패 로그 기록 (에러 메시지 1줄로 정규화)
if [ -f "$PIPELINE_FLAG" ] && [ -n "$ERROR" ]; then
  ERROR_ONELINE=$(echo "$ERROR" | head -1 | cut -c1-200)
  echo "$(date +%s) $TOOL_NAME: $ERROR_ONELINE" >> "$FAILURES_LOG"
fi

# 에러 패턴 매칭
HINT=""
case "$ERROR" in
  *EACCES*)
    HINT="파일 권한을 확인하세요. chmod 또는 sudo가 필요할 수 있습니다."
    ;;
  *ENOENT*|*"No such file"*)
    HINT="파일 또는 디렉토리가 존재하는지 확인하세요."
    ;;
  *ECONNREFUSED*)
    HINT="대상 서버/서비스가 실행 중인지 확인하세요."
    ;;
  *"command not found"*)
    HINT="필요한 도구가 설치되어 있는지 확인하세요."
    ;;
  *"shellcheck"*)
    HINT="shellcheck 설치: brew install shellcheck (macOS) 또는 apt install shellcheck (Linux)"
    ;;
  *"ENOMEM"*|*"Cannot allocate"*)
    HINT="메모리 부족. 다른 프로세스를 종료하거나 리소스를 확인하세요."
    ;;
  *)
    HINT=""
    ;;
esac

# 힌트가 있으면 JSON 출력 (변수를 sanitize하여 JSON 인젝션 방지)
if [ -n "$HINT" ]; then
  # jq 사용 가능 시 안전한 JSON 생성, 불가 시 특수문자 제거 후 printf
  if command -v jq &> /dev/null; then
    jq -n --arg ctx "[SELFISH HINT] $HINT (tool: $TOOL_NAME)" \
      '{"hookSpecificOutput":{"hookEventName":"PostToolUseFailure","additionalContext":$ctx}}'
  else
    # shellcheck disable=SC1003
    SAFE_HINT=$(echo "$HINT" | tr -d '"' | tr -d '\\')
    # shellcheck disable=SC1003
    SAFE_TOOL=$(echo "$TOOL_NAME" | tr -d '"' | tr -d '\\')
    printf '{"hookSpecificOutput":{"hookEventName":"PostToolUseFailure","additionalContext":"[SELFISH HINT] %s (tool: %s)"}}\n' "$SAFE_HINT" "$SAFE_TOOL"
  fi
fi

exit 0
