---
name: ubiquitous-language
description: Build, document, and enforce the ubiquitous language of a DDD project — the shared vocabulary used by domain experts, developers, code, tests, docs, and UI. Discover terms from the business (not invent them), embody them consistently across every layer of the code, respect that the same word can mean different things in different bounded contexts, translate foreign vocabularies at the anti-corruption boundary, and refactor when language shifts. Trigger on 'ubiquitous language', 'domain language', 'glossary', 'naming things', 'what should I call this', 'business term vs technical term', 'rename a domain concept', 'terminology', 'DDD language', 'translate from legacy system', 'mixed language code', 'French business English code', or any naming / vocabulary question with a domain dimension.
---

# Ubiquitous language

Ubiquitous language is the foundation DDD sits on: **the same words** are used in conversation with the business, in code, in tests, in docs, in the UI, and in event names. Without it, every translation between layers is a chance for meaning to drift. With it, the code reads like a domain description.

This skill is about **language discipline**. For modeling the domain (aggregates, value objects, folder layout), see `spring-hex-domain`. For Socratically extracting and recording terms, see `whetstone`.

## 1. The rule

Use the **business's words**, in the business's meaning, **everywhere** they appear in code or docs that touch the domain. If the business says *souscription*, the class is `Souscription` — not `Subscription`, not `Contract`, not `PolicyHolder`. The model speaks the domain's language, not the developer's.

If the business uses a word you find awkward or imprecise, that's information about the domain, not a flaw to fix. Push back only with domain experts present.

**The speak-it-out-loud test.** Read your method invocations and use-case names aloud. *"`souscription.accepter(decision)`"* sounds like something an underwriter would say; *"`policyManager.process(policy)`"* doesn't. If a domain expert would frown, the name is wrong — even if the code compiles and the tests pass.

## 2. Technical suffixes are not domain words

The rule in §1 covers **domain words** — the nouns and verbs the business uses. Code also needs **technical suffixes** the business doesn't care about: `*UseCase`, `*Repository`, `*Gateway`, `*Adapter`, `*Service`, `*Event`, `*Command`, `*Query`, `*JpaEntity`, `*Request`, `*Response`. These name the **architectural role** of the class, not the domain concept. They're allowed, expected, and stay English / Java-conventional even in non-English domains.

The convention: **domain word + technical suffix.** `SouscriptionRepository`, `CreateSouscriptionUseCase`, `SouscriptionAcceptee` (event), `SouscriptionJpaEntity`. The domain word carries the meaning; the suffix carries the role.

**Banned suffixes** — they hide a missing domain word rather than name a real role:
- `Manager`, `Helper`, `Util`, `Processor`, `Handler`, `Coordinator`, `Worker`, `Doer`.
- Anything generic enough that you could swap it onto any class and still have it "make sense".

If you reach for one of those, you're missing a domain verb. Ask the business what they call *the activity* the class is doing.

## 3. Discover it — listen first, invent never

- **Listen to domain experts** in their natural speech. Capture the verbs and nouns they use **verbatim** before reformulating.
- **Event-storm** when starting a new context: write past-tense events on stickies (`PolicyCancelled`, `PrimeCalculee`). The verbs reveal the language.
- **Read existing contracts, regulations, internal docs** — the terms are already there. Steal them; don't invent parallel ones.
- **Disambiguate aloud** — when an expert uses two words for the same thing, or one word for two things, ask which is which. Record the answer in `CONTEXT.md`'s glossary.

Never name a class after a programming pattern (`Manager`, `Helper`, `Processor`, `Util`, `Handler`) when a domain word exists. If no domain word exists for the concept, the concept may not belong in the domain layer.

## 4. ASCII in code — accents stay in docs, not identifiers

Java identifiers technically accept Unicode (so `Souscrïption` compiles), but **don't do it**. Accents cause real friction:

- Keyboard input on QWERTY layouts (CI / colleagues abroad).
- File-system and Git encoding inconsistencies across OSes.
- `grep`, `sed`, refactor tools that quietly match against the wrong codepoints.
- Logs, exception traces, and external tools that mangle non-ASCII.

The rule: **keep the business's word, strip the accents in identifiers**. Class names, method names, packages, files, DB columns, REST paths, event names — all ASCII.

| Spoken / written | In code |
|---|---|
| Souscription | `Souscription` (no accents anyway) |
| Souscription acceptée | `SouscriptionAcceptee` |
| Échéance | `Echeance` |
| Prime calculée | `PrimeCalculee` |
| Bénéficiaire | `Beneficiaire` |

Accents are fine — and expected — in **docs**, **`CONTEXT.md`** glossary entries, **user-facing strings**, and **log messages aimed at humans** (those go through proper UTF-8 anyway). The constraint is *identifiers only*.

If a stripped-accent name becomes ambiguous (e.g. `pêche` "fishing" vs `péché` "sin" both → `peche`), you've found a real domain ambiguity — disambiguate by adding context (`FishingActivity` / `Sin`) rather than re-introducing the accent.

## 5. Mixed-language code — business words in business language, scaffolding in English

