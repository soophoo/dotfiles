# CONTEXT

> Living notebook for this project. Read this before making any design decision. Update it whenever the shared understanding of the project changes — terms, boundaries, in-flight work, open questions.
>
> This file is **mutable**. Architectural decisions worth preserving go into `docs/adr/` as immutable ADRs.

## Project overview

<One paragraph: what this project is, who uses it, why it exists. Avoid marketing language — focus on the problem it solves.>

## Glossary — ubiquitous language

Terms used throughout the codebase. When a word means something specific *in this project* (different from common usage, or different from how a synonym is used), define it here.

| Term | Definition | Notes / synonyms to avoid |
|---|---|---|
| <Term> | <One-sentence definition in domain language.> | <e.g. "Don't call this a 'contract' — that's used for X."> |

## Bounded contexts / modules

| Module | Owns | Talks to (and how) |
|---|---|---|
| <name> | <aggregates / responsibilities> | <other modules via events / ports> |

## Current state

- **In flight:** <initiatives currently being worked on, with the person or team responsible if known>
- **On hold:** <work that is paused and why>
- **Recently shipped:** <last 1–3 significant changes, with date>

## Constraints

External or organisational constraints that influence design decisions (regulations, deadlines, legacy systems we must integrate with, performance SLOs, security boundaries).

- <Constraint> — <why it matters>

## Open questions

Things we have not yet decided. Each entry should name the question, what's blocking the answer, and (if known) who needs to be involved.

- [ ] <Question?> — blocked on <X> — needs input from <person/role>

## External references

| Resource | Purpose | Link |
|---|---|---|
| <Name> | <e.g. "production latency dashboard", "JIRA project for bugs"> | <url> |

## Architectural decisions

See `docs/adr/` for the full record. Quick index of accepted decisions:

- ADR 0001 — <title>
- ADR 0002 — <title>
