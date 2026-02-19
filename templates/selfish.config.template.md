# Selfish Configuration

> 이 파일은 selfish 커맨드 시스템의 프로젝트별 설정을 정의한다.
> 모든 selfish.* 커맨드는 이 파일을 참조하여 프로젝트별 동작을 결정한다.
> 각 섹션을 프로젝트에 맞게 수정하세요.

## CI Commands

```yaml
ci: "npm run ci"                        # 전체 CI (lint + typecheck + build)
typecheck: "npm run typecheck"          # 타입 체크만
lint: "npm run lint"                    # 린트만
lint_fix: "npm run lint:fix"            # 린트 자동 수정
gate: "npm run typecheck && npm run lint"  # Phase 게이트 (implement 중 반복 실행)
test: "npm test"                        # 테스트
```

## Architecture

```yaml
style: "Layered"                        # 예: FSD, Clean Architecture, Modular Monolith, Layered
layers: []                              # 상위 → 하위 순서로 나열
import_rule: ""                         # import 방향 규칙 (예: "상위→하위만 허용")
segments: []                            # 각 계층의 하위 세그먼트
path_alias: ""                          # 예: "@/* → ./src/*"
```

## Framework

```yaml
name: ""                                # 예: Next.js 14, Vite, CRA
runtime: ""                             # 예: App Router, Pages Router
client_directive: ""                    # 예: 'use client' (없으면 비워두기)
client_directive_rule: ""               # 클라이언트 디렉티브 적용 규칙
server_client_boundary: false           # 서버/클라이언트 경계 존재 여부
```

## Code Style

```yaml
language: "TypeScript"
strict_mode: true
type_keyword: "type"                    # type vs interface
import_type: true                       # import type 사용 여부
component_style: "PascalCase"
props_position: "above component"
handler_naming: "handle[Event]"
boolean_naming: "is/has/can[State]"
constant_naming: "UPPER_SNAKE_CASE"
any_policy: "최소화"
```

## State Management

```yaml
global_state: ""                        # 예: Zustand, Redux, Pinia
server_state: ""                        # 예: React Query, SWR, Apollo
local_state: ""                         # 예: Context API, useState
store_location: ""                      # store 파일 위치 패턴
query_location: ""                      # query 파일 위치 패턴
```

## Styling

```yaml
framework: ""                           # 예: Tailwind CSS, styled-components, CSS Modules
```

## Testing

```yaml
framework: ""                           # 예: Jest, Vitest, Playwright
```

## Project-Specific Risks

> Plan의 RISK Critic에서 반드시 점검할 프로젝트 고유 위험 패턴
> 프로젝트에 맞게 수정하세요.

1. (예시) import 순서 위반
2. (예시) 순환 참조
3. (예시) 타입 안전성 우회 (as any)

## Mini-Review Checklist

> Implement Phase 게이트의 Mini-Review에서 각 파일에 대해 점검할 항목

1. 아키텍처 규칙 위반 여부
2. 코드 스타일 패턴 준수
3. 미사용 코드 (미사용 import, 빈 export, dead code)