When the business speaks French (or any non-English language), the **domain words** are in the business language; the **technical scaffolding** stays English / Java-conventional. Mixing both is correct — **half-translating is wrong.**

| Layer | Language |
|---|---|
| Aggregate / entity / value object / enum names | Business language (`Souscription`, `Beneficiaire`, `MontantPrime`) |
| Methods on aggregates (business verbs) | Business language (`souscrire`, `accepter`, `resilier`) |
| Use-case / port / adapter / repository / event / command class names | English suffix + business-language domain noun (`CreateSouscriptionUseCase`, `SouscriptionRepository`, `SouscriptionAcceptee`) |
| Generic helpers, mappers, framework glue | English (`build`, `from`, `toDomain`) — these aren't domain concepts |
| Code comments (rare per `sopho-guidelines`) | The team's working language |
| `CONTEXT.md`, ADRs, README | The team's working language; glossary entries in the business language with translations if needed |

Rules:

- **Never half-translate.** `SubscribePolicyUseCase` for a domain called *Souscription* loses information. Either both sides match the business (`CreateSouscriptionUseCase`) or you've picked the wrong domain name.
- **Verbs match nouns.** If the noun is `Souscription`, the verb on it is `souscrire`, not `subscribe`. The aggregate method should read like a sentence in the business language.
- **English suffixes stay English.** `Repository`, `UseCase`, `Adapter`, `Event` are framework words — keep them. Don't translate to `Depot`, `CasUtilisation`, `Adaptateur`.

This produces code that reads naturally in both worlds:

```
souscriptionRepository.findById(id)
    .orElseThrow(SouscriptionInexistanteException::new)
    .accepter(decisionUnderwriting);
souscriptionEventPublisher.publish(new SouscriptionAcceptee(id, occurredAt));
```

A French underwriter recognises *souscription… accepter… souscription acceptée*; a Java developer recognises the repository → aggregate → publisher flow.

## 6. Where the language must appear

In a hexagonal project, the language has to be consistent across **every** layer below — drift in any one of them breaks the chain:

| Where | Use domain language |
|---|---|
| Class / record / enum names in `domain/**` | Yes, always |
| Method names on aggregates | Yes — verbs from the business (`cancel`, `renew`, `souscrire`) |
| Package names (`<feature>/domain/aggregate/souscription/`) | Yes |
| Inbound port names (`*UseCase`) | Yes — `AccepterSouscriptionUseCase`, not `SouscriptionUpdater` |
| Outbound port names (`*Repository`, `*Gateway`) | Yes — entity in domain language; the suffix is the only technical word |
| Command / query record names | Yes — `AccepterSouscriptionCommand`, fields named like the form the user fills |
| Domain event names | Yes, past-tense in the domain language |
| Test names | Yes — `should_accepter_souscription_when_dossier_complete` |
| Domain exception names | Yes — `SouscriptionDejaAccepteeException`, not `InvalidStateException` |
| Log messages on domain events | Yes — visible in incident review by people who speak the business language |

Where the language is **allowed to differ**:

- **REST DTOs** (`*Request`, `*Response`) — speak the language of the API's *consumers*. Often the same as the domain; sometimes intentionally different.
- **JPA entities** (`*JpaEntity`) — column names match the DB convention (often `snake_case`, sometimes English-only). The mapper bridges to domain names.
- **External-client payloads** — speak the *external* system's language; the anti-corruption adapter translates (see §9).

## 7. Bounded contexts — same word, different meaning is fine

DDD's central insight: **the same word can mean different things in different contexts**, and that's normal.

- In `souscription`, *client* may mean "the person filling out the form".
- In `sinistres`, *client* may mean "the person filing a claim, who may not be the policy holder".
- In `comptabilité`, *client* may mean "the entity invoiced".

Don't force a global definition. Each context has its **own** glossary section in `CONTEXT.md`. Cross-context communication goes through events (see `spring-hex-events`), and the event carries the **publishing context's** meaning. The consuming context maps it to its own.

A shared word across contexts is a **translation point**, not a shared type. Never reuse a single Java class across contexts to "save duplication" — the duplication is in the name, not in the meaning, and you'll regret coupling them on the day the meanings diverge.

## 8. Process when a term changes

Terms shift — the business learns, regulations change, a stakeholder corrects an old misnaming. When that happens:

1. **Update the glossary in `CONTEXT.md`** with the new term and the date.
2. **Rename across the code** — class, method, package, port, command, event, test, log message. One coordinated PR. Don't ship partial renames; ambiguity during the transition is worse than the old name.
3. **If the change is architectural** (e.g. *contract* split into *policy* and *subscription*), write a new ADR explaining the split. Old ADRs referencing the merged term get `Status: Superseded by NNNN`.
4. **Migrate persisted data** if needed (DB columns, event payloads in the outbox / broker). The renaming is incomplete until what's stored matches what's spoken.

A rename is a **whole-codebase operation**, not a local one.

## 9. Translation at boundaries — the anti-corruption layer

When integrating with a legacy system or third party, **their** vocabulary is theirs. Don't import it into your domain.

