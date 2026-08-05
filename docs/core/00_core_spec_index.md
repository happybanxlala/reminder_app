# Core Specification Index & Precedence

## 1. Document Status

* Document type: **Core specification index and precedence policy**
* Scope: Reminder App Core specifications, with current emphasis on Shared Pack v1
* Status: **Active**
* Semantic authority: **Meta-authority only**
* Planned location: `docs/core/00_core_spec_index.md`
* Phase introduced: After Shared Pack v1 Phase 1 Final Gate, before Phase 2a
* Phase 1 baseline commit: Record the exact Phase 1 Final Gate commit when this document is adopted
* Last reviewed: Record when adopted

This file is authoritative only for:

* locating the correct specification;
* determining which document owns a concern;
* resolving document precedence;
* distinguishing specification from repository evidence;
* controlling amendments and later-phase documentation;
* defining the minimum source set that later implementation phases must read.

This file does **not** define new Shared Pack product behavior, data schema, runtime behavior, API behavior, UI behavior, security policy, or implementation details.

If this index appears to introduce a new semantic rule, the rule is invalid until it is added to the specification that owns that concern.

---

## 2. Purpose

The repository contains several Core specifications with different responsibilities.

The purpose of this index is to prevent later development from treating all Core files as one undifferentiated body of text.

It provides:

1. one registry of authoritative Core documents;
2. one concern-to-owner map;
3. one conflict-resolution procedure;
4. one rule for later documents that refine earlier contracts;
5. one source-loading policy for ChatGPT, Codex, reviewers, and maintainers;
6. one amendment process;
7. one documentation policy for Shared Pack Phases 2–4.

The intended result is:

```text
Read the smallest authoritative source set
→ identify locked upstream constraints
→ implement only the current phase scope
→ prove compliance with code and tests
→ record a concise Gate result
```

The following pattern is explicitly rejected:

```text
Read every Core file as equal authority
→ infer an unofficial combined meaning
→ silently reconcile conflicts
→ create another large Core file
→ repeat during every implementation step
```

---

## 3. Non-Goals

This index does not:

* merge all Core specifications into one document;
* summarize every rule from every specification;
* replace any existing Core specification;
* make a newer document automatically more authoritative;
* make a more detailed document automatically more authoritative;
* allow implementation code to silently replace a locked specification;
* allow tests to redefine expected behavior;
* authorize scope outside Shared Pack v1;
* create a new Phase 2, Phase 3, or Phase 4 product contract;
* treat README status summaries as normative specifications;
* turn Gate reports into new Core specifications.

---

## 4. Normative Vocabulary

The terms below have specific meanings in this repository.

### 4.1 MUST / MUST NOT

A mandatory requirement.

Later design, implementation, SQL, UI, and tests must preserve it unless the owning specification is deliberately amended.

### 4.2 SHOULD / SHOULD NOT

A strong recommendation.

Deviation is permitted only when the implementation records a concrete reason and does not violate a MUST-level rule.

### 4.3 MAY

An allowed implementation choice.

It does not create a requirement for later phases.

### 4.4 Locked

A decision that later phases must preserve.

A locked decision can only change through the amendment process defined in this document.

### 4.5 Deferred

A decision intentionally assigned to a named later specification or phase.

A deferred decision is not permission to alter its locked upstream constraints.

When the named owner closes the decision, that owner becomes authoritative for the delegated seam.

### 4.6 Design target

A future implementation contract.

It is not evidence that the behavior currently exists in production code.

### 4.7 Repository evidence

A verified observation about the current repository, dependency graph, database version, tests, routes, or implementation.

Evidence describes what exists. It does not automatically define what should exist.

### 4.8 Implemented

Production or test code exists for the behavior.

“Implemented” does not automatically mean “compliant.”

### 4.9 Verified

The implementation has executable evidence showing that it satisfies the relevant contract.

### 4.10 Amendment

A deliberate semantic change to an authoritative specification.

An amendment is different from:

* spelling correction;
* formatting cleanup;
* updated repository evidence;
* added implementation notes that do not change behavior.

### 4.11 Upstream specification

A document whose locked decisions constrain another document.

### 4.12 Concern owner

The document authorized to make decisions for a specific subject.

Authority is based on concern ownership, not filename order alone.

---

## 5. Core Authority Model

### 5.1 Authority is concern-based

There is no single global rule that the newest or longest Core document wins.

Each document owns a defined concern.

For example:

* product scope belongs to `06`;
* remote request and response contracts belong to `07`;
* runtime consistency invariants belong to `08`;
* local schema belongs to `10`;
* projector mechanics belong to `11`;
* runtime coordination mechanics belong to `12`;
* remote SQL security and RPC implementation design belong to `13`;
* application-facing contracts and test ownership belong to `14`.

A document may refine an upstream rule only inside its assigned concern.

It may not redefine the upstream concern.

### 5.2 Upstream constraints remain active

A later technical design document must preserve all applicable upstream constraints.

For example:

```text
06 says Shared Pack v1 excludes realtime
```

A later RPC, application, or UI design cannot add realtime merely because it owns remote implementation or provider composition.

### 5.3 Later does not automatically mean stronger

Filename sequence and creation date do not establish blanket precedence.

The following rule is invalid:

```text
14 is newer than 08, therefore 14 may override runtime consistency.
```

The correct interpretation is:

```text
08 owns runtime consistency.
14 owns application/UI/test behavior constrained by 08.
```

### 5.4 Specificity applies only within a delegated seam

A more specific document may close a decision explicitly deferred to it.

Example:

```text
08 requires known-untrusted cache to block mutation
and defers the exact trust-state representation.

12 may define the concrete trust-state transition and coordinator behavior.
12 may not permit mutation from known-untrusted cache.
```

