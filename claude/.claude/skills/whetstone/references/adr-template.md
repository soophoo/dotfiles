# ADR NNNN: <Short imperative title — e.g. "Use the transactional outbox pattern for inter-module events">

Date: <YYYY-MM-DD>
Status: Accepted

> Status values: **Proposed** (under discussion) → **Accepted** (in force) → **Deprecated** (still in code but not for new work) → **Superseded by ADR XXXX** (replaced).
>
> ADRs are **append-only**. Never edit an Accepted ADR to change the decision — write a new ADR with `Status: Supersedes NNNN` and update the old one's status to `Superseded by XXXX`.

## Context

What problem are we facing? What forces are at play (technical, organisational, regulatory, performance, team skill)? What was already in place before this decision?

Keep this section factual — describe the situation, not the solution.

## Decision

What did we choose to do? Phrase as a single, unambiguous statement of action.

If the decision has non-obvious implications (e.g. "all event publishers must go through an outbound port"), state them here too.

## Consequences

- **Easier:** <what this unlocks or simplifies>
- **Harder / cost:** <what this makes more painful, what we now have to maintain>
- **New risks:** <failure modes, operational concerns, future migration cost>

Be honest about the downsides — that's the whole point of an ADR.

## Alternatives considered

- **<Option A>** — rejected because <reason>.
- **<Option B>** — rejected because <reason>.
- **Do nothing / keep status quo** — rejected because <reason>.

At least one alternative must be listed. If you can't think of one, the decision probably wasn't worth recording.

## References

- Related ADRs: <e.g. supersedes 0004, depends on 0007>
- External links: <RFCs, blog posts, internal docs that influenced the decision>
