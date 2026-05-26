---
name: tdd
description: Practice Test-Driven Development — red/green/refactor cycle, the three implementation strategies for going green, test-first discipline, AAA structure, picking the next test, FIRST properties, behavior-not-implementation, sensible use of test doubles, test data builders, outside-in vs inside-out, the test pyramid, TDD for bug fixes, legacy code with characterization tests, and the anti-patterns that quietly destroy a test suite. Trigger on 'TDD', 'test-driven', 'test first', 'red green refactor', 'write the test first', 'failing test', 'fake it', 'triangulation', 'characterization test', 'legacy code', 'how to test', 'mock vs stub', 'test data builder', 'object mother', 'test pyramid', 'test design', 'test smell', or any request to write a feature or fix a bug using a test-first workflow.
---

# Test-Driven Development

Language- and framework-agnostic. For Spring Boot + hexagonal specifics (per-layer test types, port/adapter TDD, event-flow TDD), see `tdd-spring-hex`.

## 1. The cycle — Red, Green, Refactor

1. **Red** — write the smallest failing test that names the next behavior. Run it. Confirm it fails for the *right reason* (not a compile error, not a typo).
2. **Green** — write the **least** production code that makes the test pass. It's allowed to be ugly, hardcoded, even obviously wrong-for-the-general-case. The goal is the bar going green.
3. **Refactor** — with all tests green, improve the design: rename, extract, deduplicate, generalise. **No new behavior.** When the refactor changes external behavior, it's a new cycle, not a refactor.

Loop. Each cycle is minutes, not hours. If a cycle is taking longer than ~10 minutes, the step was too big — back out and split it.

**Commit cadence.** Commit on every green bar, and again after each successful refactor. Tiny diffs make `git bisect` trivial and let you `git reset --hard` to the last green when an experiment fails. A red working copy should never be committed.

## 2. The three implementation strategies for going green

When the bar is red, you have exactly three ways to make it green (Kent Beck). Pick consciously.

- **Fake It (till you make it)** — return a hardcoded constant that satisfies the current test. Then write a second test that forces the constant to become a real implementation. Use when the right code isn't obvious yet.
- **Obvious Implementation** — type the real code in directly. Use when the implementation is small, well-understood, and you'd be wasting your own time pretending otherwise.
- **Triangulation** — when neither of the above is comfortable, write a **second test** that forces a generalisation. The production code abstracts only when two tests demand it. Use when the design is unclear and you want the tests to pull the abstraction out.

Default order: try Obvious Implementation. If the typing hand hesitates, fall back to Fake It. If after one fake the next step is still unclear, triangulate. **Never speculate** — don't write code that no failing test demands. That's the cardinal rule the strategies enforce.

## 3. Test-first is non-negotiable

The test is written **before** the production code that satisfies it. If you find yourself writing production code without a failing test pointing at it, stop and write the test.

Why: writing the test first forces you to specify the interface from the *caller's* perspective before you commit to an implementation. Writing tests after is verification; writing tests first is design.

## 4. Test structure — Arrange / Act / Assert

Every test, three sections, visually separated:

```
// Arrange — set up the world the test needs
// Act — perform the single operation under test
// Assert — verify the outcome
```

- **One logical assertion per test.** Multiple `assertThat` calls are fine if they're all checking facets of the same outcome; multiple unrelated checks mean you have multiple tests crammed into one.
- **Naming:** `should_<expected>_when_<condition>` or `<method>_<state>_<expectedResult>`. The name alone should tell the reader what's being verified.
- No conditionals, no loops, no try/catch (except when asserting on a thrown exception). If a test has branches, it isn't one test.

## 5. Picking the next test — what to write next

When the question is *"what's the next test?"*, walk this order:

1. **The happy path.** One small, representative case where the feature works end-to-end through the unit. Get it green before anything else.
2. **One test per equivalence class.** Inputs that the code treats the same way go in the same class — pick one representative per class. (E.g. "policy is active", "policy is cancelled", "policy is pending".)
3. **Boundaries.** Off-by-one, empty collection, null / `Optional.empty()`, zero, max, min, the day-of-week wrap-around. Bugs live at boundaries.
4. **Error classes.** Each way the unit can fail — invalid input, missing collaborator, conflict, timeout — becomes its own test asserting the **specific** exception/result, not a generic "throws".
5. **One example per non-obvious invariant** the unit must preserve.

