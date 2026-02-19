#!/bin/bash
set -euo pipefail

# SubagentStart Hook: 서브에이전트 생성 시 파이프라인 컨텍스트 주입
# 서브에이전트가 현재 피처/페이즈와 프로젝트 설정을 인지하도록 함
#
# Gap 해결: 서브에이전트는 부모 컨텍스트를 상속하지 않으므로 명시적 주입 필요

# shellcheck disable=SC2329
cleanup() {
  :
}
trap cleanup EXIT

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PIPELINE_FLAG="$PROJECT_DIR/.claude/.selfish-active"

# 파이프라인 비활성 시 조용히 종료
if [ ! -f "$PIPELINE_FLAG" ]; then
  exit 0
fi

# 1. 피처명 읽기
FEATURE=$(cat "$PIPELINE_FLAG" 2>/dev/null || echo "unknown")

# 2. 현재 페이즈 읽기
PHASE=$(cat "$PROJECT_DIR/.claude/.selfish-phase" 2>/dev/null || echo "unknown")

# 3. 파이프라인 상태 출력
echo "[SELFISH PIPELINE] Feature: $FEATURE | Phase: $PHASE"

# 4. selfish.config.md 에서 설정 섹션 추출
CONFIG_FILE="$PROJECT_DIR/.claude/selfish.config.md"

if [ -f "$CONFIG_FILE" ]; then
  # Architecture 섹션 추출 (## Architecture ~ 다음 ## 전까지)
  # shellcheck disable=SC2001
  ARCH=$(sed -n '/^## Architecture/,/^## /p' "$CONFIG_FILE" 2>/dev/null | sed '1d;/^## /d;/^$/d' | head -5 | tr '\n' ' ' | sed 's/  */ /g;s/^ *//;s/ *$//')
  if [ -n "$ARCH" ]; then
    echo "[CONFIG] Architecture: $ARCH"
  fi

  # Code Style 섹션 추출 (## Code Style ~ 다음 ## 전까지)
  # shellcheck disable=SC2001
  STYLE=$(sed -n '/^## Code Style/,/^## /p' "$CONFIG_FILE" 2>/dev/null | sed '1d;/^## /d;/^$/d' | head -5 | tr '\n' ' ' | sed 's/  */ /g;s/^ *//;s/ *$//')
  if [ -n "$STYLE" ]; then
    echo "[CONFIG] Code Style: $STYLE"
  fi
fi

exit 0