### 5.5 Explicit locked rules beat summaries

Within the same authority domain:

1. explicit locked requirements;
2. normative algorithms, tables, and acceptance scenarios;
3. explanatory prose;
4. document summaries.

A short summary must not be used to weaken an explicit locked rule elsewhere in the same owning specification.

---

## 6. Document Classes

Repository documents belong to one of the following classes.

| Class                             | Examples                              | Authority                                                |
| --------------------------------- | ------------------------------------- | -------------------------------------------------------- |
| Core product/domain specification | `04`, `06`                            | Normative within owned concern                           |
| Core boundary specification       | `05`, `07`, `08`                      | Normative within owned concern                           |
| Technical design specification    | `09–14`                               | Normative only within delegated technical concern        |
| Visual direction                  | `docs/ui/visual_direction.md`         | Normative for visual presentation, not product semantics |
| Roadmap                           | Shared Pack v1 schedule               | Normative for phase order, phase scope and Gate sequence |
| README                            | `README.md`                           | Repository orientation and status summary                |
| Source code                       | `lib/`, platform code, SQL            | Implementation evidence                                  |
| Test code                         | `test/`, integration tests, SQL tests | Executable compliance evidence                           |
| Generated code                    | Drift or other generated files        | Derived implementation artifact                          |
| Gate report                       | `docs/reviews/` or equivalent         | Historical implementation evidence                       |
| ADR/amendment record              | `docs/decisions/` or equivalent       | Rationale and approved change record                     |

A document from one class must not silently assume the authority of another class.

---

## 7. Authoritative Document Registry

### 7.1 `docs/core/04_core_model_spec_v1.md`

**Owns:**

* existing Personal/local-first domain semantics;
* Personal Pack and Item model;
* Personal versus Shared model intersection;
* which existing domain entities remain Personal-only;
* backup/import/reset boundary where defined;
* prohibition against treating Shared Pack as a replacement for the existing Personal model.

**Does not own:**

* Shared Pack product scope in general;
* remote API shape;
* runtime ordering;
* Shared cache schema details;
* Shared UI flow.

**Downstream dependants:**

* `06–14`;
* Personal boundary regression tests in Phases 2–4.

---

### 7.2 `docs/core/05_home_widget_spec.md`

**Owns:**

* current Home Widget architecture;
* Widget snapshot generation and native consumption;
* Home Widget action boundary;
* existing Widget data-source behavior;
* Shared Pack exclusion from the existing Widget unless deliberately revised later.

**Does not own:**

* general Shared Pack UI;
* Shared remote API;
* Shared cache;
* Shared application-service contracts.

**Downstream dependants:**

* `06`, `09`, `14`;
* Phase 2 and Phase 4 boundary regression tests.

---

### 7.3 `docs/core/06_shared_pack_direction_spec_v1.md`

**Owns:**

* Shared Pack v1 product direction;
* v1 capabilities;
* owner/member product permissions;
* supported Shared Item types and lifecycle;
* explicit exclusions;
* version roadmap;
* product success criteria;
* Personal/Shared user-facing distinction.

**Highest authority for:**

```text
What Shared Pack v1 is
What Shared Pack v1 includes
What Shared Pack v1 excludes
What owner and member may do
```

**Does not own:**

* exact RPC envelopes;
* local Drift columns;
* projector transaction order;
* Riverpod type names.

**Downstream dependants:**

* `07–14`;
* all Shared Pack implementation phases.

---

### 7.4 `docs/core/07_shared_pack_remote_contract_v1.md`

**Owns:**

* remote request catalog;
* remote request and response semantics;
* remote DTO and snapshot contract;
* protocol versions;
* version fields and authoritative response requirements;
* full-snapshot response boundary;
* remote idempotency behavior at contract level;
* invite request behavior at contract level;
* remote error contract at protocol level;
* remote authority versus local projection boundary.

**Highest authority for:**

```text
What the client sends
What remote returns
Which operations exist
Which successes return full snapshots
How remote protocol versions behave
```

**Does not own:**

* PostgreSQL table layout;
* exact RLS policy implementation;
* Dart provider composition;
* SQLite schema;
* UI wording.

**Downstream dependants:**

* `08–14`;
* Phase 2 Fake Remote;
* Phase 3 production RPC;
* Phase 4 product flow.

---

### 7.5 `docs/core/08_shared_pack_runtime_consistency_spec_v1.md`

**Owns:**

* response ordering;
* monotonic cache version behavior;
* same-version/same-content requirements;
* same-version/different-content failure;
* cache trust semantics;
* remote-success/local-projection-failure separation;
* retry identity requirements;
* known-untrusted mutation blocking;
* freshness semantics;
* inaccessible semantics;
* Scenario A–H runtime acceptance behavior.

**Highest authority for:**

```text
How valid or failed requests interact over time
How overlapping responses are accepted or rejected
When cache may be trusted
How failure and recovery must be represented
```

**Does not own:**

* exact mutex implementation;
* exact database table shape;
* exact UI component;
* exact RPC SQL.

**Downstream dependants:**

* `09–14`;
* Phase 2 runtime implementation;
* Phase 3 remote integration;
* Phase 4 failure UX.

---

### 7.6 `docs/core/09_shared_pack_technical_design_v1.md`

**Owns:**

* Shared Pack feature placement;
* layer boundaries;
* dependency direction;
* component ownership;
* separation from Personal repositories;
* separation from Home and Home Widget;
* single Shared projector boundary;
* allowed integration seams with existing app infrastructure.

**Highest authority for:**

```text
Where Shared code belongs
Which layer may depend on which layer
Which existing feature must remain isolated
```

**Constrained by:**

* `04–08`.

**Does not own:**

* exact local columns;
* exact projector algorithm;
* exact request serialization;
* exact SQL schema;
* exact routes and UI states.