- The outbound client adapter (`infrastructure.adapter.out.client`) speaks **their** language internally — DTOs, field names, error codes match what they send.
- The mapper translates **at the adapter boundary** into your domain types using **your** language.
- Past the adapter, only your language exists. If a legacy field is called `POL_NUM_CTR`, the domain side sees `NumeroSouscription`. The translation is the adapter's job; the rest of the system should never know `POL_NUM_CTR` exists.

This is the anti-corruption layer in `spring-hex-ports-adapters` doing its real work: protecting your language from theirs.

Same rule applies inbound: a REST request from a legacy front-end can use the legacy vocabulary; the REST adapter maps it to the domain language before calling the use case.

## 10. Common pitfalls

- **Technical jargon leaking into domain names** — `SouscriptionManager`, `SouscriptionHelper`, `SouscriptionProcessor`. Replace with a domain verb or a real concept (`Underwriter`, `RenouvellementSouscription`).
- **Inventing terms** developers think are "clearer" than what the business says. Bring the suggestion *to* the business; don't decide unilaterally.
- **Anglicisms in non-English domains.** If the business speaks French, the domain speaks French — `Souscription`, `souscrire(...)`, `SouscriptionAcceptee`. Don't half-translate (`PolicySouscription`, `SubscribeSouscription`). See §5.
- **Accents in identifiers.** `Échéance` as a class name compiles but breaks tooling. Strip in code (`Echeance`); keep in glossary and UI strings. See §4.
- **Abbreviations in domain names.** `Pol`, `Subscr`, `Cust`, `Bnf`. The business doesn't say "Subscr" — it says "Souscription". Type the full word. Abbreviations only belong where the abbreviation *is* the word (`Url`, `Ip`, `Json`).
- **Same word, two meanings, same package.** If you find yourself writing `SouscriptionForBilling` and `SouscriptionForUnderwriting`, you have two contexts that need separating, not two prefixes.
- **Different words, same meaning, same package.** `Client`, `Souscripteur`, `Customer` for the same concept means three developers each picked their favourite. Pick one (the business's one), refactor the rest.
- **Acronyms without a glossary entry.** `PNF`, `CRA`, `BAN` mean something to the business; the glossary must record what.
- **Names that age out** — `NewSouscriptionService`, `SouscriptionServiceV2`. The word *new* is never durable. Rename, don't suffix.

## 11. Red flags during review

- A domain class named after a pattern (`*Manager`, `*Helper`, `*Util`, `*Processor`, `*Handler`, `*Worker`).
- A `@Service` named `*Service` doing what a `*UseCase` should — generic suffix masking a missing domain verb.
- A method named `process`, `handle`, `execute`, `doIt` on a domain object. Domain methods are verbs *from the business*.
- An exception named `BusinessException`, `DomainException`, `InvalidStateException` — uninformative; the type itself should name the rule.
- A field, column, or event payload using a legacy system's vocabulary inside the domain layer.
- A glossary entry in `CONTEXT.md` that says *"see code"* — the glossary is the source of truth; the code follows it.
- A new term in code that doesn't appear in `CONTEXT.md`. Add it or rename it.
- A half-translated identifier (`SubscribePolicyUseCase` for a French domain). See §5.
- A non-ASCII identifier (`Échéance` instead of `Echeance`). See §4.
- The same business concept named two different ways across modules.

## 12. Tooling enforcement — make the rule mechanical

Discipline drifts without automation. Put the rules into tooling:

- **ArchUnit rules** in the test suite to ban forbidden suffixes (`*Manager`, `*Helper`, `*Util`, `*Processor`, `*Handler`, `*Worker`) in `domain/**` and `application/**` packages.
- **ArchUnit naming patterns** per layer (`infrastructure.adapter.out.persistence.*` classes end in `PersistenceAdapter`, etc.) — also covered in `spring-hex-review`.
- **Checkstyle / Spotless / EditorConfig** rule forbidding non-ASCII identifiers (see §4).
- **A `banned-words.txt`** in the repo, scanned in CI for occurrences in `domain/**` source — catches suffix violations and project-specific anglicisms you don't want.
- **PR checklist item**: "If this PR introduces a new domain term, is it in `CONTEXT.md`'s glossary?"

Enforce the *mechanical* rules (suffix bans, ASCII, naming patterns) with tools; reserve human review for the *hard* one — "is this the right business word?" — which no linter can answer.

## 13. Connection to other skills

- **`whetstone`** — Socratically discovers and disambiguates terms; updates the glossary in `CONTEXT.md` as decisions land.
- **`spring-hex-domain`** — embodies the language in code structure (folders, classes, methods).
- **`spring-hex-ports-adapters`** — owns the anti-corruption translation between external and domain vocabularies.
- **`spring-hex-events`** — events carry the publishing context's language; consumers translate.
- **`spring-hex-review`** — many of the §11 red flags are enforced there too.
- **`CONTEXT.md` glossary section** — the storage of record.

## 14. The shortest possible rule

> **Use the business's words. In code. Everywhere. Strip the accents. Keep technical suffixes English. Translate at boundaries.**

If a name in your code doesn't appear in `CONTEXT.md`'s glossary or in a domain expert's vocabulary, it's wrong — either rename the code, or add the term to the glossary with the expert's blessing.
