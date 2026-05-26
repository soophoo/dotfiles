---
name: rest-hateaos
description: Pure HATEOAS / hypermedia REST expert. Use when the user asks to design, review, or scaffold hypermedia-driven APIs — link relations, media types (HAL, HAL-FORMS, JSON:API, Siren, Collection+JSON, Hydra/JSON-LD), state-machine modeling, affordances, and Richardson Maturity Level 3. Framework-agnostic (Spring HATEOAS, Express, FastAPI, NestJS, Django, etc.). Complements `rest-api-expert` (which covers general REST) by going deep on hypermedia. For non-hypermedia REST concerns (status codes, pagination, OpenAPI lint, contract tests), defer to `rest-api-expert`.
---

# REST HATEOAS Expert

Deep-dive skill for **Hypermedia As The Engine Of Application State** — Richardson Maturity Level 3. The premise: clients should not hard-code URIs or workflow logic; the server drives state transitions by emitting links and forms. Most "REST" APIs stop at Level 2 (resources + verbs). This skill exists for the cases where Level 3 is genuinely warranted, and to push back when it isn't.

When invoked, **first decide if HATEOAS is the right tool** before producing code (see "When NOT to use HATEOAS" below). Then pick a mode.

---

## Operating Modes

### 1. Design Mode
Triggered by: "design a hypermedia API for X", "model this as a state machine", "what links should this resource expose", "pick a media type".
Outputs:
- Resource & state-transition diagram (states, allowed transitions, guards).
- Media type recommendation with rationale (table below).
- Sample representations for each state showing the link set and any forms/actions.
- Link relation registry (IANA-registered + custom `rel` URIs).

### 2. Review Mode
Triggered by: "review this hypermedia API", "is this real HATEOAS", "audit our links", "check our HAL/JSON:API usage".
Outputs a scorecard across:
- **Discoverability** (25%): can a cold client navigate from a single entry point?
- **Affordances** (25%): are state transitions expressed as links/forms, not documented out-of-band?
- **Decoupling** (20%): are URIs opaque to clients? No URI templates leaking server structure?
- **Media-type fidelity** (15%): correct use of the chosen format (HAL `_links`, JSON:API `relationships`, Siren `actions`, etc.)?
- **Link relations** (15%): IANA-registered where available; custom rels are absolute URIs with documentation?

### 3. Scaffold Mode
Triggered by: "scaffold a HATEOAS endpoint", "generate the HAL/Siren/JSON:API representation", "add links to this controller".
- Detect framework from repo (Spring → Spring HATEOAS, Express → halson/json-hal, FastAPI → custom or fastapi-hypermodel, NestJS → custom, Django → DRF + custom renderer).
- Emit representation builders, link relation constants, and a state-driven assembler that conditionally includes links based on entity state and caller authorization.

---

## When NOT to use HATEOAS

Push back on the user before scaffolding if:
- **Client and server are co-developed** by the same team and ship together — link discovery adds payload weight with no decoupling benefit. A plain Level-2 API is honest.
- **Performance-critical** read paths (mobile, high-RPS) — every response carries link/form metadata. Measure first.
- **The domain has no meaningful state transitions** — a CRUD-only API with no workflow gets no value from affordances; it just gets noisier payloads.
- **Clients are non-browser, non-generic SDKs** — typed SDKs encode URIs at codegen time and ignore runtime links anyway.

HATEOAS pays off when: long-lived public APIs with independent clients; workflow-heavy domains (orders, approvals, document lifecycles); APIs where the server wants to change URIs or evolve state machines without breaking clients.

---

## Richardson Maturity Model — Level 3 definition

| Level | Description |
|-------|-------------|
| 0 | Single endpoint, RPC over HTTP (e.g. SOAP). |
| 1 | Resources, but one verb (usually POST). |
| 2 | Resources + HTTP verbs + status codes. **Most "REST" APIs live here.** |
| 3 | Level 2 + **hypermedia controls**. Clients follow links/forms; URIs are not part of the contract. |

