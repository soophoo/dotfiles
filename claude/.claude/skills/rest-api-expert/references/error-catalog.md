# Error Code Catalog

Canonical `error.code` values for the standard error envelope. `code` is a stable machine-readable string; clients switch on it. `message` is human text and may be localized.

## 4xx — Client Errors

| HTTP | `code` | When to use |
|------|--------|-------------|
| 400 | `BAD_REQUEST` | Malformed JSON, syntactically invalid request. |
| 400 | `INVALID_PARAMETER` | A query/path parameter is the wrong shape. |
| 401 | `UNAUTHENTICATED` | No credentials or credentials unreadable. |
| 401 | `TOKEN_EXPIRED` | Bearer token past expiry. |
| 401 | `TOKEN_INVALID` | Signature/issuer/audience check failed. |
| 403 | `FORBIDDEN` | Authenticated but lacks the required scope/role. |
| 403 | `RESOURCE_FORBIDDEN` | User may access the *type* but not *this instance*. |
| 404 | `NOT_FOUND` | Resource does not exist (or must appear so to this user). |
| 405 | `METHOD_NOT_ALLOWED` | Route exists, verb does not. |
| 409 | `CONFLICT` | Generic conflict — use a more specific code when possible. |
| 409 | `DUPLICATE_RESOURCE` | Unique constraint would be violated. |
| 409 | `VERSION_MISMATCH` | Optimistic concurrency check failed. |
| 410 | `GONE` | Resource permanently removed. |
| 415 | `UNSUPPORTED_MEDIA_TYPE` | `Content-Type` not accepted. |
| 422 | `VALIDATION_ERROR` | Body parsed but fails semantic validation; use `details[]`. |
| 429 | `RATE_LIMIT_EXCEEDED` | Include `Retry-After` header and `retryAfter` seconds in body. |

## 5xx — Server Errors

| HTTP | `code` | When to use |
|------|--------|-------------|
| 500 | `INTERNAL_ERROR` | Unexpected — never leak stack trace; always log `requestId`. |
| 502 | `UPSTREAM_ERROR` | Downstream service returned an error. |
| 503 | `SERVICE_UNAVAILABLE` | Deployed with maintenance mode or circuit breaker open. |
| 504 | `UPSTREAM_TIMEOUT` | Downstream call exceeded deadline. |

## `details[]` entry format

For `VALIDATION_ERROR`, `INVALID_PARAMETER`, and similar, populate `details[]`:

```json
{
  "field": "email",
  "code": "INVALID_FORMAT",
  "message": "Email address is not valid"
}
```

Common `details[i].code` values:
- `REQUIRED` — field missing.
- `INVALID_FORMAT` — regex/parse failed.
- `OUT_OF_RANGE` — below min or above max.
- `TOO_SHORT` / `TOO_LONG` — length constraint.
- `NOT_ALLOWED` — value not in enum.
- `ALREADY_EXISTS` — uniqueness violation at field scope.

## Rules

1. Never return 200 with an `error` body. The HTTP status *is* the primary signal.
2. `code` is stable across versions; don't rename without a major version bump.
3. `message` may change freely and may be localized.
4. Always set `requestId` — clients quote it when filing tickets.
5. For 5xx, log the underlying exception server-side with `requestId`; response body must not expose it.
