#!/bin/bash
set -euo pipefail
# ConfigChange Hook: 파이프라인 활성 중 설정 변경 감사 및 차단
# policy_settings 변경은 로그만 기록, 그 외 변경은 차단 (exit 2)

# trap: 비정상 종료 시 exit code 보존 + stderr 메시지
# shellcheck disable=SC2329
cleanup() {
  local exit_code=$?
  if [ "$exit_code" -ne 0 ] && [ "$exit_code" -ne 2 ]; then
    echo "SELFISH CONFIG: 비정상 종료 (exit code: $exit_code)" >&2
  fi
  exit "$exit_code"
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PIPELINE_FLAG="${PROJECT_DIR}/.claude/.selfish-active"
AUDIT_LOG="${PROJECT_DIR}/.claude/.selfish-config-audit.log"

# stdin에서 hook 데이터 읽기
INPUT=$(cat)

# 파이프라인 비활성 시 조용히 종료
if [ ! -f "$PIPELINE_FLAG" ]; then
  exit 0
fi

# source 파싱 (jq 우선, grep/sed fallback)
SOURCE=""
if command -v jq >/dev/null 2>&1; then
  SOURCE=$(printf '%s\n' "$INPUT" | jq -r '.source // empty' 2>/dev/null)
else
  SOURCE=$(printf '%s\n' "$INPUT" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)
fi
SOURCE=$(printf '%s' "$SOURCE" | head -1 | tr -d '\n\r' | cut -c1-500)

# file_path 파싱 (jq 우선, grep/sed fallback)
FILE_PATH=""
if command -v jq >/dev/null 2>&1; then
  FILE_PATH=$(printf '%s\n' "$INPUT" | jq -r '.file_path // empty' 2>/dev/null)
else
  FILE_PATH=$(printf '%s\n' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)
fi
FILE_PATH=$(printf '%s' "$FILE_PATH" | head -1 | tr -d '\n\r' | cut -c1-500)

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# policy_settings 변경은 로그만 기록 (차단하지 않음)
if [ "$SOURCE" = "policy_settings" ]; then
  printf '[%s] source=%s path=%s\n' "$TIMESTAMP" "$SOURCE" "$FILE_PATH" >> "$AUDIT_LOG"
  exit 0
fi

# 그 외 변경: 감사 로그 기록 + 차단
printf '[%s] source=%s path=%s\n' "$TIMESTAMP" "$SOURCE" "$FILE_PATH" >> "$AUDIT_LOG"
echo "SELFISH CONFIG: 파이프라인 활성 중 설정 변경이 감지되었습니다. source=${SOURCE} path=${FILE_PATH}" >&2
exit 2
