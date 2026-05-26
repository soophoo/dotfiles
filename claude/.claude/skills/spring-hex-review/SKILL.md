---
name: spring-hex-review
description: Review and test a Java Spring Boot hexagonal codebase — per-layer testing strategy, scaffold/refactor workflow, and architectural red flags. Trigger on 'review architecture', 'architectural violations', 'audit code', 'hexagonal review', 'test strategy', 'per-layer tests', '@DataJpaTest', '@WebMvcTest', 'testcontainers', 'refactor a god class', or any request to verify a Spring Boot hexagonal project is structurally sound before merge.
---

# Reviewing & testing a hexagonal Spring Boot codebase

Companion to `spring-hex-structure`, `spring-hex-domain`, `spring-hex-ports-adapters`, and `spring-hex-events`. Use those when *building*; use this one when *checking*.

## 1. Testing per layer

- **`domain/**`** → plain JUnit, no Spring context, no mocks of framework classes. Fast, run on every build. If a domain test needs Mockito, the domain probably has a hidden infrastructure dependency — fix that first.
- **`application/**`** → JUnit + Mockito mocking outbound ports. Verify use-case orchestration and that domain invariants are honored. **No `@SpringBootTest`** — the application layer is framework-free by design.
- **`infrastructure.adapter.out.persistence`** → `@DataJpaTest` with **Testcontainers** for the real DB engine. H2 in place of Postgres lies about behavior; don't use it.
- **`infrastructure.adapter.in.rest`** → `@WebMvcTest` with mocked inbound port. Validate request/response shapes, status codes, validation messages.
- **`infrastructure.adapter.in.messaging` / `out.messaging`** → integration tests with Testcontainers (broker) when applicable. See `spring-hex-events` for outbox testing.
- **Aggregator module** → one `@SpringBootTest` smoke test confirming the context loads. One per module is enough.

## 2. Refactor workflow — when splitting a class that mixes concerns

Apply in this order:
1. Pull domain logic into pure classes first (no annotations, no Spring).
2. Extract an outbound port for every external dependency (DB, HTTP client, message broker, clock, random).
3. Move framework code into adapters that implement those ports.
4. Move HTTP/messaging entry points into inbound adapters that call inbound ports.
5. Delete the original class.

Don't try to do all five at once — each step should compile and pass tests.

## 3. Architectural red flags — block the PR

Imports / annotations in the wrong place:
- `@Entity`, `@Table`, `@Column`, `@Id` on a domain class.
- `@Component`, `@Service`, `@Autowired`, `@Value` anywhere in `domain/**`.
- A domain class importing `org.springframework.*`, `jakarta.persistence.*`, `com.fasterxml.jackson.*`.
- `application/**` importing `jakarta.persistence.*`, any JPA repository, any `*JpaEntity`, any HTTP DTO, or any concrete adapter class.

Wiring smells:
- A `@Service` injecting a Spring Data `JpaRepository` directly (must go through an outbound port).
- A controller injecting a `@Service` instead of a `*UseCase` interface.
- A `@KafkaListener` / `@EventListener` containing business logic instead of delegating to a use case.
- An outbound port returning a JPA entity, a `ResponseEntity`, or an HTTP DTO.
- An inbound port accepting a JPA entity or an HTTP DTO instead of a command/query record.

Module-level smells:
- A feature module depending on another feature module in `pom.xml` (cross-context coupling must go through events or a dedicated port — see `spring-hex-events`).
- The aggregator module containing business code.
- A feature module depending on the aggregator.

Domain smells:
- Anemic aggregates — only getters/setters, no behavior methods.
- Value objects with identity, or mutable value objects.
- A catch-all `DomainException` instead of named rule violations.
- Two unrelated concepts sharing a file or folder inside `domain/`.

Events / messaging smells:
- A use case injecting `ApplicationEventPublisher` or `KafkaTemplate` directly instead of an outbound `*EventPublisher` port.
- Publishing to a broker inside the same transaction as the DB write, with no outbox.
- A listener importing the producer module's event class instead of defining/sharing a typed contract.

## 4. Review checklist (run top-to-bottom)

1. Does each feature module have only `domain` / `application` / `infrastructure` at its root?
2. Is the dependency rule respected? (`grep` `domain` for forbidden imports.)
3. Does every use case have an inbound port? Does every external dependency have an outbound port?
4. Are JPA entities separate from domain classes, with a mapper?
5. Do cross-module interactions go through events, never direct calls?
6. Are domain tests Spring-free? Are persistence tests using Testcontainers (not H2)?
7. Are there any of the red flags above?