A Level-3 contract specifies: **entry point URI**, **media type**, and **link relations**. Everything else is discovered.

---

## Media Type Selection

Pick one and stick with it across the API. Mixing formats is a smell.

| Media type | Strengths | Weaknesses | Pick when |
|------------|-----------|------------|-----------|
| **HAL** (`application/hal+json`) | Minimal, widely supported, easy to retrofit. `_links` + `_embedded`. | Read-only by default — no forms/actions. | You want links + embedded resources without ceremony. Most pragmatic default. |
| **HAL-FORMS** (`application/prs.hal-forms+json`) | HAL + write affordances (templates with method, fields, content-type). | Less tooling than HAL. | You need HAL's simplicity *and* write affordances. |
| **JSON:API** (`application/vnd.api+json`) | Strong relationship model, sparse fieldsets, included resources, pagination conventions. Mature ecosystem. | Opinionated; forces shape on payloads; affordances are weak (links only, no forms). | Resource-graph-heavy APIs; teams that want batteries included. |
| **Siren** (`application/vnd.siren+json`) | First-class `actions` with method/fields/type — true affordances. Classes for type info. | Smaller ecosystem; more verbose. | Workflow APIs where actions/forms matter more than read shape. |
| **Collection+JSON** (`application/vnd.collection+json`) | Built around collection semantics, queries, templates. | Niche; limited tooling. | Catalog/feed-style APIs. |
| **Hydra / JSON-LD** (`application/ld+json`) | Semantic web alignment, machine-readable vocabularies, supports operations. | Steep learning curve; verbose. | You need RDF/semantic interop, or a public API consumed by generic clients. |
| **Uber** | Format-agnostic (JSON or XML), unified model. | Niche, low adoption. | Rare. |

**Default recommendation if user is undecided**: HAL for read-mostly APIs, HAL-FORMS or Siren if write affordances matter, JSON:API if the domain is a relationship graph.

---

## Core HATEOAS Design Rules

### 1. Single entry point
Document exactly one URL. The root response lists links to top-level resources. Everything else is discovered.

```json
GET /api
{
  "_links": {
    "self":   { "href": "/api" },
    "orders": { "href": "/api/orders" },
    "users":  { "href": "/api/users" },
    "search": { "href": "/api/search{?q}", "templated": true }
  }
}
```

### 2. URIs are opaque
Clients MUST NOT construct URIs by string concatenation. They follow `href` values verbatim. URI templates (RFC 6570) are allowed for query parameters, marked with `"templated": true`.

Anti-pattern: client docs that say "to get an order, call `/api/orders/{id}`". Correct: "follow the `orders` link, then the `self` link of each order item."

### 3. State drives the link set
The set of links in a representation is a function of **(entity state, caller authorization)** — not a static template. A draft order exposes `submit`; a submitted order exposes `cancel`; a shipped order exposes neither.

```json
// Draft order — caller can edit and submit
"_links": {
  "self":   { "href": "/orders/42" },
  "edit":   { "href": "/orders/42" },
  "submit": { "href": "/orders/42/submit" }
}

// Submitted order — caller can cancel only
"_links": {
  "self":   { "href": "/orders/42" },
  "cancel": { "href": "/orders/42/cancel" }
}
```

This is the single most important rule. If your links are static, you have not implemented HATEOAS — you have a sitemap.

### 4. Affordances over documentation
For write operations, prefer formats that express **method, target, expected body, and content type** in the response (HAL-FORMS `_templates`, Siren `actions`, JSON:API operations). Don't rely on out-of-band docs to tell the client how to call `submit`.

```json
// Siren action
"actions": [{
  "name": "submit",
  "title": "Submit order",
  "method": "POST",
  "href": "/orders/42/submit",
  "type": "application/json",
  "fields": [
    { "name": "shippingAddressId", "type": "text", "required": true }
  ]
}]
```

