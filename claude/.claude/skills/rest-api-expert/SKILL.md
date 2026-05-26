---
name: rest-api-expert
description: End-to-end REST API expert. Use when the user asks to design, review, lint, version, secure, document, or test a REST API — including endpoint/resource naming, status codes, error envelopes, pagination, auth, rate limiting, OpenAPI specs, breaking-change detection, contract tests, and integration test suites (auth/validation/error-code/pagination/upload/rate-limit matrices). Covers Spring Boot, Express, Next.js App Router, FastAPI, Django REST, NestJS.
---

# REST API Expert

Combines **design review** (conventions, scorecard, breaking-change detection) and **test suite authoring** (auth / validation / error / pagination / upload / rate-limit matrices) into one end-to-end skill. Use it for any REST API work: designing a new endpoint, reviewing an existing one, generating an OpenAPI spec, or producing a test suite.

---

## Operating Modes

Pick the mode that matches the user's ask; do not run every mode by default.

### 1. Design / Review Mode
Triggered by: "review this API", "is this RESTful", "audit our endpoints", "score this spec", "check for breaking changes".
- Lint resource paths, HTTP methods, status codes, error shapes, versioning.
- Detect breaking changes between two OpenAPI specs (removed fields, type changes, now-required fields).
- Produce a scorecard across 5 dimensions: Consistency (30%), Documentation (20%), Security (20%), Usability (15%), Performance (15%).

### 2. Design / Author Mode
Triggered by: "design an endpoint for X", "how should I model this resource", "write the OpenAPI for…".
- Propose resource model, path, methods, request/response schemas, status codes, error envelope.
- Pick a versioning strategy (default: URL `/api/v1`).
- Specify auth (bearer/API key/OAuth2) and a pagination pattern (cursor by default for high-cardinality).

### 3. Test Suite Mode
Triggered by: "generate tests for this API", "write integration tests", "build a contract test", "cover the error paths".
- Detect routes, infer schemas and auth, emit a test file per route group.
- Cover the full Auth + Validation + Error-code matrices, plus pagination / upload / rate-limit when applicable.
- Target stack inferred from the repo (Spring Boot → MockMvc/RestAssured, Node → Vitest+Supertest, Python → Pytest+httpx, Next.js → Vitest+Supertest against `/api`).

---

## REST Design Rules (enforced in all modes)

### Resource naming
- Plural nouns, `kebab-case` for multi-word resources, `camelCase` for JSON fields.
- `/api/v1/users`, `/api/v1/user-profiles`, `/api/v1/orders/{id}/line-items`.
- Never verbs in paths (`/getUsers`, `/createOrder` ❌). Actions as sub-resources: `POST /users/{id}/activate`.

### HTTP methods
| Method | Semantics | Safe | Idempotent |
|--------|-----------|------|------------|
| GET | read | ✅ | ✅ |
| POST | create / non-idempotent action | ❌ | ❌ |
| PUT | full replace | ❌ | ✅ |
| PATCH | partial update | ❌ | depends |
| DELETE | remove | ❌ | ✅ |

### Status codes (use these, not a narrower subset)
- **2xx**: 200 OK, 201 Created (+ `Location` header), 202 Accepted (async), 204 No Content.
- **4xx**: 400 bad syntax, 401 unauthenticated, 403 unauthorized, 404 not found, 409 conflict, 410 gone, 415 unsupported media type, 422 semantic validation error, 429 rate limited.
- **5xx**: 500 unexpected, 502 upstream failure, 503 unavailable, 504 upstream timeout.

### Error envelope (standard)
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid parameters",
    "details": [
      { "field": "email", "code": "INVALID_FORMAT", "message": "Email address is not valid" }
    ],
    "requestId": "req-123456",
    "timestamp": "2024-02-16T13:00:00Z"
  }
}
```
Rule: every non-2xx response uses this shape. `code` is a stable machine string; `message` is human text; `details` is optional per-field.

### Pagination
- **Cursor** (default for append-only or high-cardinality): `?cursor=…&limit=…` → `{ data, pagination: { nextCursor, hasMore } }`.
- **Offset**: `?offset=…&limit=…` — fine for small, stable datasets.
- **Page**: `?page=…&pageSize=…` — legacy/UI-friendly only.

### Versioning
- Prefer URL versioning `/api/v1`. Bump major on any breaking change (see list below).
- Accept `Accept: application/vnd.myapi.v1+json` only if the team has an existing header-versioning convention.

### Auth
- Bearer JWT is the default for internal + first-party clients.
- API keys only for server-to-server with IP allowlist + rotation.
- Always HTTPS. Always short-lived access tokens + refresh tokens.
- Document scopes/roles per endpoint.

### Rate limiting
Return `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`. On 429 include `Retry-After` seconds.

### Idempotency
For non-idempotent POSTs that create money-moving or billable resources, require `Idempotency-Key` header (UUID) and dedupe server-side for ≥24h.

---

## Breaking vs Non-Breaking Changes

**Non-breaking (safe, no version bump):**
- Adding optional request fields.
- Adding fields to responses.
- Adding new endpoints.
- Making required request fields optional.
- Adding new enum values *if* clients handle unknown values.

**Breaking (requires new major version):**
- Removing or renaming fields / endpoints.
- Changing field types.
- Making optional fields required.
- Changing URL structure.
- Changing error envelope shape.
- Tightening validation rules (new constraints on existing fields).

Breaking-change review workflow: diff old OpenAPI vs new, list each violation with severity + suggested migration.

---

## Scorecard Rubric (Design Review Mode)

Assign a letter A–F per dimension, weighted:
- **Consistency (30%)** — naming, response shape, status codes, casing.
- **Documentation (20%)** — OpenAPI completeness, examples, descriptions.
- **Security (20%)** — auth defined per endpoint, no secrets in URLs, input validation, rate limits.
- **Usability (15%)** — discoverability, sensible defaults, error message quality, HATEOAS where it helps.
- **Performance (15%)** — pagination on all list endpoints, caching headers, field selection, batch endpoints.

Output: per-dimension grade + weighted composite + top 3 concrete fixes.

---

## Test Suite Mode — Route Detection

Detect routes by stack, then read each handler for schema/auth/business rules before generating tests.

### Spring Boot (this project's stack)
```bash
# find controllers and methods
rg -n "@(Rest)?Controller|@RequestMapping|@(Get|Post|Put|Patch|Delete)Mapping" \
  --type java