Stop when adding another test does not change the production code. That's the signal the unit is fully specified.

## 6. FIRST properties

- **Fast** — milliseconds per unit test. A slow suite stops being run.
- **Independent** — any test runs alone, in any order. No shared mutable state between tests. Use fresh fixtures.
- **Repeatable** — same input, same result, always. No clocks, no random, no network — inject them.
- **Self-validating** — pass/fail is binary. No "check the log to see if it worked".
- **Timely** — written immediately before the production code, not days later.

## 7. Test behavior, not implementation

- Test what the unit *does* (its observable outcomes and the messages it sends to its collaborators), not *how* it does it.
- Never test private methods directly. If a private method needs its own test, it probably wants to be public on a new class.
- Never assert on internal fields, internal call counts, or specific call ordering — unless that ordering *is* the behavior (e.g. "must lock before writing").
- A test that breaks during a pure refactor was testing implementation, not behavior. Rewrite it.

## 8. Test doubles — pick the right kind

**The position on mocking.** The slogan "mocking is bad" oversimplifies a real debate. The truth:

- **Over-mocking is bad** — heavy mock setup makes tests mirror the production code's structure, so tests break on every refactor even when behavior is preserved. The test was testing implementation, not behavior.
- **Mocks can pass while production fails** — stubbed return values never exercise the real query, the real serialization, the real failure modes.
- **Mocks are still legitimate for two things:** (a) verifying *commands* sent to collaborators (e.g. "did the use case publish the right event?" — unobservable any other way), and (b) replacing **true external boundaries** that break FIRST (clock, randomness, network, broker, third-party HTTP).
- **Prefer real domain objects** over mocked ones — they're cheap to construct and round-trip real data.
- **Prefer fakes** (in-memory repo, in-memory bus) over chains of mocks at port boundaries when you'd otherwise need 5+ stubs.
- **Never mock value objects, records, enums, or pure domain types.** They have no behavior to stub; just construct the real one.
- **Heavy mocking is a design smell, not a test smell.** A unit needing 5 mocks is doing too much. Redesign the unit (extract value object, collapse collaborators, push behavior into domain) — don't write more mocks.

Rule of thumb: **stub queries, mock commands, fake ports, construct domain.** Mock at seams, not between every collaborator inside the unit.

| Kind | Use when | Smell when overused |
|---|---|---|
| **Stub** | The collaborator returns a value the unit consumes (a query). | — |
| **Mock** | The unit's behavior *is* the call it makes (a command). | Mocking everything → tests pass while production breaks. The unit has too many collaborators. |
| **Fake** | A working lightweight implementation (in-memory repo, in-memory queue). | — |
| **Spy** | You need to verify *and* let the real method run. | Almost never the right choice — usually means the seam is wrong. |
| **Dummy** | A required argument the unit doesn't touch. | — |

## 9. Test data builders & fixture factories

As features grow, test setup explodes. Three patterns keep tests readable:

- **Test data builder** — a fluent builder per aggregate / value object exposing sensible defaults and only the fields the test cares about:
  ```
  Policy policy = aPolicy()
      .withStatus(ACTIVE)
      .withHolder(aCustomer().withName("Alice"))
      .build();
  ```
  Defaults make tests focus on the **one** field that matters; the builder's existence removes the need to construct full graphs per test.
- **Object Mother** — named factory methods for canonical fixtures: `aValidPolicy()`, `anExpiredPolicy()`, `aPolicyWithUnpaidPremium()`. Use when the same fixture appears in 3+ tests and a builder would still be verbose. Combine freely with builders: `anExpiredPolicy().withHolder(...).build()`.
- **In-memory fakes** as port implementations (`InMemoryPolicyRepository`) — let tests round-trip real domain objects through the port interface, replacing chains of stubs.

Live builders and Object Mothers in a `testfixtures/` package alongside production code so any test module can reuse them. **No business logic in fixtures** — only construction.

If a test still needs 20 lines of setup with builders in place, the unit is doing too much. Redesign the unit, not the fixture.

## 10. Outside-in vs inside-out

