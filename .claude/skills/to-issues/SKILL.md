---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable issues on the project issue tracker using tracer-bullet vertical slices. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues.
---

This skill takes an existing plan, spec, or PRD (from the current conversation, a linked document, or a file in the repo) and breaks it into a set of issues on the project's issue tracker. Do NOT re-interview the user about the feature — synthesize from what's already there.

The issue tracker (e.g. Linear, GitHub Issues, Jira) and any team/label vocabulary should have been provided to you. If the source PRD lives on the tracker, link the new issues back to it.

## Core principle: tracer-bullet vertical slices

A "tracer bullet" is the thinnest possible end-to-end slice that exercises every layer (UI → API → domain → persistence → infra) for one user-visible behavior. Each issue should be a vertical slice that can be picked up, implemented, reviewed, and merged independently — not a horizontal layer ("build the database schema", "build the API", "build the UI") that has no value until other tickets land.

Good slice properties:

- **Independently grabbable** — any developer can pull it off the backlog without waiting on another in-flight ticket. Dependencies are explicit and already merged, not implied.
- **End-to-end** — touches every layer needed to demonstrate the behavior, even if other behaviors in the same layer are stubbed.
- **User-visible or behavior-visible** — completing the issue moves a user story (or a clearly-scoped technical capability) from "doesn't work" to "works".
- **Small** — ideally 0.5–2 days of work. If it's bigger, split it.
- **Testable on its own** — has a clear acceptance criterion that can be verified without the rest of the epic landing.

Anti-patterns to avoid:

- Layer-by-layer breakdowns ("schema", "repository", "service", "controller", "screen").
- "Setup" or "scaffolding" tickets with no user-visible outcome — fold setup into the first slice that needs it.
- Tickets that say "and then we'll figure out X" — resolve the unknown first or scope it out.
- Mega-tickets that bundle multiple user stories.

## Process

1. **Locate the source.** Identify the PRD/plan/spec being decomposed. If it's an issue on the tracker, read it. If it's in the conversation, use it directly. Confirm the scope with the user in one sentence before writing issues.

2. **Identify the walking skeleton.** What is the smallest possible end-to-end slice that proves the architecture works? This becomes the first issue. Subsequent slices add behavior on top.

3. **List the vertical slices.** For each user story (or coherent group), draft one slice. Sequence them so each builds on the previous, but each is still independently mergeable (the previous slice can be in `main` before the next is started).

4. **Check with the user.** Show the proposed slice list (titles + one-line descriptions + dependency order) and confirm before creating issues. This is the only checkpoint — don't drip-feed.

5. **Create the issues** on the tracker using the template below. Apply the project's standard triage label (e.g. `needs-triage`) and link each issue back to the parent PRD. If the tracker supports parent/sub-issue or epic relationships, use them.

<issue-template>

## Slice

One sentence: the user-visible (or behavior-visible) outcome this slice delivers. Example: "User can submit the contact form and see a success message; submissions are persisted but no notification is sent yet."

## Why this slice

Which user story or capability from the parent PRD this advances, and why it's a useful standalone increment.

## Acceptance criteria

A short bulleted checklist of observable behaviors that must be true when this is done. Written so a reviewer can verify them without reading the implementation.

- [ ] ...
- [ ] ...

## Scope

**In scope** — what this issue touches across the stack to deliver the slice.

**Out of scope** — what is intentionally deferred to a later slice. Link the follow-up issue if it exists.

## Dependencies

Other issues that must be merged before this one can start. If none, say "None — can start immediately."

## Notes

Anything implementation-relevant the picker should know: prior art in the codebase, ADRs to respect, modules likely to be touched, gotchas. Do NOT include file paths or code snippets — they go stale fast. Defer detailed design to the picker.

</issue-template>

## After creating the issues

Report back to the user with the list of created issue links and the suggested order of execution. Flag any slices you weren't sure how to scope so they can adjust.
