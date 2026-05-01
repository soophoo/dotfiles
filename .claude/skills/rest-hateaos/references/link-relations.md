# Link Relations Reference

A link relation (`rel`) names the *meaning* of a link, decoupled from its URI. Pick from the IANA registry where possible; mint custom rels only when no registered rel fits.

## Most useful IANA-registered relations

### Navigation
- **`self`** — the URI of the current representation. Always include it.
- **`up`** — parent resource in a hierarchy.
- **`collection`** — the collection this item belongs to.
- **`item`** — a member of this collection.
- **`related`** — a generic related resource (use a more specific rel if one exists).

### Pagination
- **`first`**, **`prev`**, **`next`**, **`last`** — page navigation in collections.

### Discovery / metadata
- **`search`** — a resource that supports query (typically a templated link).
- **`describedby`** — a description of this resource (schema, profile, docs).
- **`profile`** — applied profile (RFC 6906) refining the media type's semantics.
- **`type`** — the type of the linked resource.
- **`alternate`** — alternate representation (different language, format).

### Modification
- **`edit`** — a URI that can be used to edit this resource (typically same as `self`, exposed only when caller is authorized).
- **`edit-form`** — a resource representing a form to edit this resource.
- **`create-form`** — a resource representing a form to create a new item.

### Authorship / attribution
- **`author`**, **`license`**, **`copyright`**.

### Versioning
- **`version-history`**, **`latest-version`**, **`predecessor-version`**, **`successor-version`**, **`working-copy`**, **`working-copy-of`**.

Full registry: <https://www.iana.org/assignments/link-relations/link-relations.xhtml>

## Custom (extension) relation types

Per RFC 8288, custom rels MUST be absolute URIs you control. Bare strings (`"submit"`, `"approve"`) are not conformant for custom rels.

```
https://api.example.com/rels/submit-order
https://api.example.com/rels/approve-invoice
https://api.example.com/rels/cancel-shipment
```

The URI SHOULD resolve to documentation describing the rel's semantics, expected method, and parameters.

### CURIEs (HAL convention)
HAL allows compact URIs to keep payloads readable:

```json
{
  "_links": {
    "curies": [{
      "name": "ex",
      "href": "https://api.example.com/rels/{rel}",
      "templated": true
    }],
    "ex:submit-order": { "href": "/orders/42/submit" }
  }
}
```

Resolve `ex:submit-order` → `https://api.example.com/rels/submit-order`.

## Choosing a rel — decision rules

1. Is there an IANA-registered rel with the right semantics? Use it.
2. Is this a domain action (verb-like state transition)? Mint a custom rel as an absolute URI: `https://api.example.com/rels/<verb-noun>`.
3. Is this just "another related thing"? Use `related` with a `name` or `title` qualifier rather than inventing a vague custom rel.
4. Don't reuse an IANA rel for non-matching semantics (e.g. `edit` for a domain action that isn't editing the resource).

## Common mistakes

- Using `"action"`, `"link"`, or `"url"` as rel names — meaningless.
- Using HTTP method names as rels (`"post"`, `"delete"`) — the method is on the link/form itself.
- Inconsistent casing across the API (`submitOrder` vs `submit-order`). Pick one (kebab-case is conventional for path segments in custom rel URIs).
