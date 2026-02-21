---
name: selfish:tasks
description: "Task decomposition"
argument-hint: "[constraints/priority directives]"
user-invocable: false
model: sonnet
---
# /selfish:tasks — Task Decomposition

> Generates an executable task list (tasks.md) based on plan.md.
> Validates coverage with 1 Critic Loop iteration.

## Arguments

- `$ARGUMENTS` — (optional) additional constraints or priority directives

## Config Load

**Must** read `.claude/selfish.config.md` first. Stop if the config file is not present.

## Execution Steps

### 1. Load Context

1. Load from `specs/{feature}/`:
   - **plan.md** (required) — stop if missing: "Run /selfish:plan first."
   - **spec.md** (required)
   - **research.md** (if present)
2. Extract from plan.md:
   - Phase breakdown
   - File Change Map
   - Architecture decisions

### 2. Decompose Tasks

Decompose tasks per Phase defined in plan.md.

#### Task Format (required)

```markdown
- [ ] T{NNN} {[P]} {[US*]} {description} `{file path}` {depends: [TXXX, TXXX]}
```

| Component | Required | Description |
|-----------|----------|-------------|
| `T{NNN}` | Yes | 3-digit sequential ID (T001, T002, ...) |
| `[P]` | No | Parallelizable — no file overlap with other [P] tasks in the same phase |
| `[US*]` | No | User Story label (US1, US2, ... from spec.md) |
| description | Yes | Clear task description (start with a verb) |
| file path | Yes | Primary target file (wrapped in backticks) |
| `depends:` | No | Explicit dependency list — task cannot start until all listed tasks complete |

#### Phase Structure

```markdown
# Tasks: {feature name}

## Phase 1: Setup
{type definitions, configuration, directory structure}

## Phase 2: Core
{core business logic, store, API}

## Phase 3: UI
{components, interactions}

## Phase 4: Integration & Polish
{integration, error handling, optimization}
```

#### Decomposition Principles

1. **1 task = 1 file** principle (where possible)
2. **Same file = sequential**, **different files = [P] candidate**
3. **Explicit dependencies**: Use `depends: [T001, T002]` to declare blocking dependencies. Tasks without `depends:` and with [P] marker are immediately parallelizable.
4. **Dependency graph must be a DAG**: no circular dependencies allowed. Validate before output.
5. **Test tasks**: Include a verification task for each testable unit
6. **Phase gate**: Add a `{config.gate}` validation task at the end of each Phase

### 3. Critic Loop (1 iteration)

> **Always** read `docs/critic-loop-rules.md` first and follow it.

| Criterion | Validation |
|-----------|------------|
| **COVERAGE** | Are all files in plan.md's File Change Map included in tasks? Are all FR-* in spec.md covered? |
| **DEPENDENCIES** | Is the dependency graph a valid DAG? Do [P] tasks within the same phase have no file overlaps? Are all `depends:` targets valid task IDs? |

On FAIL: add missing items and re-check.

### 4. Coverage Mapping

```markdown
## Coverage Mapping
| Requirement | Tasks |
|-------------|-------|
| FR-001 | T003, T007 |
| FR-002 | T005, T008 |
| NFR-001 | T012 |
```

Every FR-*/NFR-* must be mapped to at least one task.

### 5. Final Output

Save to `specs/{feature}/tasks.md`, then:

```
Tasks generated
├─ specs/{feature}/tasks.md
├─ Tasks: {total count} ({[P] count} parallelizable)
├─ Phases: {phase count}
├─ Coverage: FR {coverage}%, NFR {coverage}%
├─ Critic: 1 iteration complete
└─ Next step: /selfish:analyze (optional) or /selfish:implement
```

## Notes

- **Do not write implementation code**: Write task descriptions only. Actual code is the responsibility of /selfish:implement.
- **No over-decomposition**: Do not create separate tasks for single-line changes.
- **Accurate file paths**: Use paths based on the actual project structure (no guessing).
- **Use [P] sparingly**: Mark [P] only for truly independent tasks. When in doubt, keep sequential.
- **Dependencies unlock swarm**: explicit `depends:` enables /selfish:implement to use native task orchestration with automatic dependency resolution. Tasks without dependencies can be claimed by parallel workers immediately.
