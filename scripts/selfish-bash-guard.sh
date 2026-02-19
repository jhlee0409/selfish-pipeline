#!/bin/bash
set -euo pipefail
# PreToolUse Hook: 파이프라인 활성 중 위험한 Bash 명령 차단
# git push --force, reset --hard, checkout ., restore ., clean -f 등을 방지
# 단, selfish/pre- 태그 롤백을 위한 reset --hard는 허용

# shellcheck disable=SC2329
cleanup() {
  # 임시 자원 정리가 필요한 경우를 위한 placeholder
  :
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PIPELINE_FLAG="$PROJECT_DIR/.claude/.selfish-active"

# 파이프라인 비활성이면 → 허용
if [ ! -f "$PIPELINE_FLAG" ]; then
  printf '{"decision":"allow"}\n'
  exit 0
fi

# stdin에서 tool input 파싱
INPUT=$(cat)

# stdin이 비어있으면 → 허용
if [ -z "$INPUT" ]; then
  printf '{"decision":"allow"}\n'
  exit 0
fi

# jq가 있으면 jq로, 없으면 grep/sed fallback으로 command 추출
if command -v jq &> /dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)
fi

# command가 비어있으면 → 허용
if [ -z "$COMMAND" ]; then
  printf '{"decision":"allow"}\n'
  exit 0
fi

# 위험한 패턴 검사
DENY_REASON=""

case "$COMMAND" in
  *"push --force"*|*"push -f "*|*"push -f")
    DENY_REASON="git push --force는 파이프라인 중 차단됩니다"
    ;;
  *"reset --hard"*)
    # selfish/pre- 태그 롤백은 허용
    if [[ "$COMMAND" != *"selfish/pre-"* ]]; then
      DENY_REASON="git reset --hard는 파이프라인 중 차단됩니다"
    fi
    ;;
  *"checkout ."*|*"checkout -- ."*)
    DENY_REASON="git checkout .은 파이프라인 중 차단됩니다"
    ;;
  *"restore ."*)
    DENY_REASON="git restore .은 파이프라인 중 차단됩니다"
    ;;
  *"clean -f"*)
    DENY_REASON="git clean -f는 파이프라인 중 차단됩니다"
    ;;
esac

if [ -n "$DENY_REASON" ]; then
  printf '{"decision":"deny","reason":"SELFISH GUARD: %s"}\n' "$DENY_REASON"
else
  printf '{"decision":"allow"}\n'
fi

exit 0