---

### 7.7 `docs/core/10_shared_pack_local_cache_schema_design_v1.md`

**Owns:**

* planned Shared Drift table set;
* columns and storage types;
* indexes;
* foreign keys;
* uniqueness;
* local constraint capacity;
* UTC storage representation;
* trust-state storage capacity;
* pending-mutation storage capacity;
* v5→v6 migration target;
* Personal backup/import/reset preservation boundary at schema level.

**Highest authority for:**

```text
What Shared data is persisted locally
How it is keyed and constrained
How schema v6 represents the planned cache
```

**Constrained by:**

* `04–09`.

**Does not own:**

* trust-state transition policy;
* retry orchestration;
* projector acceptance algorithm;
* remote SQL schema.

---

### 7.8 `docs/core/11_shared_pack_snapshot_projector_design_v1.md`

**Owns:**

* strict snapshot decoding;
* validation;
* canonicalization;
* canonical ordering;
* snapshot fingerprint;
* same-version comparison mechanics;
* full projection transaction;
* Pack/member/Item reconciliation;
* stale-row deletion;
* transaction rollback behavior;
* `notModified` local database operation;
* projector outcomes;
* Phase 2d/2e projector tests.

**Highest authority for:**

```text
How one valid authoritative snapshot becomes local cache truth
```

**Constrained by:**

* `04–10`.

**Does not own:**

* per-Pack request lock lifecycle;
* pending-intent lifecycle;
* remote SQL behavior;
* UI recovery presentation.

---

### 7.9 `docs/core/12_shared_pack_runtime_coordination_design_v1.md`

**Owns:**

* per-Pack coordination;
* request serialization;
* relationship between application operation, remote request and projection;
* pending logical mutation lifecycle;
* `clientRequestId` creation, persistence, reuse and resolution;
* duplicate-tap coordination;
* app-restart unresolved-intent behavior;
* trust-state transitions;
* mutation blocking;
* revalidation orchestration;
* separation between remote outcome and projection outcome.

**Highest authority for:**

```text
How requests, retries, locks, pending intents and trust transitions
are coordinated around the projector
```

**Constrained by:**

* `04–11`.

**Does not own:**

* remote SQL tables;
* RLS policy;
* application route layout;
* visual design.

---

### 7.10 `docs/core/13_shared_pack_remote_security_rpc_design_v1.md`

**Owns:**

* Supabase/PostgreSQL authoritative schema design;
* database roles and grants;
* RLS;
* RPC-only client boundary;
* SQL function catalog implementation design;
* remote transactions and locks;
* remote Pack and Item version increment implementation;
* server idempotency persistence and exact replay;
* invite storage and brute-force controls;
* function security;
* remote privacy and threat mitigations;
* Phase 3 remote integration obligations.

**Highest authority for:**

```text
How the locked remote contract is securely implemented in PostgreSQL/Supabase
```

**Constrained by:**

* `04–12`;
* especially `06`, `07` and `08`.

**Does not own:**

* changes to the operation catalog established by `07`;
* Dart application signatures;
* Riverpod composition;
* user-facing UI wording.

---

### 7.11 `docs/core/14_shared_pack_application_ui_test_contract_v1.md`

**Owns:**

* application facade;
* inward-facing ports;
* command and query contracts;
* read models;
* application outcomes and failures;
* Riverpod composition;
* provider lifecycle and override seams;
* route map;
* dedicated Shared Pack UI flow;
* owner/member action availability;
* trust, pending and recovery presentation behavior;
* Fake Remote contract;
* diagnostic and redaction boundary;
* automated test ownership;
* Scenario A–H traceability;
* Phase 2/3/4 Gate expectations;
* final manual UAT contract.

**Highest authority for:**

```text
How locked Shared Pack behavior is exposed to Flutter application and UI layers
How implementation is tested across later phases
```

**Constrained by:**

* `04–13`;
* `docs/ui/visual_direction.md` for presentation direction.

**Does not own:**

* expansion of Shared Pack v1 scope;
* modification of remote protocol;
* weakening runtime invariants;
* modification of local schema without amending `10`.

---

### 7.12 `docs/ui/visual_direction.md`

**Owns:**

* visual tone;
* typography direction;
* spacing;
* component styling;
* color and surface direction;
* general navigation and page presentation direction.

**Does not own:**

* product capability;
* role permissions;
* cache trust behavior;
* retry semantics;
* route authorization;
* test expectations.

When visual direction conflicts with functional correctness, accessibility, security, or locked failure semantics, the relevant Core specification wins.

The visual direction should then be amended or interpreted in a compatible way.

---

### 7.13 Shared Pack v1 Roadmap / Schedule

**Owns:**

* phase order;
* step boundaries;
* implementation sequence;
* Gate sequence;
* named delivery phase;
* exit-point discipline;
* prohibition against skipping directly to later phases.

**Does not own:**

* product semantics;
* DTO shapes;
* runtime invariants;
* schema details;
* RPC security behavior;
* UI state semantics.

If the roadmap conflicts with an authoritative semantic specification:

1. do not silently follow the roadmap;
2. preserve the semantic specification;
3. revise the roadmap or formally amend the owning specification.

---

## 8. Precedence Layers

The following layers are used when more than one document applies.

### Layer 1 — Product and existing-domain boundaries

1. `06` — Shared Pack v1 scope, roles, capabilities and exclusions
2. `04` — existing Personal/local-first domain and Personal/Shared boundary
3. `05` — existing Home Widget boundary

### Layer 2 — Protocol and runtime invariants

4. `07` — remote request, response and snapshot contract
5. `08` — runtime consistency, ordering, trust and recovery invariants

### Layer 3 — Delegated technical design

