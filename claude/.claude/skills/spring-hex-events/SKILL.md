---
name: spring-hex-events
description: Design event-driven communication between feature modules in a Java Spring Boot hexagonal modular monolith — domain events, publisher ports, listener adapters, in-process vs broker delivery, and the transactional outbox pattern. Trigger on 'domain event', 'event-driven', 'publish event', 'event listener', '@EventListener', 'ApplicationEventPublisher', 'module communication', 'inter-module', 'cross-context', 'eventual consistency', 'outbox', 'Kafka', 'RabbitMQ', or any request to make two modules talk without coupling them directly.
---

# Event-driven communication between modules

Feature modules in a hexagonal modular monolith must **never depend on each other directly** (see `spring-hex-structure`). When module A needs to react to something that happened in module B, the link is a **domain event** published by B and consumed by A.

## 1. Domain events

- Past-tense names: `PolicyCreated`, `ClaimSettled`, `PaymentReceived`. Never imperative (`CreatePolicy` is a command, not an event).
- Live in `<feature>/domain/event/`, one per file.
- Java `record`s carrying only **domain-typed** fields (IDs, value objects, enums). No JPA, no Jackson, no Spring.
- Immutable. Include an occurrence timestamp and the aggregate ID.
- Belong to the publishing module's public API: changing an event signature is a breaking change for every consumer.

```java
public record PolicyCreated(
    PolicyId policyId,
    CustomerId customerId,
    Instant occurredAt
) {}
```

## 2. Publishing — outbound port, not direct injection

The application service does **not** inject `ApplicationEventPublisher` or `KafkaTemplate`. It depends on an outbound port:

```
application/port/out/PolicyEventPublisher.java   ← interface, domain language
infrastructure/adapter/out/messaging/...         ← implementation
```

This keeps the application layer ignorant of *how* events leave the module (in-process bus, Kafka, Rabbit, outbox table).

## 3. Consuming — inbound messaging adapter

Listeners live in the **consumer** module's `infrastructure/adapter/in/messaging/`. They translate the incoming event into a call on an **inbound port** (`*UseCase`) of the consumer module. Listeners contain no business logic — they're adapters, just like REST controllers.

```
billing/infrastructure/adapter/in/messaging/PolicyCreatedListener.java
  → calls billing/application/port/in/StartBillingForPolicyUseCase
```

The consumer must define its **own copy** of the event type in its package (or share a thin published-language module). It must **not** import the producer's `domain/event/` class — that would re-introduce the module dependency the event was meant to break.

## 4. Delivery mechanism — pick per use case

| Mechanism | When to use | Notes |
|---|---|---|
| `ApplicationEventPublisher` + `@EventListener` | Same-JVM modules, no durability requirement, can re-derive on replay | Synchronous by default; use `@TransactionalEventListener(phase = AFTER_COMMIT)` to avoid reacting to rolled-back transactions |
| `@Async` + `@EventListener` | Same as above but consumer is slow / shouldn't block the producer | Needs `@EnableAsync`; loses transactional context — be explicit about what that means |
| Kafka / RabbitMQ | Cross-process, durable, replayable, or future extraction to a separate service | Always pair with the outbox pattern below |

Default to `@TransactionalEventListener(AFTER_COMMIT)` for in-process events. Move to a broker only when durability, replay, or future service extraction is a real requirement.

## 5. Transactional outbox — the rule for brokers

Never publish to Kafka/Rabbit directly inside the use-case transaction. Doing so risks: (a) DB commit succeeds, broker publish fails → consumers never hear; (b) broker publish succeeds, DB rollback → consumers act on something that didn't happen.

Instead:
1. In the same transaction as the aggregate change, insert a row into an `outbox` table (`id`, `aggregate_id`, `event_type`, `payload`, `occurred_at`, `published_at NULL`).
2. A separate scheduled poller (or Debezium CDC) reads unpublished rows and pushes them to the broker, marking them published on ack.
3. Consumers must be **idempotent** — design every listener to tolerate the same event arriving twice.

The outbox table and its poller live in the **producer module's** `infrastructure/adapter/out/messaging/` package. The application service stays unaware: it just calls `policyEventPublisher.publish(event)`, whose adapter writes to the outbox.

## 6. What never to do

- Inject another module's `*UseCase` directly to "call it" — that's a hidden module dependency. Publish an event instead.
- Share JPA entities across modules. Each module has its own persistence; events carry IDs, not row references.
- Put business logic in a `@KafkaListener` / `@EventListener` method. They are inbound adapters; delegate to a use case.
- Emit events from inside the domain layer using `ApplicationEventPublisher`. The domain returns events (or stages them on the aggregate); the application service publishes them through the outbound port.
- Use generic event payloads (`Map<String, Object>`, raw JSON nodes). Events are typed contracts.

## 7. Testing

- Publisher: mock the outbound `*EventPublisher` port in application-service tests; assert the right event was published with the right payload.
- Listener: `@SpringBootTest` slice or plain unit test — feed the event, verify the inbound use case was called.
- Outbox: integration test with Testcontainers (DB + broker) covering the commit-then-publish guarantee and the at-least-once delivery / idempotency contract.
