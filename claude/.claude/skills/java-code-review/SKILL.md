---
name: java-code-review
description: Review Java/Spring Boot code for architecture, quality, security, and testing. Use when the user asks to review code, review a PR, or check code quality.
---

# Java Code Review

Review code against the following checklist. For each category, report findings as:
- PASS — no issues found
- WARN — minor issues, suggestions for improvement
- FAIL — must fix before merging

Run `git diff main...HEAD` (or the appropriate base branch) to get the changes under review. If the user specifies specific files, review only those.

## 1. Hexagonal Architecture Boundaries

- [ ] Domain model has ZERO imports from `jakarta.*`, `org.springframework.*`, or infrastructure packages (except JPA annotations on entities)
- [ ] Domain services depend only on domain interfaces (ports), never on adapters
- [ ] Inbound ports (use cases) are interfaces in `application/port/in/`
- [ ] Outbound ports are interfaces in `application/port/out/`
- [ ] Adapters implement ports, never the other way around
- [ ] No business logic in adapters (controllers, JPA repos, external clients)
- [ ] Modules do not import from other modules' internal packages (only shared kernel)

## 2. Domain Model Quality

- [ ] Value objects are `final` and immutable (no setters, fields are `private final`)
- [ ] Value objects override `equals()`, `hashCode()`, and `toString()`
- [ ] Entities validate invariants in constructors — never allow invalid state
- [ ] Domain exceptions are meaningful (not generic `RuntimeException`)
- [ ] No primitive obsession — use value objects for domain concepts (phone numbers, codes, etc.)
- [ ] Domain model uses ubiquitous language from the business domain

## 3. Java Best Practices

- [ ] No mutable static fields
- [ ] No raw types (use generics properly)
- [ ] Use `Optional` for return types that may be empty — never return `null`
- [ ] Use `final` on local variables and parameters where possible
- [ ] No unused imports, fields, or methods
- [ ] Consistent naming: `camelCase` for methods/fields, `PascalCase` for classes, `UPPER_SNAKE` for constants
- [ ] Use records for simple data carriers where applicable (Java 25)
- [ ] Use pattern matching and sealed types where appropriate (Java 25)
- [ ] Prefer constructor injection over field injection
- [ ] No `System.out.println` — use proper logging (SLF4J)

## 4. Spring Boot Conventions

- [ ] Services annotated with `@Service`, not `@Component`
- [ ] Repository adapters annotated with `@Repository`
- [ ] Controllers annotated with `@RestController` with proper `@RequestMapping`
- [ ] Configuration in `@Configuration` classes, not scattered
- [ ] No business logic in `@Configuration` or `@Bean` methods
- [ ] Proper use of `@Transactional` — on service layer, not controllers
- [ ] Bean validation (`@Valid`, `@NotNull`, etc.) on DTOs at controller boundary
- [ ] No entity objects exposed directly in REST responses — use DTOs

## 5. Security (OWASP Top 10)

- [ ] No SQL injection — using parameterized queries (JPA/Spring Data handles this)
- [ ] No hardcoded secrets, passwords, or API keys
- [ ] Input validation at system boundaries (controllers, external API consumers)
- [ ] No sensitive data in logs (passwords, tokens, PINs, OTPs)
- [ ] Proper authentication/authorization checks on endpoints
- [ ] CORS configuration is restrictive (not `*`)
- [ ] No mass assignment — DTOs whitelist accepted fields

## 6. Testing Quality

- [ ] Tests follow TDD naming: `should<Expected>_when<Condition>` or `should<Expected>`
- [ ] Each test tests ONE behavior — no multiple assertions testing different things
- [ ] Mocks are used only for outbound ports (infrastructure boundaries), not for domain objects
- [ ] No test logic (if/else/loops in tests)
- [ ] Edge cases covered: null, empty, boundary values, error paths
- [ ] No flaky tests (time-dependent, order-dependent, external-dependent)
- [ ] Test classes mirror the package structure of production code
- [ ] Integration tests use `@SpringBootTest` or `@DataJpaTest`, unit tests use plain JUnit + Mockito

## 7. Error Handling

- [ ] Custom domain exceptions instead of generic ones where appropriate
- [ ] Exceptions carry meaningful messages
- [ ] No empty catch blocks
- [ ] No `throws Exception` — declare specific exceptions
- [ ] REST controllers have proper error responses (not stack traces to client)
- [ ] Validation errors return 400, not found returns 404, auth errors return 401/403

## 8. Performance & Scalability

- [ ] No N+1 query problems (check `@OneToMany` / `@ManyToOne` fetch strategies)
- [ ] No unbounded queries — use pagination for list endpoints
- [ ] No blocking calls in hot paths without consideration
- [ ] Thread-safe implementations for shared state (e.g., `ConcurrentHashMap`)
- [ ] Proper use of database indexes (check `@Index` on frequently queried columns)

## Output Format

For each category, provide:

```
### [Category Name] — [PASS|WARN|FAIL]

[If WARN or FAIL, list specific findings with file:line references]
[Suggest concrete fixes, not vague advice]
```

End with a **Summary** section:
- Total: X PASS, Y WARN, Z FAIL
- Blocking issues (must fix)
- Recommended improvements (nice to have)
- Overall verdict: APPROVE / REQUEST CHANGES