6. `09` — architecture placement and dependency direction
7. `10` — local cache schema
8. `11` — snapshot projector
9. `12` — runtime coordination
10. `13` — remote security and RPC implementation design
11. `14` — application, UI and test contract

This layered list is a routing aid, not a rule that every earlier number wins every possible conflict.

The concern owner remains decisive within its concern, subject to all applicable upstream constraints.

---

## 9. Concern Ownership Matrix

| Concern                                 | Primary owner                     | Required upstream constraints              |
| --------------------------------------- | --------------------------------- | ------------------------------------------ |
| Shared Pack v1 capabilities             | `06`                              | `04`, `05` where existing boundaries apply |
| Owner/member permissions                | `06`                              | `04`                                       |
| Shared v1 exclusions                    | `06`                              | —                                          |
| Personal/Shared boundary                | `04`                              | `06` for Shared product intent             |
| Home integration exclusion              | `06`, `09`                        | `04`                                       |
| Home Widget exclusion                   | `05`                              | `06`, `09`                                 |
| Remote operation catalog                | `07`                              | `06`                                       |
| Request/response DTO semantics          | `07`                              | `06`, `04`                                 |
| Snapshot shape and protocol version     | `07`                              | `06`, `04`                                 |
| Remote idempotency contract             | `07`                              | `06`                                       |
| Runtime version monotonicity            | `08`                              | `07`                                       |
| Cache trust and revalidation semantics  | `08`                              | `06`, `07`                                 |
| Remote success/local projection failure | `08`                              | `07`                                       |
| Feature folder and layer ownership      | `09`                              | `04–08`                                    |
| Dependency direction                    | `09`                              | `04–08`                                    |
| Shared Drift tables and columns         | `10`                              | `04–09`                                    |
| Local indexes/FKs/constraints           | `10`                              | `07–09`                                    |
| v5→v6 migration design                  | `10`                              | `04`, `09`                                 |
| Snapshot validation                     | `11`                              | `07`, `08`, `10`                           |
| Canonicalization/fingerprint            | `11`                              | `07`, `08`, `10`                           |
| Projection transaction                  | `11`                              | `08–10`                                    |
| `notModified` local operation           | `11`                              | `07`, `08`, `10`                           |
| Per-Pack lock                           | `12`                              | `08`, `09`, `11`                           |
| Pending logical mutation lifecycle      | `12`                              | `07`, `08`, `10`                           |
| `clientRequestId` reuse lifecycle       | `12`                              | `07`, `08`, `10`                           |
| Trust-state transitions                 | `12`                              | `08`, `10`, `11`                           |
| Revalidation orchestration              | `12`                              | `07`, `08`, `11`                           |
| PostgreSQL authoritative tables         | `13`                              | `06–08`                                    |
| RLS/grants/function security            | `13`                              | `06`, `07`                                 |
| RPC transaction implementation          | `13`                              | `07`, `08`, `12`                           |
| Remote idempotency persistence          | `13`                              | `07`, `08`, `12`                           |
| Invite SQL/security                     | `13`                              | `06`, `07`                                 |
| Application facade                      | `14`                              | `06–13`                                    |
| Riverpod composition                    | `14`                              | `09`, `12`                                 |
| Route map                               | `14`                              | `06`, `09`                                 |
| UI role gating                          | `14`                              | `06`, `12`                                 |
| Failure/recovery UI semantics           | `14`                              | `08`, `12`                                 |
| Fake Remote                             | `14`                              | `07`, `08`, `12`                           |
| Test ownership and traceability         | `14`                              | `04–13`                                    |
| Visual presentation                     | `visual_direction.md`             | `06`, `08`, `14`                           |
| Phase order                             | Roadmap                           | All Core authorities                       |
| Current repository state                | Source code and verified commands | Not a semantic authority                   |
| Compliance proof                        | Tests and Gate reports            | All applicable specifications              |

---

## 10. Conflict-Resolution Procedure

When two sources appear inconsistent, the developer or reviewer MUST use the following procedure.

### Step 1 — Identify the exact disputed statement

Do not describe the conflict only as:

```text
10 and 12 disagree.
```

Record:

* the exact subject;
* the relevant sections;
* the two incompatible interpretations;
* the implementation decision affected.

### Step 2 — Classify the concern

Map the dispute to the ownership matrix.

Examples:

* SQL column type → `10` or `13`, depending on local versus remote storage
* retry ID reuse → `12`, constrained by `07` and `08`
* route availability → `14`, constrained by `06`
* adding Shared Items to Home → `06` and `09`
* response envelope → `07`

### Step 3 — Identify the concern owner

The concern owner decides the detailed rule only within its delegated boundary.

### Step 4 — Identify upstream constraints

Read the relevant locked upstream sections.

The concern owner may refine a deferred seam but may not contradict an upstream locked rule.

### Step 5 — Distinguish refinement from contradiction

A refinement adds implementation precision without changing observable behavior.

A contradiction changes one or more of:

* supported product capability;
* role permission;
* request or response shape;
* cache correctness;
* failure meaning;
* security guarantee;
* data preservation;
* user-observable result;
* acceptance-test expectation.

### Step 6 — Check for an explicit amendment

A valid amendment must:

* identify the owning specification;
* identify affected downstream documents;
* record the reason;
* update acceptance tests;
* be deliberately approved.

A later incidental sentence is not an amendment.

### Step 7 — Stop on unresolved contradiction

Do not:

* choose whichever rule is easier to implement;
* choose the newest file automatically;
* create a hybrid behavior;
* silently update only the implementation;
* weaken a P0 invariant;
* proceed while noting the conflict only in a final summary.

The current phase must stop at its Gate until the contradiction is resolved.

### Step 8 — Record the resolution

The resolution must be placed in:

* the owning Core specification, if semantics change;
* a short ADR/amendment record, if rationale is useful;
* this index, only if document ownership or precedence changes;
* dependent tests and cross-references.

---

## 11. Standard Precedence Rules

### Rule P1 — No global “newer wins”

A newer filename, commit, or phase does not automatically override an older authority.

### Rule P2 — No global “more detailed wins”

Detail is authoritative only inside the document’s assigned concern.

### Rule P3 — Product scope cannot be expanded by technical design

`09–14` cannot add a capability excluded by `06`.

### Rule P4 — Technical documents may close explicitly deferred decisions

The named owner may choose the implementation shape while preserving upstream behavior.

### Rule P5 — Existing Personal behavior remains protected

Shared implementation cannot change Personal behavior merely because Shared code uses the same database host, router, ProviderScope, or visual system.

### Rule P6 — Protocol and implementation are separate

`07` defines remote behavior.

`13` defines how that behavior is implemented securely.

If `13` proposes a SQL shape that changes the `07` request or response contract, `07` must be amended first.

### Rule P7 — Runtime invariant and mechanism are separate

`08` defines required observable runtime behavior.

`11` and `12` define projector and coordination mechanisms.

A lock, queue, transaction, or retry mechanism is invalid if it weakens `08`.

### Rule P8 — Schema capacity and runtime lifecycle are separate

`10` owns persisted shape and constraints.

`12` owns lifecycle and transitions using that capacity.

`12` cannot require a persisted state impossible under `10` without amending `10`.

### Rule P9 — Functional UI contract beats visual preference

`14` owns action availability, trust states, recovery behavior and failure meaning.

`visual_direction.md` owns how those states look.

Visual styling cannot hide, merge or misrepresent a required functional state.

### Rule P10 — Roadmap controls order, not semantics

A roadmap step cannot override a Core contract.

### Rule P11 — README is not normative

README may summarize progress and can temporarily lag behind the Core specifications.

A README mismatch should be corrected, but it does not amend a Core contract.

### Rule P12 — Historical baselines are evidence only

Branch names, HEAD values and repository findings recorded inside Phase 1 documents describe the state at the time of inspection.

They do not override a newer verified repository state.

### Rule P13 — Passing tests do not override specifications

A test that encodes incorrect behavior is a test defect.

### Rule P14 — Existing code does not silently override planned design

During implementation, code/spec disagreement must be classified as:

* implementation defect;
* stale repository evidence;
* infeasible design requiring amendment;
* deliberate scope change requiring Gate review.

### Rule P15 — Generated files are never edited as authority

Generated code follows its source schema or generator configuration.

---

## 12. Repository Evidence Versus Normative Design

Phase 1 Shared Pack documents are documentation-only design targets.

Statements such as:

```text
planned table
future provider
target schema version
proposed SQL
future RPC
```

must not be interpreted as proof that the repository already contains them.

When implementation begins, every review must separately report:

### Normative target

What the specifications require.

### Repository baseline

What exists before the current step.

### Current implementation delta

What the current step adds or changes.

### Verification evidence

What commands, tests and manual checks prove.

The following statement is invalid:

```text
The specification contains a SharedPackCacheProjector,
therefore the projector is implemented.
```

The correct statement is:

```text
The specification requires a SharedPackCacheProjector.
Repository inspection must determine whether it exists.
```

---

## 13. Phase 1 Freeze Policy

After the Phase 1 Final Gate:

* `04–14` form the Shared Pack v1 design baseline;
* Phase 2 must begin from that frozen baseline;
* implementation convenience is not sufficient reason to modify a Core specification;
* implementation must first attempt to satisfy the locked design;
* Core changes require an identified contradiction, infeasibility, correctness defect, security defect, or approved scope change.

The exact Phase 1 Final Gate commit must be recorded in this file.

Suggested field:

```text
Shared Pack v1 Phase 1 frozen baseline:
<commit SHA>
```

---

## 14. Amendment Policy

### 14.1 Editorial change

Examples:

* spelling;
* formatting;
* broken cross-reference;
* corrected historical commit;
* clearer wording with unchanged behavior.

Requirements:

* no Gate reopening;
* no new semantic rule;
* commit message should identify the change as editorial.

### 14.2 Clarification

A clarification makes an existing rule less ambiguous without changing observable behavior.

Requirements:

* edit the concern owner;
* state that behavior is unchanged;
* update cross-references if needed;
* add or improve tests when ambiguity affected test coverage.

### 14.3 Owned technical refinement

A technical document closes a decision explicitly deferred to it.

Requirements:

* remain inside the delegated seam;
* preserve all upstream invariants;
* record the upstream constraints used;
* avoid copying entire upstream sections.

### 14.4 Contract amendment

A contract amendment changes observable behavior, data shape, security policy, protocol, role permission, failure meaning, or acceptance expectation.

Requirements:

1. identify the concern owner;
2. state the old rule;
3. state the new rule;
4. explain why implementation cannot or should not preserve the old rule;
5. list affected documents;
6. list affected phases and tests;
7. reopen the relevant Gate;
8. update the owner before downstream implementation;
9. update this index only if ownership or precedence changes.

### 14.5 Scope expansion

Adding an excluded capability requires:

* amendment to `06`;
* review of `04`, `05`, `07`, `08`, `09`, `13` and `14` as applicable;
* roadmap update;
* new Gate decision;
* explicit statement that the work is no longer the original frozen Shared Pack v1 scope.

A later implementation step cannot label scope expansion as a small refactor.

---

## 15. Documentation Policy for Phases 2–4

### 15.1 Default rule

Phases 2–4 MUST NOT create one new large Core specification per roadmap step.

Their primary deliverables are:

* production code;
* migrations;
* SQL;
* tests;
* fixtures;
* Fake Remote scenarios;
* diagnostic harnesses;
* concise Gate reports;
* UAT evidence.

