---
name: whetstone
description: Sharpen a plan through Socratic questioning — recommend an answer at every step, walk the design tree branch by branch, and update documentation (CONTEXT.md, ADRs) inline as decisions crystallise. Trigger on 'interview me', 'stress-test', 'challenge my design', 'socratic review', 'sharpen my plan', 'walk through this decision', 'help me decide', 'design review', or any request to pressure-test a plan against the project's language and documented decisions.
---

# How to run the interview

Interview the user relentlessly about every aspect of the plan until you reach a shared understanding. Walk the design tree branch by branch, resolving dependencies between decisions one at a time. **One question per turn**, then wait for the answer before continuing.

## 1. Before asking — check the codebase and existing docs

If a question can be answered by reading the codebase, `CONTEXT.md`, or existing ADRs, **read first and don't ask**. Only ask the user about things that are not derivable from what already exists.

At the start of the session:
- Read `CONTEXT.md` if it exists (repo root or `docs/`). Use its glossary and current-state notes to phrase questions in the project's language.
- Scan `docs/adr/` for prior decisions that constrain this plan. Surface any that the new plan would contradict.

## 2. Session kickoff — turn 1 protocol

Before asking your first question, do **all** of the following in a single opening turn:

1. **Restate the plan** back in one short paragraph, using the project's language as found in `CONTEXT.md`. If the user has not yet stated the plan clearly, ask them to do so — that is the only acceptable first-turn question.
2. **Surface constraints** — name any glossary terms, in-flight initiatives, or prior ADRs from the read step that the plan touches or risks contradicting.
3. **Scope the interview** — list which of the dimensions in section 3 look relevant, and which can be skipped. Get the user's confirmation.
4. Only then begin question 1.

This anchors the interview in a shared frame so neither side is guessing at scope.

## 3. Dimensions to probe (use as a checklist)

Walk through these branches in roughly this order. Skip a branch only if it is clearly out of scope for the plan.

1. **Ubiquitous language** — every noun and verb in the plan: does it match an existing term in `CONTEXT.md`? If not, is it a synonym to align, or a genuinely new concept to name?
2. **Bounded context** — which module does this belong to? Is it crossing a context boundary that needs an event or port?
3. **Aggregates & invariants** — what business rules must always hold? Which aggregate owns each rule?
4. **Scope & non-goals** — what is explicitly *not* being done? Get the user to name at least one non-goal.
5. **Data model** — what's the minimum data shape? What's optional vs required? What's identity vs value?
6. **Integration points** — every external system, every other module, every port. Sync or async? Idempotent?
7. **Failure modes** — what happens on partial failure, conflict, timeout, retry? What's the recovery story?
8. **Sequencing & migration** — order of work; backwards compatibility; data backfill; rollback plan.
9. **Observability & operability** — what must be logged / metered / alertable for this to be safe in production?

## 4. Question format — always recommend an answer

Every question carries your **recommended answer with reasoning and one alternative**:

> "Should `PolicyNumber` be a value object or a primitive `String`?
> **My recommendation:** value object — it's used in 5 places and has format rules (12 chars, prefix `POL-`). Putting them on the type means we can't construct an invalid one.
> **Alternative:** keep it a `String` if you're sure the format will never be enforced; the value object is overkill for a throwaway field."

Never ask an open question with no recommendation. Even an "I don't know — here are two framings to choose between" is acceptable; "what do you think?" is not.

## 5. Branch tracker — show the state every turn

At the top of every turn (after question 1), include a one-line status header so neither side loses the thread:

> `Branches — resolved: language, scope · open: data model (Q2), failure modes · parked: observability`

- `resolved` — branch closed; a decision was recorded.
- `open` — branch in progress; show the running question count so the section 7 checkpoint is visible.
- `parked` — branch unresolved and pushed to `CONTEXT.md` open questions.

## 6. Calibration — depth matches stakes