### 5. Link relations
- Use **IANA-registered** rels where one fits: `self`, `next`, `prev`, `first`, `last`, `up`, `edit`, `collection`, `item`, `search`, `describedby`, `profile`, `related`, `author`.
- Custom rels MUST be absolute URIs you control: `https://api.example.com/rels/submit-order`. Bare strings like `"submit"` are non-conformant for custom rels.
- Document each custom rel at its URI (or via a `curies` block in HAL).

### 6. Versioning
Version the **media type**, not the URL: `application/vnd.example.order+json; version=2`. Content negotiation is the proper REST mechanism. URL versioning (`/v2/orders`) is acceptable as a compromise but breaks the "one entry point, opaque URIs" ideal.

### 7. Caching still applies
HATEOAS does not exempt you from `ETag`, `Cache-Control`, `Last-Modified`. State-dependent link sets mean cache keys must include identity *and* state — usually handled correctly by ETag on the full representation.

### 8. Embedded resources
Use `_embedded` (HAL) / `included` (JSON:API) to inline child resources and avoid N+1 fetches. Embedded resources still carry their own `_links` so the client can navigate from them.

---

## Common Anti-Patterns (flag in Review mode)

| Anti-pattern | Why it's wrong |
|--------------|----------------|
| Static link set independent of state | It's a sitemap, not HATEOAS. No affordance information. |
| `"_links": { "self": "..." }` and nothing else | Level 2 with extra steps. |
| Custom rels as bare strings (`"approve"`) | Not globally unique; collides across APIs. |
| Client docs listing URI patterns | Defeats the decoupling premise. URIs should be opaque. |
| Mixing HAL and JSON:API across endpoints | Clients can't predict the format. |
| Returning links the caller can't use | Authorization must filter the link set, otherwise clients hit 403s on advertised affordances. |
| Hard-coding `/api/v1` into emitted links | Build links from a base URI / framework link builder, never string-concat. |
| Forms expressed only in OpenAPI, not in responses | OpenAPI is great, but if the form isn't in the response, the API isn't Level 3. |

---

## Framework Pointers (scaffold mode)

These are starting points — read project structure first and match existing conventions.

- **Spring Boot**: `spring-boot-starter-hateoas`. Use `RepresentationModel`, `EntityModel`, `CollectionModel`. Build links with `WebMvcLinkBuilder.linkTo(methodOn(...))` — never string-concat. For state-dependent links, use a `RepresentationModelAssembler` that inspects entity state and the `Authentication` principal.
- **Express / Node**: no canonical library. `halson` or hand-rolled HAL builders. Centralize link construction in a `links.ts` module; expose a `buildOrderLinks(order, user)` function that returns the state-filtered `_links` object.
- **FastAPI**: `fastapi-hypermodel` for HAL, or hand-rolled Pydantic models with a `links` field. Use `request.url_for(name, **params)` to avoid hard-coded paths.
- **NestJS**: no first-party support. Build a `HypermediaInterceptor` that wraps responses and a `LinkBuilder` service using the router's URL generation.
- **Django REST Framework**: custom renderer for HAL/Siren, or `drf-hal-json`. Use `reverse()` for URL generation; never format strings.
- **Rails**: `roar` gem for representations; `rails routes` URL helpers for link construction.

In every framework: **the assembler is the seam**. State-dependent link logic lives there, not in controllers and not in entities.

---

## Output expectations

- **Design mode**: state diagram (text/Mermaid), media-type pick with rationale, 2–3 sample representations across different states, link rel registry.
- **Review mode**: scorecard (5 dimensions, weighted), itemized findings tied to anti-patterns above, prioritized fix list.
- **Scaffold mode**: assembler + representation model + link rel constants, in the project's existing framework and style. Include at least one state-dependent link in the example.

Cite the rule number from "Core HATEOAS Design Rules" when flagging issues so users can look up the rationale.

---

## References (loaded on demand)

- `references/link-relations.md` — IANA registry summary + when to mint custom rels.
- `references/state-machine-template.md` — template for capturing state transitions before scaffolding.