### 15.2 New Core file threshold

A new Core specification is permitted only when all are true:

1. a genuinely new long-lived concern exists;
2. no current document owns it;
3. the concern affects multiple future phases or features;
4. adding it to an existing owner would make ownership unclear;
5. the change has passed an explicit design Gate.

Implementation detail alone is not sufficient.

### 15.3 Gate report location

Use a non-Core location, for example:

```text
docs/reviews/shared_pack_phase_2a_result.md
docs/reviews/shared_pack_phase_2b_result.md
docs/reviews/shared_pack_phase_2_gate.md
```

The exact directory may follow existing repository conventions.

### 15.4 Gate report content

A Gate report should contain only:

* status;
* branch and baseline commit;
* changed files;
* implemented contract sections;
* tests added;
* commands executed;
* manual checks;
* deviations;
* unresolved issues;
* scope confirmation;
* exit-gate decision.

It must not restate the full Core design.

---

## 16. Minimum Reading Sets

The goal is not to forbid access to other documents.

The goal is to distinguish:

* **Primary**: must be read closely for the current step;
* **Constraint**: relevant locked sections must be checked;
* **Reference**: read only when implementation touches the concern.

All steps should also inspect the current repository rather than relying only on historical evidence inside the specifications.

---

## 17. Phase 2 Reading Matrix

### Phase 2a — Shared Feature Skeleton

**Primary:**

* `09_shared_pack_technical_design_v1.md`
* `14_shared_pack_application_ui_test_contract_v1.md`

**Constraints:**

* `04_core_model_spec_v1.md`
* `06_shared_pack_direction_spec_v1.md`
* `07_shared_pack_remote_contract_v1.md`
* `08_shared_pack_runtime_consistency_spec_v1.md`

**Reference:**

* `10–13`

**Must not implement:**

* Drift schema;
* projector;
* runtime coordinator behavior beyond interfaces;
* Supabase;
* production UI;
* remote SQL.

---

### Phase 2b — Drift Schema v6

**Primary:**

* `10_shared_pack_local_cache_schema_design_v1.md`

**Constraints:**

* `04_core_model_spec_v1.md`
* `06_shared_pack_direction_spec_v1.md`
* `09_shared_pack_technical_design_v1.md`
* relevant test ownership in `14`

**Reference:**

* `11` for projector-required storage;
* `12` for pending-intent capacity.

**Expected evidence:**

* fresh v6 database;
* true v5→v6 migration fixture;
* Personal data preservation;
* backup/import/reset regression tests.

---

### Phase 2c — Shared Cache Read Layer

**Primary:**

* `09_shared_pack_technical_design_v1.md`
* `10_shared_pack_local_cache_schema_design_v1.md`
* relevant read models in `14`

**Constraints:**

* `04`, `05`, `06`

**Reference:**

* `11` for projected cache meaning.

**Must not implement:**

* Personal repository integration;
* Home aggregation;
* Widget integration;
* remote membership discovery.

---

### Phase 2d — Snapshot Validator & Fingerprint

**Primary:**

* `07_shared_pack_remote_contract_v1.md`
* `11_shared_pack_snapshot_projector_design_v1.md`

**Constraints:**

* `08_shared_pack_runtime_consistency_spec_v1.md`
* `10_shared_pack_local_cache_schema_design_v1.md`

**Reference:**

* `13` only where remote canonical values must match.

**Expected evidence:**

* strict decode tests;
* schema-version tests;
* UTC tests;
* foreign-identity tests;
* canonical ordering tests;
* fingerprint golden tests.

---

### Phase 2e — Transactional Projector

**Primary:**

* `11_shared_pack_snapshot_projector_design_v1.md`

**Constraints:**

* `07`, `08`, `09`, `10`

**Reference:**

* `12` for coordinator/projector seam;
* `14` for expected application outcomes.

**Expected evidence:**

* initial projection;
* newer projection;
* older snapshot rejection;
* same-version identical handling;
* same-version conflict;
* full rollback;
* missing-row deletion;
* `notModified`.

---

### Phase 2f — Runtime Coordinator

**Primary:**

* `08_shared_pack_runtime_consistency_spec_v1.md`
* `12_shared_pack_runtime_coordination_design_v1.md`

**Constraints:**

* `07`, `09`, `10`, `11`

**Reference:**

* `14` for application outcomes and provider seams.

**Expected evidence:**

* per-Pack coordination;
* duplicate action handling;
* persisted unresolved intent;
* retry ID reuse;
* payload mismatch handling;
* trust transitions;
* mutation block;
* revalidation recovery.

---

### Phase 2g — Fake Remote Gate

**Primary:**

* `14_shared_pack_application_ui_test_contract_v1.md`

**Constraints:**

* `06–12`

**Reference:**

* `13` for behavior the Fake Remote must later match without implementing Supabase.

**Expected evidence:**

* Scenario A–H;
* create/refresh/complete flow;
* deterministic out-of-order responses;
* timeout/replay;
* projection failure;
* inaccessible state;
* full Phase 2 Gate report.

---

## 18. Phase 3 Reading Matrix

### Phase 3a — Supabase & Lazy Identity

**Primary:**

* `13_shared_pack_remote_security_rpc_design_v1.md`
* identity/application portions of `14`

**Constraints:**

* `06`, `07`, `09`

**Key exclusion:**

* no eager identity creation during ordinary Personal startup.

---

### Phase 3b — Remote Schema & RLS

**Primary:**

* `13_shared_pack_remote_security_rpc_design_v1.md`

**Constraints:**

* `06`, `07`, `08`

**Expected evidence:**

* executable SQL migration;
* grants;
* RLS;
* cross-Pack denial tests;
* owner/member permission tests.

---