Both are TDD; pick per task.

- **Outside-in** — start with a failing acceptance test at the system boundary (HTTP, CLI, message handler). Drive inward, discovering collaborators as fakes/mocks, writing unit tests for each as it appears. Best when the feature has a clear external trigger. The opening acceptance test is the **walking skeleton** (Freeman & Pryce): minimal end-to-end thread, stays red until the whole feature works.
- **Inside-out** — start at the smallest pure unit and grow outward, composing tested pieces. Best when the domain logic is the hard part and the boundary is trivial.

Don't mix in one session — choose, run, deliver. Switch directions next session if needed.

## 11. The test pyramid

Many fast tests at the bottom; few slow tests at the top.

- **Unit tests (base, broad)** — domain logic, pure functions, application services with mocked outbound ports. Milliseconds. Hundreds to thousands.
- **Integration tests (middle, narrower)** — one adapter against the real thing (DB via Testcontainers, broker, third-party API via WireMock). Seconds. Dozens.
- **End-to-end / acceptance tests (tip, narrowest)** — the system as a black box. Tens of seconds. A handful — one per critical user journey.

Symptoms of an inverted pyramid (ice-cream cone): slow suite, flaky CI, bugs caught only at the end-to-end level, developers stop running tests locally. Push assertions *down* the pyramid whenever you can: if a behavior can be tested at the unit level, don't also test it at the integration level — duplicate coverage at higher cost.

## 12. Coverage is a smell-detector, not a goal

- Use coverage to *find* untested code.
- Never set a coverage *target*. 100% coverage with poor assertions is worse than 70% with sharp ones.
- A line being covered does not mean its behavior is asserted. Mutation testing (PIT, Stryker) is the honest measure if you really want one.

## 13. TDD for bug fixes

1. Reproduce the bug as a **failing test** before touching production code.
2. Confirm the test fails for the bug's reason (not a typo).
3. Fix the production code; test goes green.
4. Refactor if needed.

The test now stands as a regression guard. Skipping step 1 is the most common cause of repeat-regressions.

## 14. Legacy code — characterization first, TDD second

You cannot TDD untested legacy. Apply Michael Feathers' loop:

1. **Identify a change point** in the legacy code.
2. **Find seams** — places where you can intercept behavior without rewriting (constructor injection, sprout method, sprout class, extract interface).
3. **Pin current behavior with characterization tests** — record what the code *actually does today*, not what it should do. These tests are descriptive, not prescriptive.
4. **Refactor under the characterization tests** until you have a tested seam.
5. **Now TDD the change** through that seam.

A failing characterization test means *behavior changed*, not that the code is wrong. Decide consciously which one to update.

## 15. Test smells — fix when you see them

- **Mock-heavy tests** that re-encode the production code's structure → the unit has too many collaborators; redesign.
- **Tests that need rewriting on every refactor** → testing implementation, not behavior.
- **Slow tests in the unit suite** → wrong test type; move to integration, or isolate the slow collaborator behind a seam.
- **Ignored / `@Disabled` tests** → fix or delete. A disabled test rots and lies.
- **Snapshot-everything tests** that assert on huge blobs → no one reads the diff; brittle. Assert on the specific facets that matter.
- **Tests that print** instead of assert → not self-validating; fail the FIRST check.
- **Order-dependent tests** → shared state somewhere; find it and remove it.
- **Asserting on log messages** → unless the log *is* the contract, this couples to formatting and breaks on translation.
- **Test names that don't describe a behavior** (`test1`, `testFoo`) → unreadable suite.
- **Setup that dwarfs the act/assert** even with builders in place → the unit is doing too much (see §9).
- **Speculative tests** asserting behavior the production code doesn't yet need → violates "no code without a failing test demanding it" (see §2).

## 16. When NOT to do TDD

- **Exploratory spikes** — when you don't yet know what to build or how the API should look. Hack, learn, **then delete the spike** and TDD the real thing.
- **Throw-away prototypes** for a demo or a proof of concept that will not survive the week.
- **Learning a new library or API** — write a learning test for the library, but don't pretend you're TDDing your own code yet.

In all three cases, the discipline returns the moment the code is going to live. Spike code that survives untested is the most expensive kind of code.
