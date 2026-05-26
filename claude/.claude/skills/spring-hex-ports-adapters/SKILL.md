---
name: spring-hex-ports-adapters
description: Design ports and adapters in a Java Spring Boot hexagonal project — inbound (driving) use-case ports, outbound (driven) repository/gateway/publisher ports, and their REST / persistence / client adapters, including the anti-corruption layer around legacy or third-party systems. Trigger on 'port', 'adapter', 'use case interface', 'inbound port', 'outbound port', 'repository port', 'gateway', 'anti-corruption layer', 'REST controller', 'persistence adapter', 'JPA adapter', 'wrap legacy', or any request to integrate an external system behind a port.
---

# Ports & adapters

For where these live in the package tree, see `spring-hex-structure`. For domain folder rules, see `spring-hex-domain`. For event publishers/listeners, see `spring-hex-events`.

## 1. Ports

### Driving / inbound ports — `application.port.in`

- Interfaces named after the **use case**: `CreatePolicyUseCase`, `FindPolicyByIdQuery`.
- One method per use case (`execute`, `handle`, or a verb matching the use case).
- Input/output are **command/query records** defined in `port.in` (`CreatePolicyCommand`, `PolicyView`), never JPA entities or HTTP DTOs.
- One interface per use case. Don't bundle five operations into a single `PolicyService` interface.

### Driven / outbound ports — `application.port.out`

- Interfaces named after the capability the application needs from the outside world: `PolicyRepository`, `BillingGateway`, `PolicyEventPublisher`.
- They speak the **domain language** and return **domain objects**, never JPA entities or HTTP payloads.
- The application service depends on these interfaces; the infrastructure layer provides the implementations.

## 2. Wiring rules

- REST controllers and listeners call **inbound ports**, never `@Service` classes directly.
- Application services depend on **outbound port interfaces**, never on concrete adapters or Spring Data interfaces.
- Inbound adapters never call outbound adapters directly — everything goes through the application service.

## 3. Adapters

### Inbound REST adapter — `infrastructure.adapter.in.rest`

Controllers translate HTTP DTOs → port commands, call the inbound port, translate domain results → HTTP response DTOs. **No business logic.** Validation via `jakarta.validation` lives on the HTTP DTO (`*Request`), not on domain objects.

### Outbound persistence adapter — `infrastructure.adapter.out.persistence`

A class implementing the outbound port, holding a Spring Data `JpaRepository` of a separate `*JpaEntity` class. A `*PersistenceMapper` converts between `JpaEntity` and the domain model. The domain model **never** carries `@Entity`, `@Id`, `@Column`, etc.

### Outbound client adapter — `infrastructure.adapter.out.client`

Same pattern: implements the outbound port, wraps `RestClient` / Feign / SOAP, maps external payloads to domain objects. This is the **anti-corruption layer** — external models, error codes, and quirks must not leak past this boundary. Throw domain exceptions, not `RestClientException`.

## 4. Naming conventions

| Concept | Pattern |
|---|---|
| Inbound port | `<Verb><Noun>UseCase` / `<Verb><Noun>Query` |
| Inbound command/query | `<Verb><Noun>Command` / `<Verb><Noun>Query` (Java `record`) |
| Outbound port | `<Noun>Repository` / `<Noun>Gateway` / `<Noun>Publisher` |
| Application service | `<Noun>Service` implements one or more `*UseCase` |
| JPA entity | `<Noun>JpaEntity` |
| Spring Data repo | `<Noun>JpaRepository` (package-private when possible) |
| Persistence adapter | `<Noun>PersistenceAdapter` implements `<Noun>Repository` |
| Client adapter | `<Noun>ClientAdapter` implements `<Noun>Gateway` |
| Mapper | `<Noun>PersistenceMapper`, `<Noun>RestMapper`, `<Noun>ClientMapper` |
| REST DTO | `<Noun>Request` / `<Noun>Response` |
| REST controller | `<Noun>Controller` |

## 5. Scaffold order when adding a use case

1. Define the **inbound port** (`*UseCase`) and its command/query record in domain terms.
2. Define any **outbound ports** the use case needs (persistence, external systems, events).
3. Write the **application service** implementing the inbound port, depending only on outbound port interfaces.
4. Add the **adapters** last: REST controller for the inbound side, persistence/client adapter for the outbound side.
5. Wire Spring config in `infrastructure.config` of the feature module — not in the aggregator.