### Phase 3c — Version, Snapshot & Idempotency Core

**Primary:**

* `07_shared_pack_remote_contract_v1.md`
* `08_shared_pack_runtime_consistency_spec_v1.md`
* `13_shared_pack_remote_security_rpc_design_v1.md`

**Constraints:**

* canonical compatibility with `11`;
* retry lifecycle compatibility with `12`.

---

### Phase 3d–3f — Remote Operations

**Primary:**

* operation definitions in `07`;
* SQL/RPC implementation in `13`.

**Constraints:**

* product permissions and exclusions in `06`;
* runtime behavior in `08`;
* client contract in `12` and `14`.

---

### Phase 3g — Dart Remote Adapter

**Primary:**

* `07`
* `09`
* `13`
* relevant application ports in `14`

**Constraints:**

* `08`, `11`, `12`.

---

### Phase 3h — Remote Integration Gate

**Primary:**

* test ownership and UAT mapping in `14`

**Constraints:**

* all `06–13` locked behavior.

**Expected evidence:**

* two independent identities;
* authorization;
* idempotency replay;
* concurrency;
* stale version;
* projection failure recovery;
* invite lifecycle;
* cross-Pack security.

---

## 19. Phase 4 Reading Matrix

### Phase 4a–4e — Product UI Flows

**Primary:**

* `14_shared_pack_application_ui_test_contract_v1.md`
* `docs/ui/visual_direction.md`

**Constraints:**

* product behavior in `06`;
* runtime/failure meaning in `08`;
* coordinator outcomes in `12`;
* remote contract in `07`.

### Phase 4f — Complete & Trust UX

**Primary:**

* `08`
* `12`
* `14`

**Constraints:**

* no UI wording may represent uncertain remote outcome as confirmed remote failure.

### Phase 4g — Data Boundary & Release Gate

**Primary:**

* `04`
* `05`
* `06`
* final test/UAT requirements in `14`

**Constraints:**

* full Shared Pack v1 locked baseline.

---

## 20. Codex Source-Loading Protocol

Every Codex implementation prompt SHOULD contain the following sections.

### 20.1 Current phase and hard boundary

```text
Current step:
Phase 2x — <name>

Only implement this step.
Do not begin later steps.
Stop at the named exit point.
```

### 20.2 Primary authorities

List only the documents requiring close reading.

### 20.3 Locked constraints

List the smaller set of upstream specifications whose relevant sections constrain the step.

### 20.4 Reference-only sources

List documents that may be consulted when the current implementation touches their concern.

Reference-only does not mean lower authority within their own concern.

### 20.5 Explicit exclusions

Repeat the most likely scope-creep risks for the current step.

### 20.6 Repository verification

Require Codex to inspect:

* branch;
* HEAD;
* working tree;
* existing implementation;
* relevant tests;
* current database/schema state;
* generated files;
* dependency state.

Historical evidence in Phase 1 files must not replace current inspection.

### 20.7 Conflict protocol

Include:

```text
If implementation evidence conflicts with a locked specification,
do not silently choose one.

Classify the issue as:
- implementation defect;
- stale evidence;
- specification ambiguity;
- specification infeasibility;
- required amendment.

Do not broaden scope or amend a Core contract without reporting it.
```

### 20.8 Required result format

Require:

* status;
* changed files;
* contract sections implemented;
* tests;
* commands;
* failures;
* deviations;
* scope confirmation;
* exit-gate decision.

---

## 21. Standard Source Authority Block for Future Prompts

```text
## Source authority

Use `docs/core/00_core_spec_index.md` only to locate ownership and resolve
precedence. It does not define feature semantics.

Primary authorities for this step:
- <document>
- <document>

Locked upstream constraints:
- <document and concern>
- <document and concern>

Reference-only sources:
- <document>

Authority is concern-based:
- newer files do not automatically override older files;
- specific design may close only a seam explicitly delegated to it;
- no later technical document may weaken product scope, remote contract,
  runtime consistency, Personal boundary, or Widget boundary;
- current repository code is implementation evidence, not an automatic
  replacement for the locked design.

If an irreconcilable conflict is found, stop the affected implementation,
identify the exact sections and concern owner, and report the required
amendment. Do not silently reconcile the conflict.
```

---

## 22. Standard Gate Report Template

```markdown
# Shared Pack Phase <x> Result

## Status

- COMPLETE / BLOCKED / PARTIAL

## Scope

- Planned step:
- Implemented:
- Explicitly not implemented:

## Repository Baseline

- Branch:
- Starting HEAD:
- Working tree:
- Relevant existing state:

## Source Authorities

- Primary:
- Locked constraints:
- Reference-only:

## Changed Files

- `path`
- `path`

## Contract Traceability

| Requirement | Owner document | Implementation | Test evidence |
|---|---|---|---|

## Commands Executed

- command
- command

## Automated Tests

- test
- result

## Manual Checks

- check
- result

## Deviations

- None
or
- Exact deviation and reason

## Conflicts or Amendments

- None
or
- Exact concern, owner and required action

## Exit Gate

- PASS / FAIL
- Reason:
- Next permitted step:
```

---

## 23. Conflict Register Template

Use this only when an actual contradiction is found.

```markdown
## Specification Conflict

### Concern

<exact subject>

### Source A

- File:
- Section:
- Requirement:

### Source B

- File:
- Section:
- Requirement:

### Concern owner

<owning document>

### Upstream constraints

- document:
- rule:

### Classification

- refinement ambiguity;
- direct contradiction;
- stale evidence;
- implementation infeasibility;
- scope expansion.

### Impact

- code:
- schema:
- protocol:
- tests:
- security:
- user behavior:

### Required resolution

<exact amendment or clarification>

### Implementation status

- blocked;
- unaffected work may continue;
- Gate reopened.
```

