---
name: tdd-spring-hex
description: Apply Test-Driven Development to a Java Spring Boot hexagonal modular monolith — which test type belongs at which layer (domain / application / persistence / REST / messaging), how to TDD a use case through its port, how to TDD a persistence or client adapter, and how to TDD a domain event end-to-end through publisher and listener. Trigger on 'TDD a use case', 'TDD a port', 'TDD an adapter', 'TDD a controller', 'TDD a repository', 'TDD a domain event', 'hexagonal test', 'test first hexagonal', 'JUnit 5 Spring Boot', 'AssertJ', 'Mockito', 'MockMvc', '@DataJpaTest', '@WebMvcTest', 'Testcontainers', or any request to write tests first against a hexagonal Spring Boot codebase.
---

# TDD on a Spring Boot hexagonal codebase

Builds on `tdd` (universal cycle, doubles, anti-patterns) and `spring-hex-structure` / `spring-hex-domain` / `spring-hex-ports-adapters` / `spring-hex-events` / `spring-hex-review` (the architecture this assumes). Read those first if the terms `port`, `adapter`, `aggregate`, or `outbox` are unfamiliar.

## 1. Test type per hexagonal layer

| Layer | Test type | Tools | What to assert |
|---|---|---|---|
| `domain/**` | Plain JUnit unit test | JUnit 5 + AssertJ | Invariants, behavior of aggregates, value-object validation, domain-service logic. **No Spring context, no mocks of framework classes.** |
| `application/service/**` | Plain JUnit unit test with mocked **outbound ports** | JUnit 5 + Mockito + AssertJ | Use-case orchestration: correct domain calls, correct outbound port interactions, correct command/event publication. **No `@SpringBootTest`.** |
| `infrastructure.adapter.out.persistence` | Persistence slice test | `@DataJpaTest` + Testcontainers (the real DB engine, never H2 as a Postgres stand-in) | JPA mapping, query correctness, mapper round-trip. |
| `infrastructure.adapter.in.rest` | Web slice test | `@WebMvcTest` + MockMvc, with the inbound port mocked | HTTP status, request validation, JSON shape, error translation. |
| `infrastructure.adapter.in.messaging` / `out.messaging` | Integration test | Testcontainers (Kafka / Rabbit) + Spring slice | Listener wiring, payload deserialization, outbox publish guarantees. See `spring-hex-events`. |
| Aggregator / bootstrap | Smoke test | `@SpringBootTest` | Context loads. One per module is enough. |

Pick the **smallest** type that covers what you're testing. A `@SpringBootTest` for a domain rule is wrong — it makes the suite slow and tells you nothing the unit test wouldn't.

## 2. TDDing a use case — start at the inbound port

Order, strictly:

1. **Domain test first.** If the use case introduces a new aggregate rule, write a pure JUnit test for that rule on the aggregate. Make it green at the domain level.
2. **Application service test.** Write a failing JUnit test against the inbound port (`<Verb><Noun>UseCase`). Mock the outbound ports the service needs (`<Noun>Repository`, `<Noun>Gateway`, `<Noun>EventPublisher`). Assert: the right domain method is called, the right outbound port calls are made with the right *domain-typed* arguments, the right exception is thrown on rule violation. **Do not load Spring.**
3. **Write the application service.** Plain `@Service` implementing the inbound port, depending only on outbound port *interfaces*.
4. **REST adapter test.** Write a `@WebMvcTest` against the controller with the inbound port mocked. Assert HTTP shape, validation, status codes. Do **not** re-test the use-case logic here — that's already covered.
5. **Write the controller.** Translates HTTP DTO → port command, calls the port, translates result → HTTP response DTO.
6. **Persistence adapter test.** `@DataJpaTest` + Testcontainers against the `*PersistenceAdapter` implementing the outbound `*Repository` port. Round-trip an aggregate; assert the JPA entity and mapper behave.
7. **Write the persistence adapter.**

Every step is its own red → green → refactor cycle. Don't skip the domain step even when the rule feels obvious — that's where the regression net lives.