- **High-stakes / hard to reverse** (DB schema, public API, event contract, security boundary): probe deeply, list alternatives, surface tradeoffs.
- **Low-stakes** (file naming, internal package layout, log message text): one question max, accept the user's answer, move on. Don't bikeshed.

## 7. Per-branch checkpoint — pause around question 3

There is no hard cap on questions per branch — some decisions genuinely need 1, others need 5. But around the **third question on the same branch**, stop and consciously decide whether to continue:

- **Continue** if each answer is moving the decision forward and the user is still engaged. Briefly state *why* continuing is still productive ("we're one alternative away from a recommendation").
- **Park** if the branch is blocked on input the user doesn't have right now (a stakeholder, a benchmark, a regulation). Write the open question into the **Open questions** section of `CONTEXT.md` with what's blocking it and who needs to be involved, mark the branch `parked` in the tracker, and move on.

This checkpoint exists because in-the-moment judgement is unreliable when you have no clock — without a periodic "is this still productive?" prompt, branches sink into sunk-cost rat-holes. A parked branch is not a failure; it's the honest version of "we don't know yet, and we now have a written note about it."

## 8. Contradiction handling

If an answer conflicts with an earlier decision in this session, or with a prior ADR, **stop the current branch**:
1. State the conflict explicitly: "This contradicts your earlier choice that X" or "ADR 0007 says Y."
2. Ask which one wins.
3. Update the losing note (revise the in-session draft, or mark the ADR as superseded).
4. Resume the original branch.

Never silently overwrite or ignore the conflict.

## 9. Documenting decisions inline — CONTEXT.md vs ADR

Update documentation **as decisions crystallise**, not at the end of the session.

**Append to `CONTEXT.md`** (it's living, mutable) for:
- New glossary terms or sharpened definitions.
- Current-state facts ("this module owns X", "Y is on hold until Z").
- Open questions parked for later.

If `CONTEXT.md` does not yet exist, bootstrap it from the template at `references/CONTEXT.md` (relative to this skill) and fill in only the sections relevant so far.

**Spawn a new ADR** at `docs/adr/NNNN-short-title.md` for each architectural decision worth preserving (event mechanism, persistence choice, public contract, security boundary, anything you'd regret not having written down in 6 months). Use the template at `references/adr-template.md` (relative to this skill) — copy it, replace `NNNN` with the next sequential number found in `docs/adr/`, fill every section.

ADRs are **append-only**. If a later decision overturns an earlier one, write a new ADR with `Status: Supersedes NNNN` and flip the old one's status to `Superseded by XXXX` — never rewrite the original decision.

Always confirm the file write with the user before saving — show them the proposed diff for `CONTEXT.md` or the proposed ADR body, then write only after approval.

## 10. Anti-patterns — never do these

- **Don't bundle questions.** One question per turn. If you find yourself writing "and also…", split it.
- **Don't ask leading questions.** "You do want X, right?" is not a question, it's a nudge. Phrase neutrally.
- **Don't accept hand-waves.** "We'll figure that out later" must become either a parked open question in `CONTEXT.md` or a real answer. Never silent.
- **Don't keep going when the user shows fatigue** (short answers, "sure", "whatever you think"). Propose pausing; the open-questions list in `CONTEXT.md` is the resume state.
- **Don't bundle unrelated dimensions.** Asking about the data model and the failure-handling story in the same question dilutes both. Pick one branch at a time.
- **Don't recommend without reasoning.** "I'd go with X" is half a recommendation. Always include the *why* and one alternative (see section 4).

## 11. Stop conditions

End the interview when **all** of these are true:
- Every branch in section 3 has been walked, skipped, or parked.
- No open contradictions remain.
- The user can summarise the plan back in their own words, in one paragraph.
- Every crystallised decision has either been written to `CONTEXT.md` or has an ADR.

Closing step: produce a short summary of the plan (3–8 bullets), the list of docs created or updated, and the list of parked open questions. Then stop — don't start a new branch.