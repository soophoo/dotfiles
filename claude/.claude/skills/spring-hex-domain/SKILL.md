---
name: spring-hex-domain
description: Organize the domain layer of a Java Spring Boot hexagonal project — dedicated folders for aggregates, entities, value objects, enumerations, domain events, exceptions, domain services, and policies / specifications. Trigger on 'domain model', 'aggregate', 'aggregate root', 'value object', 'enum' / 'enumeration', 'entity', 'domain service', 'domain event', 'invariant', 'specification', 'DDD building blocks', or any request to design, refactor, or review code inside a `domain/` package.
---

# Domain layer — one concept per folder

This skill defines **what goes inside `domain/`** and how to organize it. For where `domain/` sits in the project, see `spring-hex-structure`.

## Folder layout

```
domain/
├── aggregate/       ← aggregate roots (one folder per aggregate if large)
├── entity/          ← non-root entities
├── valueobject/     ← immutable value objects
├── enumeration/     ← domain enums
├── event/           ← domain events
├── exception/       ← domain-specific exceptions
├── service/         ← domain services
└── policy/          ← reusable business rules / specifications
```

Never lump everything into a single `model/` package. Each concept gets its own folder so files stay short and intent is obvious from the path.

## Rules per folder

- **`aggregate/`** — aggregate roots only. One file per root. If a root grows complex, give it its own subfolder (`aggregate/policy/Policy.java`, `aggregate/policy/PolicyLine.java`) so its internals are grouped together. Aggregates enforce their own invariants; mutators must keep the aggregate valid.
- **`entity/`** — non-root entities that belong to an aggregate but are not the root. Identity-based equality.
- **`valueobject/`** — immutable types with value semantics (`Money`, `Email`, `PolicyNumber`, `DateRange`). Always Java `record` or final class with `equals`/`hashCode` on all fields. **Never has an identity.** Validate inputs in the canonical constructor — invalid value objects must not exist.
- **`enumeration/`** — enums modelling closed sets (`PolicyStatus`, `ClaimType`). Behavior allowed (methods on enum constants), but no framework annotations. Persistence mapping to strings/ints happens in the persistence adapter, not the enum itself.
- **`event/`** — past-tense domain events (`PolicyCreated`, `ClaimSettled`), one per file. Records carrying only domain-typed fields. See `spring-hex-events` for publishing/subscribing.
- **`exception/`** — checked or unchecked exceptions expressing domain rule violations (`PolicyAlreadyCancelledException`). One per rule. Never a generic `DomainException` catch-all.
- **`service/`** — stateless domain services for logic that spans multiple aggregates and doesn't fit on any one of them. Pure classes, no `@Service` annotation, no Spring.
- **`policy/`** — reusable business rules / specifications. A `PolicyRule` or `Specification<T>` style class belongs here, not inline inside an aggregate when it is reused across aggregates or use cases.

## Hard constraints on every domain file

- Zero imports from `org.springframework.*`, `jakarta.persistence.*`, `com.fasterxml.jackson.*`, or any `application`/`infrastructure` package.
- No `@Entity`, `@Id`, `@Column`, `@JsonProperty`, `@Component`, `@Service`, etc.
- No JPA-style empty constructors "for the framework"; if persistence needs that, it lives on a separate `*JpaEntity` in the persistence adapter.
- Domain objects expose **behavior**, not just getters/setters. Mutations go through methods named after business operations (`policy.cancel(reason)`), not `setStatus(CANCELLED)`.

## Rule of thumb

If you're tempted to put two unrelated concepts in the same file or folder, split them. Folder names are part of the ubiquitous language; choose them carefully and keep them consistent across feature modules.