## 3. TDDing a persistence adapter

- The test asserts on **domain objects in, domain objects out**. Never on `*JpaEntity` directly — that's an internal type.
- Use Testcontainers for the real DB engine. H2 lies about Postgres behavior (JSONB, arrays, case-sensitive identifiers, transactional DDL).
- Cover: save-then-find round-trip, find-by-business-id, find-not-found returns `Optional.empty()` (or domain-meaningful equivalent), update preserves identity, optimistic-lock conflict if relevant.
- One `@DataJpaTest` class per adapter. Reuse the container across the suite via Testcontainers reuse or a `@TestConfiguration`.

## 4. TDDing a client / anti-corruption adapter

- Use **WireMock** (or MockServer) to stub the external system. Real network is forbidden in CI.
- Test that external errors and quirky payloads are translated into **domain exceptions** and **domain objects** before they leave the adapter. A `RestClientException` leaking up is a bug.
- Cover the failure cases the adapter is supposed to absorb: 4xx, 5xx, malformed payload, timeout. Each one becomes a domain-meaningful outcome.

## 5. TDDing a domain event end-to-end

For each event, three cycles:

1. **Application service publishes correctly.** Mock the outbound `*EventPublisher` port; assert the right event with the right payload is published *after* the aggregate change. If `@TransactionalEventListener(AFTER_COMMIT)` is the chosen mechanism, the unit test still asserts on the publisher port; the *transaction* behavior is verified at the next layer.
2. **Listener routes correctly.** Slice test (or plain unit if the listener is thin): feed the event; assert the inbound `*UseCase` of the consumer module is called with the right command. The listener must contain **no business logic**.
3. **Outbox / broker integration.** Testcontainers (DB + broker). Assert: a successful transaction produces a row in the outbox and eventually a broker message; a rolled-back transaction produces neither; the consumer is idempotent under duplicate delivery.

See `spring-hex-events` for the architectural rules these tests are enforcing.

## 6. AssertJ patterns worth standardising

- `assertThat(actual).isEqualTo(expected)` for plain equality.
- `assertThat(collection).extracting(...).containsExactly(...)` for ordered facet matching — cleaner than per-element loops.
- `assertThatThrownBy(() -> ...).isInstanceOf(X.class).hasMessageContaining(...)` for exception assertions.
- `assertThat(optional).hasValueSatisfying(value -> ...)` for `Optional` round-trip checks.
- Custom assertions for repeated domain shapes (`assertThat(policy).isActive().withNumber("POL-…")`) when the same assertion appears in 5+ tests.

Avoid `assertEquals` from raw JUnit — AssertJ's fluent diff messages are worth the consistency.

## 7. Mockito patterns to apply and to avoid

Apply:
- `when(port.find(id)).thenReturn(Optional.of(domainObject))` for stubs.
- `verify(publisher).publish(eq(expectedEvent))` for command verification.
- `ArgumentCaptor` when the published object is built inside the service and you need to inspect its fields.

Avoid:
- `verifyNoMoreInteractions` — couples the test to the production code's call list, breaks on every refactor.
- Mocking value objects, records, or pure domain types — they have no behavior worth mocking.
- Mocking the class under test (`@Spy` on the service) — almost always means the seam is wrong.

## 8. Per-layer red flags during code review

- A `@SpringBootTest` covering pure domain logic — wrong test type.
- `H2Database` in `application.properties` of a persistence test — use Testcontainers.
- A `@WebMvcTest` re-asserting use-case behavior instead of HTTP behavior — duplicates the application test, slows the suite.
- A persistence test asserting on `*JpaEntity` — couples the test to the adapter's internals.
- A listener test that constructs a full `@SpringBootTest` context — over-scoped; use a slice or plain unit.
- A use-case test that loads Spring — application layer is meant to be framework-free; if the test needs Spring, the service has a hidden infrastructure dependency.
- No test for the unhappy path of a port adapter (timeout, 5xx, conflict) — the anti-corruption layer is missing its main job.