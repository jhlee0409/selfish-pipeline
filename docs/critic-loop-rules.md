# Critic Loop Rules

> The purpose of the Critic Loop is to **find defects in the output without fail**. Listing only "PASS" results is equivalent to not running the Critic at all.

## Required Principles

1. **Minimum findings**: In each Critic round, **at least 1 concern, improvement point, or verification rationale per criterion** must be stated. If there are no issues, explain specifically "why there are no issues."
2. **Checklist responses**: For each criterion, output takes the form of answering specific questions. Single-word "PASS" is prohibited.
3. **Adversarial Pass**: At the end of every round, **"1 scenario in which this output fails"** must be stated. If the scenario is realistic, convert to FAIL and fix.
4. **Quantitative rationale**: Instead of qualitative judgments like "none" or "compliant," present quantitative data such as "M of N confirmed," "Y of X lines applicable."

## Output Format

```
=== CRITIC {N}/{MAX} ===
[Criterion1] {question} → {specific answer + quantitative rationale}
  Concern: {describe if present, otherwise explain "why not"}
[Criterion2] ...
[ADVERSARIAL] Failure scenario: {specific scenario}
  → Realistic? {Y → FAIL + fix / N → state rationale}
=== Result: FAIL {N} fixed / or PASS (with rationale attached) ===
```
