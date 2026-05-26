# REST API PR Review Checklist

Run through this list on any PR that adds or changes a public endpoint.

## Routing & Methods
- [ ] Resource is a plural noun, kebab-case.
- [ ] No verbs in path (actions use sub-resource + POST).
- [ ] HTTP method matches semantics (GET safe, PUT idempotent, etc.).
- [ ] Version prefix present (`/api/v{n}`).

## Request
- [ ] Request body schema documented in OpenAPI.
- [ ] All required fields explicitly marked.
- [ ] Validation rules (min/max/regex/enum) declared.
- [ ] `Content-Type` handling: rejects anything other than documented types (415).
- [ ] For money/side-effect POSTs: `Idempotency-Key` supported.

## Response
- [ ] Success status code is correct (201 + `Location` for create; 204 for delete; 202 for async).
- [ ] Error envelope matches the standard shape (`error.code`, `error.message`, `details?`, `requestId`, `timestamp`).
- [ ] No internal IDs, stack traces, or sensitive fields in the body.
- [ ] Dates are ISO-8601 UTC.
- [ ] Lists are paginated (cursor by default).

## Auth & Security
- [ ] Auth requirement declared per endpoint (not just globally).
- [ ] Role / scope checks explicit.
- [ ] No secrets in URL or query string.
- [ ] Rate-limit bucket defined (per-user and/or per-IP).
- [ ] HTTPS enforced; HSTS at the edge.

## Docs
- [ ] OpenAPI updated in the same PR.
- [ ] Example request + example response included.
- [ ] Error responses documented per status code.

## Evolution
- [ ] No breaking changes without a major version bump.
- [ ] Deprecated endpoints still work and carry `Deprecation` + `Sunset` headers.

## Tests
- [ ] Auth matrix covered.
- [ ] Validation matrix covered (required, types, boundaries, nulls).
- [ ] Each documented error code has at least one test.
- [ ] Pagination edge cases covered for list endpoints.
- [ ] Rate limit test present if the endpoint has a bucket.