---

## 24. Worked Precedence Examples

### Example A — Shared Items in Home

Suppose `14` contains a convenient provider shape that could expose Shared Items to Home.

Applicable owners:

* `06` owns v1 product scope;
* `09` owns feature isolation;
* `14` owns provider composition.

Because Shared Home integration is excluded upstream, `14` cannot authorize it.

Result:

```text
Do not add Shared Items to Home.
```

---

### Example B — Same-version snapshot conflict

Suppose an implementation shortcut in `11` would project a same-version snapshot without comparing its fingerprint.

Applicable owners:

* `08` owns same-version/same-content invariant;
* `11` owns the algorithm.

The algorithm must satisfy `08`.

Result:

```text
The shortcut is invalid.
```

---

### Example C — Pending mutation table versus lifecycle

Suppose `10` defines storage capacity for one unresolved logical mutation, while `12` defines when the row is inserted and deleted.

Applicable owners:

* `10` owns persisted columns and constraints;
* `12` owns lifecycle.

This is a valid refinement if `12` uses the schema without changing its meaning.

---

### Example D — RPC shape differs from remote contract

Suppose `13` proposes an RPC returning a mutation fragment while `07` requires a full active snapshot.

Applicable owners:

* `07` owns response behavior;
* `13` owns SQL implementation.

Result:

```text
13 must be corrected.
07 must not be silently weakened.
```

---

### Example E — UI says mutation failed after projection failure

Suppose remote mutation succeeds, projection fails, and UI displays:

```text
完成失敗，請再試一次。
```

Applicable owners:

* `08` owns remote-success/local-failure distinction;
* `12` owns recovery coordination;
* `14` owns UI representation.

Result:

```text
The wording is invalid because it encourages a potentially duplicate mutation.
The UI must represent an unresolved/revalidation state instead.
```

---

### Example F — Tests pass but Personal reset deletes Shared cache

Applicable owners:

* `04` owns Personal data boundary;
* `10` owns Shared schema;
* `14` owns regression-test requirements.

If tests do not catch the deletion, the tests are incomplete.

Result:

```text
Passing tests do not make the behavior compliant.
Fix implementation and add the missing regression test.
```

---

### Example G — README says Shared Pack is not implemented after Phase 2 begins

README is repository status documentation.

Current code and Gate evidence may show that part of Phase 2 is implemented.

Result:

```text
Update README.
Do not treat the stale README as proof that the implementation is absent.
```

---

## 25. Anti-Patterns

The following are prohibited.

### 25.1 Reading every Core file as equal authority

This causes accidental averaging of incompatible abstraction levels.

### 25.2 Copying all upstream rules into every new file

This creates drift and competing sources of truth.

Use cross-references and concern ownership instead.

### 25.3 “Latest file wins”

Later documents often own different concerns.

### 25.4 Silent implementation amendments

Code cannot become a new contract merely because it was merged.

### 25.5 Gate report as specification

A result report records evidence. It does not redefine behavior.

### 25.6 Test-driven scope expansion

Adding a test for a new capability does not authorize the capability.

### 25.7 Solving an implementation difficulty by weakening an invariant

P0 correctness and security requirements require amendment review, not convenience edits.

### 25.8 Starting later roadmap work because interfaces are nearby

Phase boundaries remain active even when later implementation would be easy to add.

### 25.9 Creating a mega-summary as a replacement authority

This index routes readers to the owner.

It must not duplicate the full specifications.

---

## 26. Maintenance Rules

This file must be updated when:

* a new Core specification is approved;
* a Core specification is superseded;
* concern ownership changes;
* document precedence changes;
* the Phase 1 frozen baseline commit is recorded;
* Shared Pack moves to a new major contract version;
* a new long-lived feature shares these Core boundaries.

This file should not be updated merely because:

* implementation files were added;
* tests were added;
* repository HEAD changed;
* a Gate passed;
* a phase result was recorded;
* a specification’s historical evidence became old.

---

## 27. Review Checklist

Before starting any Shared Pack implementation step, confirm:

* [ ] The current roadmap step is identified.
* [ ] Primary authorities are listed.
* [ ] Relevant upstream constraints are listed.
* [ ] Reference-only documents are separated.
* [ ] Current repository state was inspected.
* [ ] Historical evidence was not mistaken for current implementation.
* [ ] Scope exclusions are explicit.
* [ ] Concern ownership is understood.
* [ ] No “newer wins” assumption is being used.
* [ ] No later phase work is included.
* [ ] Required tests are mapped to their owner specification.
* [ ] Any conflict has been recorded rather than silently reconciled.

Before closing the step, confirm:

* [ ] Production changes match the current step.
* [ ] Tests prove the relevant locked behavior.
* [ ] Personal boundaries remain intact.
* [ ] Home and Widget exclusions remain intact.
* [ ] No Core contract was changed accidentally.
* [ ] Deviations are recorded.
* [ ] Gate report is concise and non-normative.
* [ ] The next permitted roadmap step is named.

---

## 28. Adoption Gate

This index is ready for adoption when:

1. the Phase 1 Final Gate is complete;
2. the exact frozen baseline commit is recorded;
3. all listed document paths exist or missing paths are corrected;
4. no existing Core document claims incompatible concern ownership;
5. the Phase 2a prompt references this index;
6. Phase 2 documentation policy is accepted;
7. future implementation steps use Primary / Constraint / Reference source groups;
8. Gate reports are stored outside `docs/core/`.

Once adopted:

```text
docs/core/00_core_spec_index.md
```

becomes the required entry point for Shared Pack specification navigation and precedence.

It remains intentionally thin:

* it points to authority;
* it does not duplicate authority;
* it prevents silent precedence assumptions;
* it does not become another full Shared Pack design specification.
