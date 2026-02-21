---
name: selfish:spec
description: "Generate feature specification"
argument-hint: "[feature description in natural language]"
model: sonnet
---
# /selfish:spec — Generate Feature Specification

> Converts a natural language feature description into a structured specification (spec.md).
> Operates on pure prompts without external scripts.

## Arguments

- `$ARGUMENTS` — (required) Feature description in natural language

## Project Config (auto-loaded)

!`cat .claude/selfish.config.md 2>/dev/null || echo "[CONFIG NOT FOUND] .claude/selfish.config.md not found. Create it with /selfish:init."`

## Config Load

**Always** read `.claude/selfish.config.md` first (read manually if not auto-loaded above). Abort if config file is missing.

## Execution Steps

### 1. Set Up Feature Directory

1. Check **current branch** → `BRANCH_NAME`
2. Determine **feature name**:
   - Extract 2-3 key keywords from `$ARGUMENTS`
   - Convert to kebab-case (e.g., "add user authentication" → `user-auth`)
3. **Create directory**: `specs/{feature-name}/` (create parent `specs/` directory if it does not exist)
4. If already exists, confirm with user: "Overwrite existing spec?"

### 2. Explore Codebase

Before writing the spec, understand the current project structure:

1. Check key directories by `{config.architecture}` layer
2. Explore existing code related to the feature description (Grep/Glob)
3. Identify related type definitions, APIs, and components

### 3. Write Spec

Create `specs/{feature-name}/spec.md`:

```markdown
# Feature Spec: {feature name}

> Created: {YYYY-MM-DD}
> Branch: {BRANCH_NAME}
> Status: Draft

## Overview
{2-3 sentences on the purpose and background of the feature}

## User Stories

### US1: {story title} [P1]
**Description**: {feature description from user perspective}
**Priority rationale**: {why this order}
**Independent testability**: {whether this story can be tested on its own}

#### Acceptance Scenarios
- [ ] Given {precondition}, When {action}, Then {result}
- [ ] Given {precondition}, When {action}, Then {result}

### US2: {story title} [P2]
{same format}

## Requirements

### Functional Requirements
- **FR-001**: {requirement}
- **FR-002**: {requirement}

### Non-Functional Requirements
- **NFR-001**: {performance/security/accessibility etc.}

### Key Entities
| Entity | Description | Related Existing Code |
|--------|-------------|-----------------------|
| {name} | {description} | {path or "new"} |

## Success Criteria
- **SC-001**: {measurable success indicator}
- **SC-002**: {measurable success indicator}

## Edge Cases
- {edge case 1}
- {edge case 2}

## Constraints
- {technical/business constraints}

## [NEEDS CLARIFICATION]
- {uncertain items — record if any, remove section if none}
```

### 4. Critic Loop (1 pass)

> **Always** read `docs/critic-loop-rules.md` first and follow it.

After writing, perform a **self-critique loop** once:

```
=== CRITIC PASS 1/1 ===
[COMPLETENESS]  Does every User Story have acceptance scenarios? Are any requirements missing?
[MEASURABILITY] Are the success criteria measurable, not subjective?
[INDEPENDENCE]  Are implementation details (code, library names) absent from the spec?
[EDGE_CASES]    Are at least 2 edge cases identified? Any missing boundary conditions?
```

- **On FAIL**: auto-fix spec.md → notify user of changes
  - e.g., `⚠ COMPLETENESS: US3 missing acceptance scenarios. Adding...`
- **ALL PASS**: display `✓ Critic passed`
- Complete FAIL → fix → re-validate cycle before proceeding to the next step

### 5. Final Output

```
Spec generated
├─ specs/{feature-name}/spec.md
├─ User Stories: {count}
├─ Requirements: FR {count}, NFR {count}
├─ Unresolved: {[NEEDS CLARIFICATION] count}
└─ Next step: /selfish:clarify (if unresolved) or /selfish:plan
```

## Notes

- Do **not** write implementation details in the spec. Expressions like "manage with Zustand" belong in plan.md.
- Specify **actual paths** for entities related to existing code.
- If `$ARGUMENTS` is empty, ask user for a feature description.
- Do not pack too many features into one spec. Suggest splitting if User Stories exceed 5.
