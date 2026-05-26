---
name: diagnose
description: Disciplined diagnosis loop for hard bugs, failing specs, broken features, and performance regressions. Reproduce → isolate → hypothesise → instrument → fix → add regression test. Use when the user says "diagnose this" / "debug this", reports something broken/throwing/failing/flaky, suspects a regression, or says a feature doesn't match its specification.
---

# Disciplined Diagnosis

You are operating in **diagnosis mode**. The goal is to find the *root cause* — not to make the symptom go away. Speed comes from discipline, not from guessing.

If you are tempted to "just try a fix and see," stop. That is debugging-by-coincidence and it produces brittle patches that re-break later.

## The Loop

Run these phases in order. Do not skip ahead.

### 1. REPRODUCE — make the failure happen on demand

- Get a deterministic, minimal-effort way to trigger the failure: a command, a request, a test, a script.
- For flakes: run it in a loop until you see the failure rate. "Couldn't reproduce" is not a diagnosis — it is a missing reproduction.
- For perf regressions: capture a **measurement** (latency, memory, CPU, query count) with a number, not a vibe. Note the baseline and the regressed value.
- For spec mismatches: write down the expected behavior (from the spec) and the observed behavior, side by side.
- **Show the user the reproduction** before going further.

If you cannot reproduce, say so explicitly and ask the user for: exact command, input, environment, version/commit, timestamp. Do not proceed on assumption.

### 2. ISOLATE — shrink the surface

- Cut away everything that is not needed to trigger the failure: inputs, config, dependencies, code paths.
- For bugs: bisect — git bisect on commits, binary-search on inputs, comment-halving on code. Each cut should answer one question.
- For perf: profile first (flame graph, query log, allocator trace). Do not optimise without a profile.
- Stop when the reproduction is small enough that the cause is staring at you, or small enough to share.

### 3. HYPOTHESISE — name the suspected cause

- State the hypothesis as a concrete, falsifiable claim: *"X happens because Y is null when Z is called concurrently."*
- "It's probably a race condition" is not a hypothesis. Name the variables, the ordering, the line.
- List the top 1–3 candidates if unsure, ranked. Note what evidence would distinguish them.

### 4. INSTRUMENT — gather evidence to confirm or kill the hypothesis

- Add logging, asserts, breakpoints, query plans, traces — whatever proves or disproves the hypothesis directly.
- Prefer evidence that **could disprove** the hypothesis. If your instrumentation can only confirm, you are confirmation-biased.
- Re-run the reproduction. Read the evidence. If the hypothesis is wrong, return to step 3 — do not bend the data.
- Remove instrumentation before the final commit unless it earns its place.

### 5. FIX — change the smallest thing that addresses the root cause

- The fix targets the cause, not the symptom. If you are catching an exception to make it disappear, you are patching the symptom.
- Smallest viable change. No drive-by refactors, no "while I'm here" cleanups — those go in a separate change.
- Re-run the reproduction. It must now pass. Re-run the full suite. Nothing else regressed.

### 6. REGRESSION TEST — lock the fix in

- Add a test that **fails without your fix and passes with it**. Verify both directions: revert the fix, see the test go red; reapply, see it go green.
- For perf: add a benchmark or assertion on the metric (query count, allocation count, p95 latency) — not just "it feels faster."
- For spec mismatches: the test encodes the spec, not the current code's behavior.
- Without this step, the bug will return. The test is the deliverable.

## Hard rules

1. **No fix without a reproduction.** If you cannot trigger it, you cannot prove you fixed it.
2. **No fix without a named root cause.** "I changed X and it stopped failing" is not a diagnosis — it is a coincidence until you can explain *why*.
3. **No fix without a regression test.** Untested fixes rot.
4. **Don't blame "flakiness".** Flaky means "I haven't found the race yet." Treat it as a bug.
5. **Don't widen scope mid-diagnosis.** If you find a second bug, write it down and finish the first one. Mixing fixes hides which change did what.
6. **Performance work is measurement-driven.** No profile, no optimisation. "I think this is slow" is not evidence.
7. **Believe the evidence over the model.** If the data contradicts your mental model of the system, your model is wrong. Update it.

## Communicating with the user

Keep output tight. A typical turn looks like:

> REPRODUCE: `pytest tests/test_orders.py::test_concurrent_checkout` fails 4/10 runs with `IntegrityError: duplicate key`.
> ISOLATE: only fails when two checkouts hit the same cart row within ~5ms. Reduced repro to 30 lines.
> HYPOTHESIS: missing `SELECT ... FOR UPDATE` on cart row in `checkout_service.py:142` — both txns read the same stock count, both decrement, second insert collides on the unique index.
> INSTRUMENT: added query log; confirmed two `SELECT` then two `INSERT` interleaved with no row lock.
> FIX: added `with_for_update()` on the cart query (1 line).
> REGRESSION TEST: `test_concurrent_checkout_locks_cart_row` — 100/100 runs green; reverting the fix turns it red.

Do not narrate the philosophy of debugging. Run the loop.

## When to break frame

- **Production is on fire**: apply a documented mitigation (rollback, feature flag off, scale up) to stop the bleeding, then return to step 1 for the real diagnosis. Note what you did and that the root cause is still open.
- **The "bug" is a spec question**: if reproduction shows the code is doing what was asked and the spec is what's wrong, stop and ask the user — diagnosis is done, the next step is a spec decision, not a code change.
- **User explicitly wants a workaround, not a fix**: acknowledge it, apply the workaround, and leave a note (TODO + link to the open root cause) so it doesn't get forgotten.

In every other case, if you are tempted to skip a phase, you are wrong. Run the loop.
