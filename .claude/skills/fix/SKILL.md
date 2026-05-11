---
name: fix
description: Fix a bug or missing feature using TDD — write failing test first, then fix, refactor, verify, beautify. Use when a bug is discovered or a feature doesn't work as expected.
---

# Fix

You are fixing a bug or a feature that doesn't behave as expected. Run the loop below in order. Do not skip steps.

If at any point you cannot identify the root cause after a reasonable effort (~15 minutes of focused work, or two failed hypotheses), stop and hand off to the `/diagnose` skill before continuing.

## 0. Frame the problem

Before touching code, get these in writing (in your reply):

- **Symptom**: what the user observes.
- **Expected**: what should happen instead.
- **Repro steps**: exact, minimal sequence that triggers it.
- **Scope**: which file/module/feature is suspected, and which are explicitly out of scope.

If any of these are missing or ambiguous, ask the user one focused question before proceeding. Do not guess.

## 1. RED — write a failing test that reproduces the bug

Non-negotiable. The fix does not begin until a test fails for the **right reason** (the bug itself), not for a missing import or a typo.

- Write **exactly one** test asserting the expected behavior.
- Run it. Show the user the failure output verbatim.
- The failure message must describe the bug. If it doesn't, the test is wrong — fix the test before touching production code.

### When a test genuinely cannot be written

Rare. Examples: pure visual/CSS bugs, animation timing, native platform glitches. In these cases:

1. State explicitly: "I cannot write an automated test for this because <reason>."
2. Document precise manual repro + manual verification steps in your reply.
3. Get user acknowledgement before proceeding.
4. Still add whatever automated coverage is possible adjacent to the fix (e.g., a snapshot, a unit test on the underlying logic).

Do not use this escape hatch for laziness. "It's hard to test" is not a reason.

## 2. Locate root cause

- Read the code around the failure. Trace the actual data flow, don't guess.
- Distinguish **where** it breaks from **why** it breaks. Patching the where is a workaround; fixing the why is a fix.
- If the cause is unclear after two hypotheses, hand off to `/diagnose`.

## 3. GREEN — minimal fix

- Smallest change that makes the new test pass at the root cause.
- Do not widen scope. If you spot unrelated issues, note them in your reply for follow-up — do not fix them now.
- Run the **full test suite**, not just the new test. Show it green.
- If a previously-passing test now fails, stop and address it before continuing.

## 4. REFACTOR — only while green

- Clean up the fix and immediate surrounding code if it improves clarity.
- Behavior must not change. Re-run the suite after each meaningful change.
- If nothing needs cleaning, say so and move on. Don't invent work.

## 5. Verify manually

For anything user-facing (UI, integration, API, CLI):

- Exercise the actual feature end-to-end, not just the unit test.
- Check the **golden path** and at least one **edge case** related to the bug.
- Watch for regressions in adjacent features.
- If you cannot run it (no dev server, no device, etc.), say so explicitly. Do not claim verification you didn't do.

## 6. Beautify

Run on changed files only:

- Linter / formatter for the language.
- Remove dead code, debug prints, commented-out blocks, and TODOs introduced while debugging.
- Remove comments that explain WHAT the code does — keep only ones that explain non-obvious WHY.
- Then invoke the `/simplify` skill on the changed files to catch bloat, premature abstractions, or duplication introduced during the fix.

## 7. Commit

Invoke the `/commit` skill to package the fix. The regression test from step 1 must be part of the commit — it is permanent protection against this bug returning.

## Hard rules

1. **No fix without a failing test first.** If a test truly cannot be written, document why and get explicit user acknowledgement.
2. **The reproducing test stays.** Never delete or weaken it to get green.
3. **No symptom patching.** No try/catch swallowing the error, no `if (broken) return early`, no disabled assertions, no mocking the thing under test.
4. **No `--no-verify`, no skipped hooks, no commented-out tests.** If a hook fails, fix the underlying issue.
5. **Don't widen scope.** One bug = one focused fix = one bisectable commit. Note unrelated issues separately for the user.
6. **Root cause, not workaround.** If you're patching at a layer above the bug, justify it explicitly to the user and get confirmation.

## Output format

Keep updates tight. A typical turn looks like:

> FRAME: bug = empty cart total shows `NaN` when all items removed; expected `0.00`. Suspect `cartTotal()` in `cart.ts`.
> RED: added `test_cart_total_is_zero_when_empty` — fails with `Expected "0.00" got "NaN"`.
> ROOT CAUSE: `reduce` with no initial value on empty array returns `undefined`, formatted as `NaN`.
> GREEN: added `0` initial value. Suite: 47 passed.
> REFACTOR: nothing worth changing.
> VERIFY: emptied cart in dev server — total shows `0.00`. Adding/removing items still works.
> BEAUTIFY: prettier clean. Ran /simplify — no issues flagged.
> Ready to /commit.

Do not narrate philosophy. Run the loop.