# extract path prefixes
rg -n "@RequestMapping\(" --type java
```

### Next.js App Router
```bash
find ./app/api -name "route.ts" -o -name "route.js" | sort
rg -n "export (async )?function (GET|POST|PUT|PATCH|DELETE)" app/api
```

### Express
```bash
rg -n "(router|app)\.(get|post|put|delete|patch)\(" --type ts --type js
```

### FastAPI
```bash
rg -n "@(app|router)\.(get|post|put|delete|patch)\(" --type py
```

### Django REST
```bash
rg -n "path\(|re_path\(|router\.register\(" --type py
```

---

## Test Matrices (generate ALL rows per endpoint)

### Auth (every authenticated endpoint)
| Case | Expected |
|------|----------|
| No Authorization header | 401 |
| Malformed token | 401 |
| Expired token | 401 |
| Valid token, wrong role | 403 |
| Valid token, correct role | 2xx |
| Token for deleted user | 401 |

### Input validation (every POST/PUT/PATCH with body)
| Case | Expected |
|------|----------|
| Empty body `{}` | 400/422 |
| Missing each required field (one at a time) | 400/422 |
| Wrong type per field | 400/422 |
| Boundary min-1 / min / max / max+1 | 400/2xx/2xx/400 |
| `null` for required field | 400/422 |
| Unknown / extra fields | per policy (reject or ignore — test the contract) |
| SQL injection payload | 400 or sanitized 2xx |
| XSS payload | 400 or sanitized 2xx |
| Wrong `Content-Type` | 415 |

### Error-code coverage
Every route must assert at least one test for each applicable code from {400, 401, 403, 404, 409, 422, 429}.

### Pagination (list endpoints)
First page, last page, empty result, `limit` at max, `limit` above max (expect 400), malformed cursor.

### File upload
Valid file, oversized file, wrong MIME type, empty file, missing file part.

### Rate limiting
Burst above limit within window (expect 429 + `Retry-After`), per-user vs global scope.

---

## Test Authoring Rules

1. One `describe` / test class per endpoint — failures stay isolated.
2. Seed only the minimal fixture data; clean up in `afterAll` / `@AfterEach`.
3. Name tests after the *observable behavior*: `"returns 401 when token is expired"` — never `"auth test 3"`.
4. Assert **response shape and specific error code/field**, not just status.
5. Assert sensitive fields (`password`, `secret`, internal IDs) never appear in responses.
6. Use factories/fixtures for IDs — never hardcode.
7. Test `"missing header"` and `"invalid token"` as separate cases.
8. Rate-limit tests run last or in their own file — they poison parallel runs.
9. For contract tests, validate response against the OpenAPI schema, not a hand-written expected object.

---

## Common Anti-Patterns to Flag

- Verb-based URLs (`/getUser`, `/createOrder`).
- Inconsistent error envelopes across endpoints.
- List endpoints with no pagination.
- Exposing DB columns / internal IDs directly.
- Using 200 for errors (with an `"error"` body).
- Missing rate limits on public endpoints.
- No versioning strategy.
- Leaking stack traces in 500 responses.
- Ignoring `Content-Type` — accepting XML where only JSON is documented.

---

## Output Expectations by Mode

- **Review**: scorecard table + prioritized fix list, each with file:line.
- **Breaking-change check**: table of changes with severity (breaking / deprecated / safe) and migration note.
- **Author**: endpoint spec (method, path, request schema, responses, errors, auth) + OpenAPI fragment.
- **Tests**: one file per route group in the project's test convention, imports compiled, factories imported from existing fixtures when present.

---

## References

- `references/design-checklist.md` — quick audit checklist for PR reviews.
- `references/error-catalog.md` — canonical `code` values for the standard error envelope.
