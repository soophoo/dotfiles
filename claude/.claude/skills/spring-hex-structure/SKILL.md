---
name: spring-hex-structure
description: Structure a Java Spring Boot project as a hexagonal modular monolith — Maven module per bounded context, package layout (domain / application / infrastructure), dependency rule, and the aggregator / bootstrap module. Trigger on 'modular monolith', 'project structure', 'new feature module', 'new bounded context', 'scaffold module', 'package layout', 'hexagonal layers', 'parent pom', 'aggregator module', 'bootstrap module', or any request to set up or extend the skeleton of a Spring Boot hexagonal project.
---

# Hexagonal structure — Maven modules, packages, dependency rule

This skill defines **where code lives**. For what goes inside the domain folder, see `spring-hex-domain`. For ports/adapters, see `spring-hex-ports-adapters`. For events, see `spring-hex-events`.

## 1. One Maven module per bounded context

Each business capability is its **own Maven module** declared under the parent POM's `<modules>` block. Module names are lowercase and follow the project's ubiquitous language.

Inside every feature module, enforce the hexagonal split via **package boundaries** (not sub-modules — packages are enough and keep the build tree flat):

```
<feature-module>/
└── src/main/java/<base-package>/<feature>/
    ├── domain/              ← pure business model, zero framework imports
    ├── application/         ← use-cases orchestrating the domain
    │   ├── port/
    │   │   ├── in/          ← driving ports (use-case interfaces, command/query records)
    │   │   └── out/         ← driven ports (repository, gateway, publisher interfaces)
    │   └── service/         ← @Service implementations of `in` ports
    └── infrastructure/      ← framework + I/O code
        ├── adapter/
        │   ├── in/
        │   │   ├── rest/    ← @RestController + request/response DTOs
        │   │   └── messaging/ ← @KafkaListener, @RabbitListener, @EventListener…
        │   └── out/
        │       ├── persistence/ ← JPA entities, Spring Data repos, mappers
        │       └── client/  ← REST/SOAP clients to external systems
        └── config/          ← @Configuration beans wiring adapters to ports
```

## 2. Dependency rule — strict, one direction only

`domain` ← `application` ← `infrastructure`. Code in an inner layer must **never** import from an outer layer.

- `domain/**` must not import anything from `org.springframework`, `jakarta.persistence`, `com.fasterxml.jackson`, Lombok annotations that generate framework code, or any `application`/`infrastructure` package.
- `application/**` may import `domain/**` and `org.springframework.stereotype.Service` / `org.springframework.transaction.annotation.Transactional` only. No JPA, no web, no Jackson, no concrete adapter types.
- `infrastructure/**` may import everything it needs, including the ports it implements, but must never be referenced from `domain` or `application`.

Treat any reverse-direction import as a blocking violation.

## 3. The aggregator / bootstrap module

The aggregator module depends on every feature module in its `pom.xml`, owns the single `@SpringBootApplication`, the `application.properties` / `application.yml`, cross-cutting database migrations (Flyway/Liquibase), and global `@ControllerAdvice` / security config. It contains **no business code**. Feature modules must not depend on the aggregator.

When a new feature module is added:
1. Create the module directory and `pom.xml` with `<parent>` pointing to the root.
2. Register it in the root `pom.xml` `<modules>`.
3. Add it as a dependency in the aggregator module's `pom.xml`.
4. Use a package under the project's base package so component scanning from the main `@SpringBootApplication` picks it up.

## 4. Inter-module dependencies

A feature module must **never** depend on another feature module directly. Cross-context coupling goes through:
- a published domain event (see `spring-hex-events`), or
- a dedicated outbound port whose adapter happens to call into the other module's published API.

If you find yourself adding module B as a Maven dependency of module A, stop and revisit the design.
