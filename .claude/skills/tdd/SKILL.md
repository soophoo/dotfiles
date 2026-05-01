---
name: tdd
description: Drive implementation with a strict red-green-refactor TDD loop — write a failing test first, make it pass with the minimum code, then refactor. Use when the user explicitly asks for TDD, test-first development, or red-green-refactor — or when reproducing a bug with a failing test before fixing. Skip for exploratory/throwaway code.
---

# Strict TDD

You are operating in **strict TDD mode**. The rules below are non-negotiable for the duration of the task. If the user asks you to skip a step, push back once and ask them to confirm — only then proceed.

## The Loop

For every behavior change, you must complete these phases in order:

### 1. RED — write one failing test

- Write **exactly one** new test that describes the smallest next piece of behavior.
- The test must fail for the **right reason** (assertion failure or missing symbol — not a syntax error or unrelated crash).
- Run the test and **show the user the failure output** before moving on.
- Do not modify production code in this phase. The only exception: adding the minimum stub (empty function, undefined export) needed for the test file to load — and only if the language requires it to compile.

### 2. GREEN — minimum code to pass

- Write the **least** code that makes the failing test pass. "Obvious" implementation is fine; speculative generality is not.
- Do not add code paths, error handling, parameters, or abstractions that no test exercises.
- Run the **full test suite** (not just the new test) and show it green before moving on.
- If a previously-passing test now fails, stop and address it before continuing.

### 3. REFACTOR — clean up, tests still green

- Improve names, remove duplication, extract helpers — **without changing behavior**.
- Re-run the full suite after each meaningful change.
- If you don't see anything worth refactoring, say so explicitly and move on. Don't invent work.

Then return to RED for the next behavior.

## Hard rules

1. **No production code without a failing test.** If you catch yourself about to edit a non-test file and there is no red test driving the change, stop.
2. **One test at a time.** Don't write a batch of tests up front.
3. **Show the failure, then show the pass.** The user must be able to see the red→green transition in your output. Use real test runner output, not prose claims.
4. **Bug fixes start with a reproducing test.** Before touching the buggy code, write a test that fails because of the bug. Then fix.
5. **Refactors stay green.** If you're refactoring (no behavior change), the suite must pass before, during (after each step), and after.
6. **Don't delete or weaken tests to get to green.** If a test is wrong, say so explicitly and get user confirmation before changing it.

## Picking the next test

- Start with the simplest case that forces the smallest piece of real behavior — often a degenerate or boundary input.
- Prefer tests that fail for a missing behavior over tests that fail for a missing type/signature.
- One assertion per test when practical; group related assertions only when they describe one behavior.

## Communicating with the user

Keep output tight. A typical turn looks like:

> RED: added `test_parses_empty_input` — fails with `AssertionError: expected [] got None`.
> GREEN: implemented `parse` to return `[]`. Suite: 12 passed.
> REFACTOR: nothing to clean up yet.
> Next: handle a single token.

Do not narrate the philosophy of TDD. Just run the loop.

## When to break frame

These — and only these — are reasons to step outside the loop:

- **Spike**: user explicitly asks for a throwaway exploration. Mark it as a spike, then delete or rewrite it under TDD.
- **Setup work**: creating the test file, installing the test runner, configuring CI. No behavior, no test required.
- **Pure refactor**: behavior-preserving cleanup with the suite already green.

In every other case, if you're tempted to skip RED, you're wrong. Write the test.
