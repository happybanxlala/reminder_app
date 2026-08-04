# Shared Pack Technical Design v1

## 1. Document Status

- Status: Phase 1a architecture boundary / documentation-only gate.
- Repository baseline: branch `ver-1.3.2`, commit `e870540`, inspected on 2026-08-04.
- Implementation status: Shared Pack remains planned. No production Shared Pack implementation was found in the inspected repository.
- Decision vocabulary:
  - **Locked**: later phases MUST preserve this boundary unless the upstream specifications are deliberately revised first.
  - **Recommended**: a direction that may be refined by its owning later phase without weakening a locked boundary.
  - **Deferred**: Phase 1a intentionally makes no implementation choice.
- This document does not authorize Phase 1b implementation and does not create a Dart, database, remote, route, provider, UI, or test contract.

## 2. Purpose

This document establishes the technical ownership boundary for Shared Pack v1 before implementation begins. It tells later sessions which feature and layer may own Shared concepts, which existing Personal paths MUST remain unchanged in authority, and which decisions belong to Phases 1b–1f.

This document assigns responsibility for the already-locked product, remote-contract, and runtime-consistency invariants. It does not re-open those invariants and does not specify algorithms, fields, SQL, RPC signatures, or application-service method signatures.

## 3. Scope of Phase 1a

Phase 1a locks only:

- the independent Shared Pack feature root;
- layer responsibilities and dependency direction;
- Personal and Shared ownership isolation;
- exclusions from Home, Home Widget, notification, startup, backup, import, and reset mutation paths;
- app-level wiring boundaries;
- decision ownership for Phases 1b–1f;
- forbidden shortcuts that would collapse the authority boundary.

Phase 1a MUST NOT change runtime behavior. The only artifact produced by this phase is this document.

## 4. Source Specifications

This document was prepared after reading and cross-checking:

- `README.md` — current repository status and project layout summary.
- `docs/core/04_core_model_spec_v1.md` — Personal/local-first model and Personal/Shared intersection.
- `docs/core/05_home_widget_spec.md` — implemented Widget snapshot and action boundary.
- `docs/core/06_shared_pack_direction_spec_v1.md` — Shared Pack v1 product scope and exclusions.
- `docs/core/07_shared_pack_remote_contract_v1.md` — planned remote authority and full-snapshot contract.
- `docs/core/08_shared_pack_runtime_consistency_spec_v1.md` — runtime ordering, cache trust, retry, and projection-failure semantics.
- `docs/ui/visual_direction.md` — dedicated Shared surface direction and navigation/UI exclusions.

Authority remains with those source specifications. This document owns architecture placement and dependency boundaries only. If product scope conflicts, `06` governs; remote contract semantics belong to `07`; runtime consistency belongs to `08`; existing Personal behavior belongs to `04`; Home Widget behavior belongs to `05`.

## 5. Current Repository Baseline

### 5.1 Git and implementation state

At the start of Phase 1a:

- branch: `ver-1.3.2`;
- HEAD: `e870540` (`define Shared Pack runtime consistency contract`);
- working tree: clean;
- no Supabase dependency is present in `pubspec.yaml`;
- no Shared Pack Dart feature, Shared Drift table, migration, DAO, repository, provider, route, UI, auth/identity flow, RPC, SQL, or test was found;
- searches across `lib/`, `test/`, platform directories, and `pubspec.yaml` found no production reference to Shared Pack cache names, `remotePackVersion`, `clientRequestId`, Supabase, or membership discovery.

Therefore, all Shared package names and component roles below are architecture ownership targets, not claims about existing code.

### 5.2 Actual repository layout

The inspected top-level paths `lib/data/`, `lib/core/`, `lib/router/`, and `lib/widgets/` do not exist. Current production ownership is feature-nested or app-level:

| Concern | Actual current location and owner |
| --- | --- |
| App composition and startup | `lib/main.dart`, `lib/app/app.dart`, `lib/app/app_bootstrap.dart` |
| GoRouter registration | `lib/app/router.dart`, through `appRouterProvider` |
| Personal feature | `lib/features/reminders/` |
| Personal Item repository | `lib/features/reminders/data/item_repository.dart`, class `ItemRepository` |
| Existing DAO | `lib/features/reminders/data/local/reminder_dao.dart`, class `ReminderDao` |
| Drift database and migration | `lib/features/reminders/data/local/app_database.dart`, class `AppDatabase`; current `schemaVersion = 5` |
| Drift tables | `lib/features/reminders/data/local/tables.dart` |
| Personal Riverpod composition | `lib/features/reminders/providers/`, including `itemRepositoryProvider`, `homeRepositoryProvider`, and `appDatabaseProvider` |
| Home aggregation | `lib/features/reminders/data/home_repository.dart`, class `HomeRepository`, exposed by `lib/features/reminders/providers/home_providers.dart` |
| Home screen | `lib/features/reminders/ui/pages/home_page.dart` |
| Home Widget feature | `lib/features/home_widget/`, composed by `home_widget_providers.dart` |
| Widget snapshot source | `HomeWidgetSnapshotService`, consuming `HomeAttentionSource` / `HomeRepository` only |
| Notification and badge pipeline | `AttentionSummaryRepository` → `AttentionSyncService` → `ReminderNotificationService` / `AppBadgeService` |
| Backup/import/reset service | `lib/features/reminders/data/reminder_backup_service.dart`, class `ReminderBackupService` |
| Backup/import/reset DAO behavior | `ReminderDao.exportBackupData`, `replaceUserDataFromBackup`, `resetUserData`, and `_clearUserData` |
| Tests | flat files under `test/`; no Shared Pack test exists |

This differs from a generic top-level `lib/data`, `lib/core`, `lib/router`, or `lib/widgets` layout. Later Shared work MUST follow the feature root defined in this document and use `lib/app/router.dart` only as the app navigation composition boundary. Phase 1a does not reorganize existing Personal code.

### 5.3 Current Personal data paths

- `ItemRepository` is a concrete Personal/local-first repository over `ReminderDao`; it owns Personal Pack and Item reads/mutations, action history, and related Personal transaction behavior.
- `ReminderDao` currently covers only Personal tables registered by `AppDatabase`: `item_packs`, `items`, action/resource/stage/template tables, and `app_settings`.
- Personal providers are grouped by concern under `lib/features/reminders/providers/`; repositories are constructed from `appDatabaseProvider` and its `ReminderDao`.
- `HomeRepository` aggregates `ItemRepository`, `ResourceRepository`, and `StageTrackerRepository`. `AttentionSummaryRepository`, notification, badge, and Home Widget are downstream of that Personal Home aggregation.
- `HomeWidgetSnapshotService` does not read Drift directly; it maps the existing Home source. `HomeWidgetActionService` mutates through `ItemRepository`.
- Backup export has a fixed Personal payload. Import replaces the known Personal user-data tables, and Personal reset clears those same known tables before restoring system seed data.

These existing paths are evidence for the isolation risks below. They are not extension points for Shared Pack v1.

## 6. Locked Upstream Invariants

Phase 1a assigns, but does not redesign, the following invariants:

| Locked invariant | Responsible architecture boundary |
| --- | --- |
| Shared Pack is remote-authoritative; local Shared data is projected cache | Shared domain semantics define the authority split; Shared application coordinates remote acquisition before local projection; data implementations MUST preserve it |
| `remotePackVersion` never decreases and old responses cannot overwrite newer cache | Shared local projection boundary enforces cache acceptance; Shared application/runtime coordination prevents unsafe sequencing. Algorithm deferred to Phases 1c–1d |
| One Pack version identifies one authoritative active snapshot | Shared domain/application integrity policy and the single projector boundary. Comparison/fingerprint design deferred to Phase 1c |
| Partial projection cannot become cache truth | Shared local data transaction/projection boundary |
| Projection failure cannot advance cache version or freshness | Shared local data boundary; Shared application separately reports the outcome |
| Remote success and local projection failure are distinct | Shared application owns outcome orchestration; future Shared providers/UI may present it but MUST NOT reinterpret it |
| Known-untrusted cache cannot be a mutation base | Shared application/runtime boundary. Persistence format is Phase 1b; state machine is Phase 1d |
| The same logical retry reuses one `clientRequestId` | Shared application/runtime coordination owns logical intent; remote adapter transports the ID without changing its meaning. Lifecycle decisions are Phase 1d |
| Invite requests are outside Pack snapshot versioning | Shared domain/application policy and remote adapter mapping; invite handling MUST NOT enter the snapshot projector |
| Runtime recovery cannot add membership discovery | Shared application and remote port catalog MUST use only authorized recovery capabilities; no hidden list/discovery path |
| Shared Pack v1 stays out of Home, Widget, notification, background sync, and realtime | Shared providers, app composition, Personal Home/Widget/notification boundaries, and all data adapters |

No row above defines its concrete algorithm, storage field, API signature, or UI state.

## 7. Architecture Goals

The architecture MUST:

1. preserve separate Personal/local-first and Shared/remote-authoritative authority models;
2. make every Shared read, mutation, projection, and presentation dependency visibly Shared-owned;
3. make full-snapshot projection the only future cache-truth entry boundary, regardless of snapshot source;
4. prevent framework or transport details from becoming Shared domain dependencies;
5. keep app-level code limited to composition and navigation registration;
6. allow Personal functionality to start and operate without Shared identity or remote availability;
7. make later schema, projector, coordination, remote-security, and UI contracts independently reviewable in their owning phases.

## 8. Architecture Non-goals

Phase 1a does not:

- select a database topology;
- define tables, columns, indexes, foreign keys, schema version, or migration;
- define DTOs, RPCs, SQL, RLS, a concrete remote error catalog, or a Supabase dependency;
- define snapshot validation, ordering, fingerprinting, or transaction algorithms;
- define locks, queues, retry persistence, or trust-state transitions;
- define application-service APIs or Riverpod state models;
- define routes, screens, widgets, navigation entries, or UI failure states;
- add Home, Home Widget, notification, background sync, realtime, outbox, or discovery integration;
- refactor the Personal reminders feature.

## 9. Shared Pack Feature Boundary

Shared Pack MUST be an independent feature with this target ownership map:

```text
lib/features/shared_packs/
  application/
  data/
    local/
    remote/
  domain/
  providers/
  ui/
```

This tree is a package ownership contract only. Phase 1a MUST NOT create these directories or Dart files.

All Shared Pack-specific concepts, policies, adapters, composition, and dedicated UI belong under this root. An app-level file MAY import the Shared feature solely to wire implementations or register a future dedicated route. Shared business rules MUST NOT migrate into `lib/app/` or the Personal reminders feature.

## 10. Proposed Package Ownership

| Target package | Ownership | Explicit non-ownership |
| --- | --- | --- |
| `shared_packs/domain/` | Shared concepts, value semantics, domain errors, framework-free abstractions | Personal models/repositories, transport DTOs, cache rows, Riverpod state, widgets |
| `shared_packs/application/` | Shared use-case orchestration, mutation/refresh coordination, policy sequencing, outcome separation | UI rendering, concrete DAO/client behavior, global startup behavior |
| `shared_packs/data/local/` | Future projected-cache persistence adapter, transaction boundary, local port implementation | Remote authority, Personal DAO/repository behavior, schema decisions before Phase 1b |
| `shared_packs/data/remote/` | Future remote DTO/decoding adapter and remote-error mapping | Domain authority replacement, Personal remote access, remote design before Phase 1e |
| `shared_packs/providers/` | Shared-only Riverpod composition and state exposure | Authoritative business rules, Personal provider aggregation, Home/Widget/notification feeds |
| `shared_packs/ui/` | Future dedicated Shared Pack surfaces | Direct DAO/client access, Personal Item presentation masquerade, Phase 1a route/UI creation |
| `lib/app/` | Composition root and future dedicated navigation registration | Shared policy, retry, projection, identity, or mutation logic |

## 11. Layer Responsibilities

### 11.1 `domain/`

`domain/` MUST contain only Shared Pack domain concepts, value semantics, domain errors, and framework-free abstractions needed by higher-level policy.

It MUST NOT depend on Flutter, Riverpod, Drift, Supabase, GoRouter, a Personal reminder repository, or UI models. It MUST NOT import `application/`, `data/`, `providers/`, or `ui/`.

Risk protected: framework, storage, or Personal-model coupling would make the remote-authoritative semantics impossible to test and evolve independently.

### 11.2 `application/`

`application/` MUST own Shared use-case orchestration, mutation and refresh coordination, domain-policy sequencing, cache-trust action gating, and separation of remote and projection outcomes. All Shared mutations MUST cross this boundary.

It MAY depend on Shared domain abstractions. It MUST NOT depend on Shared UI, Home, Home Widget, Personal repositories, a concrete Supabase client, or a concrete Drift DAO. Formal service methods and port shapes are deferred to Phase 1f.

Risk protected: direct concrete dependencies would distribute consistency rules among pages, providers, and adapters.

### 11.3 `data/local/`

`data/local/` will own Shared projected-cache persistence, the atomic local transaction boundary, and concrete local implementations of Shared ports. It MAY depend on Drift after the appropriate design/implementation phase, but Drift MUST remain an implementation detail.

Phase 1a does not decide table fields, indexes, foreign keys, schema version, migration code, trust-state storage, fingerprint storage, or database topology. **Boundary locked; implementation decision deferred.** All belong to Phase 1b.

Risk protected: premature schema choices could make Personal reset destructive or make incomplete projections appear authoritative.

### 11.4 `data/remote/`

`data/remote/` will own remote DTOs, request/response decoding, remote adapter behavior, and remote-error mapping. It MUST implement a Shared-owned abstraction and MUST NOT return or accept Personal domain models as its contract.

Phase 1a does not choose a Supabase dependency, SQL schema, RPC signature, RLS, idempotency table, or concrete error catalog. **Boundary locked; implementation decision deferred.** These decisions belong primarily to Phase 1e and implementation Phases 3a–3g.

Risk protected: transport details in domain/application code would bypass security and contract review.

### 11.5 `providers/`

`providers/` will be the Shared feature's Riverpod composition layer. It MAY construct Shared application use cases and expose Shared-only read/action state to the dedicated Shared UI.

It MUST NOT:

- mix Shared values into existing Personal reminder providers;
- expose Shared Items as Personal `Item` or `ItemBundle` values;
- feed `HomeRepository`, `AttentionSummaryRepository`, `HomeWidgetSnapshotService`, `AttentionSyncService`, or notification services;
- contain authoritative version, permission, projection, retry, or trust rules that belong to domain/application/data boundaries.

Risk protected: provider convenience must not become a hidden authority merge or integration into excluded surfaces.

### 11.6 `ui/`

`ui/` will contain only dedicated Shared Pack surfaces. Future UI MUST call Shared providers/application boundaries and MUST NOT directly call a Drift DAO, a remote client, or a Personal repository.

Phase 1a creates no route, screen, widget, navigation entry, or UI state implementation. Route map and UI contract are Phase 1f; production UI is Phase 4. **Boundary locked; implementation decision deferred.**

Risk protected: direct UI data access would bypass remote-first writes, full projection, retry identity, and trust gating.

## 12. Dependency Direction

Locked dependency flow:

```text
Shared UI
    │
    ▼
Shared Providers            app composition root
    │                         │ wiring / route registration only
    ▼                         ▼
Shared Application ◄──────── concrete implementation injection
    │
    ▼
Shared Domain abstractions
    ▲                    ▲
    │                    │
Shared Data/Local     Shared Data/Remote
    └── implements Shared Domain/Application ports ──┘
```

The exact placement and shape of those inward-facing ports is deferred to Phase 1f. Whichever layer owns a port, the concrete data implementation MUST depend inward on the port; application/domain code MUST NOT import the implementation.

Rules:

- Shared domain MUST NOT depend on application, data, providers, UI, or app-level composition.
- Shared application MAY depend on Shared domain abstractions but MUST NOT depend on concrete local/remote implementations.
- Shared local/remote data implementations MAY depend on required framework packages, but those packages MUST NOT become domain dependencies.
- Shared providers are composition/state adapters and MUST NOT own authoritative business rules.
- Shared UI MUST NOT directly access `ReminderDao`, `AppDatabase`, a future Shared DAO, a Supabase client, or `ItemRepository`.
- Shared and Personal features MUST NOT read or write one another's repositories or DAOs.
- App-level composition MAY inject Shared implementations and register a future dedicated route. It MUST NOT host Shared mutation, projection, retry, trust, identity, or discovery logic.
- A snapshot obtained from mutation, manual refresh, create, or join MUST eventually enter one Shared projector boundary. The projector design is deferred to Phase 1c.

## 13. Personal and Shared Isolation Matrix

| Scope | Current owner/evidence | Locked allowed direction | Forbidden behavior and protected risk | Phase 1a status |
| --- | --- | --- | --- | --- |
| Personal Item repository | `ItemRepository` in `features/reminders/data/item_repository.dart` | Continue serving Personal/local-first Pack and Item behavior only | MUST NOT carry Shared reads, mutations, DTOs, remote IDs, cache projection, or trust logic; this would merge authority models | Locked |
| Existing Reminder DAO | `ReminderDao` in `features/reminders/data/local/reminder_dao.dart` | Continue its current Personal DAO role | MUST NOT become the Shared DAO or Shared mutation path; Shared persistence must use a Shared-owned abstraction | Boundary locked; implementation decision deferred. |
| Personal providers | `features/reminders/providers/` | Continue exposing Personal repositories/read models | MUST NOT emit or aggregate Shared Items or depend on Shared providers; avoids hidden cross-feature reads | Locked |
| Home | `HomeRepository`, `home_providers.dart`, `home_page.dart` | Keep Personal Item/Resource/Stage aggregation unchanged | MUST NOT query Shared cache or accept Shared provider streams; Shared Pack v1 does not enter the Home attention model | Locked |
| Home Widget | `features/home_widget/`; snapshot uses `HomeAttentionSource` | Keep reading the existing Personal Home snapshot and Personal actions | MUST NOT display, read, or mutate Shared data and MUST NOT call Shared remote APIs | Locked |
| Notification and badge | `AttentionSummaryRepository` and `AttentionSyncService` | Continue using existing Personal Home attention summary | MUST NOT schedule or count Shared Items; prevents accidental Shared background behavior | Locked |
| Backup/export | `ReminderDao.exportBackupData` and `BackupData` | Export the existing Personal payload only | MUST NOT treat Shared cache, membership, identity, tokens, invite data, or remote access metadata as Personal backup payload | Locked |
| Import | `replaceUserDataFromBackup` via `ReminderBackupService` | Replace only Personal user data represented by the legacy payload | MUST NOT overwrite, synthesize, or restore Shared data/identity/access; avoids replacing remote authority from a local file | Locked |
| Personal reset | `resetUserData` / `_clearUserData` | Clear Personal user data and restore Personal system seeds | MUST NOT accidentally delete Shared cache, identity/session, or access metadata; exact SQL topology is Phase 1b | Boundary locked; implementation decision deferred. |
| Router | `lib/app/router.dart`, `appRouterProvider` | Future app composition MAY register dedicated Shared routes | MUST NOT route Shared flows through Personal edit/manage pages or add routes in Phase 1a | Boundary locked; implementation decision deferred. |
| Identity/auth | No implementation; startup is `AppBootstrap` | Future identity initialization MAY occur only within authorized Shared create/preview/join/identity-required flows | General startup, Personal flows, Home, Widget, backup, and settings MUST NOT implicitly require or initialize Shared identity | Locked |
| Remote access | No remote client or Supabase dependency | Future access MUST pass through a Shared-owned remote abstraction and application boundary | Personal features MUST NOT call Shared remote APIs; UI MUST NOT call the client directly | Boundary locked; implementation decision deferred. |
| Local persistence | `AppDatabase` v5 currently owns Personal tables | Future Shared cache MUST pass through a Shared-owned local abstraction | Shared rows MUST NOT be written through Personal repository mutation paths; database topology is not selected here | Boundary locked; implementation decision deferred. |
| UI models | Personal `Item`, `ItemBundle`, and presentation models | Dedicated Shared UI consumes Shared-owned models/state | MUST NOT map Shared Items to Personal Items for convenience; avoids false support for Personal lifecycle/actions | Locked |
| Discovery | No discovery implementation | v1 list may reflect only device-local successfully projected Shared Packs authorized by upstream specs | MUST NOT add hidden membership discovery, `listMySharedPacks`, recovery scan, or startup listing | Locked |
| Global Activity and Item management | Personal reminder pages/providers | Remain Personal-only in v1 | MUST NOT aggregate Shared actions or Shared Items; these integrations are outside v1 | Locked |
| Background/realtime | No Shared implementation | No Shared background or realtime work in v1 | MUST NOT add background sync, retry worker, realtime listener, outbox, or merge engine | Locked |

## 14. App-level Integration Boundaries

### 14.1 Composition root

`ProviderScope` in `lib/main.dart`, `ReminderApp`, `AppBootstrap`, and `appRouterProvider` are app-level composition surfaces. Future Shared implementations MAY be wired from app-level composition, but Shared logic MUST remain under `lib/features/shared_packs/`.

`AppBootstrap` currently initializes Personal attention notification/badge behavior and Home Widget refresh. Shared identity, refresh, mutation recovery, discovery, or background work MUST NOT be added to this general startup path in v1.

### 14.2 Navigation

Future dedicated Shared routes may be registered in `lib/app/router.dart` only after the Phase 1f route map is approved. They MUST point to Shared-owned UI. Existing Home, Item management/edit/history, Resource, StageTracker, Settings, and More routes MUST NOT be repurposed as Shared mutation surfaces.

### 14.3 Database composition

`appDatabaseProvider` currently creates one `AppDatabase`, but that fact does not decide future Shared database topology. Whether Shared cache is registered in the existing database or a separate database is Phase 1b. In either topology, callers MUST see a Shared-owned local abstraction rather than `ReminderDao`.

### 14.4 Backup, import, and reset

The existing backup payload is Personal. Future schema work MUST prove that Personal export excludes Shared data, Personal import cannot replace Shared data, and Personal reset cannot delete Shared cache/access state. Phase 1a locks those outcomes but does not modify SQL or behavior.

### 14.5 Identity and remote availability

Personal app startup and Personal flows MUST remain usable without Shared identity or remote connectivity. Future Shared identity creation is lazy and flow-scoped. An identity failure MUST remain contained within the Shared flow and MUST NOT block app launch or Personal use.

## 15. Forbidden Dependencies and Shortcuts

The following are prohibited:

1. adding Shared fields to the existing Personal `Item`, `ItemPack`, `ItemBundle`, or their Drift tables;
2. making `ReminderDao` manage Personal and Shared mutation paths;
3. placing Shared remote APIs or DTOs in `ItemRepository` or any other Personal repository;
4. making `HomeRepository`, Home providers, or `AttentionSummaryRepository` read Shared cache;
5. mapping Shared Items into Personal Items to reuse Personal UI, notification, Widget, history, or action behavior;
6. allowing Shared UI/providers to patch local Shared rows directly;
7. letting each mutation response implement its own local row patch instead of using the one future snapshot projector boundary;
8. allowing UI/controllers/providers to call Supabase or another concrete remote client directly;
9. moving Shared business rules into `lib/app/`, router code, `AppBootstrap`, or a global service;
10. initializing Shared identity during general app startup, Personal flows, Home, Widget, backup, or unrelated settings flows;
11. using Personal reset/import as a Shared unlink, recovery, or cache rebuild mechanism;
12. exposing Shared cache through Personal provider types or repository queries;
13. introducing background sync, realtime, outbox, automatic merge, hidden retry worker, or membership discovery in v1;
14. treating invite responses as Pack snapshots or changing cache version because invite state changed;
15. continuing mutation from known-untrusted cache or presenting projection failure as confirmed remote failure.

Each prohibition protects at least one of: authority separation, snapshot completeness, version monotonicity, security reviewability, retry safety, or the locked v1 surface scope.

## 16. Architecture Decision Register

### 16.1 Accepted decisions

| ID | Decision | Rationale / consequence |
| --- | --- | --- |
| SP-ARCH-001 | Shared Pack MUST be an independent feature rooted at `lib/features/shared_packs/` | Makes ownership and forbidden imports auditable |
| SP-ARCH-002 | Shared domain MUST NOT reuse `ItemRepository` as persistence or mutation path | Personal is local-first; Shared is remote-authoritative |
| SP-ARCH-003 | Shared cache, remote adapter, providers, and UI are owned by the Shared feature | Prevents adapter and presentation leakage into Personal code |
| SP-ARCH-004 | Shared Pack v1 MUST NOT enter Home, Home Widget, or notification | Preserves the explicitly excluded v1 surfaces and avoids background writes |
| SP-ARCH-005 | Every Shared mutation MUST pass through the Shared application boundary | Centralizes policy sequencing, retry intent, trust gating, and outcome separation |
| SP-ARCH-006 | Shared UI MUST NOT operate a local DAO or remote client directly | Prevents bypass of remote-first and projection rules |
| SP-ARCH-007 | App composition root only wires dependencies and navigation | Shared business logic stays feature-owned and testable |
| SP-ARCH-008 | Shared and Personal MAY coexist at app level but MUST NOT share an authority model | Coexistence does not imply common persistence or mutation semantics |
| SP-ARCH-009 | Every future authoritative snapshot source MUST enter one Shared projector boundary | Prevents mutation-specific partial cache truth; projector design is Phase 1c |
| SP-ARCH-010 | Known-untrusted-cache mutation blocking belongs to Shared application/runtime | Protects mutation safety; persistence and state machine remain Phases 1b/1d |
| SP-ARCH-011 | Shared providers compose feature dependencies but do not own authoritative rules | Keeps Riverpod replaceable and prevents policy duplication |
| SP-ARCH-012 | Personal startup remains independent of Shared identity and remote availability | Preserves existing local-first use and lazy identity constraint |
| SP-ARCH-013 | Shared local persistence is accessed only through a Shared-owned abstraction | Keeps database topology replaceable and prevents `ReminderDao` coupling |
| SP-ARCH-014 | Shared remote access is exposed only through a Shared-owned abstraction | Keeps transport and security details out of Personal/domain/UI code |
| SP-ARCH-015 | Personal backup/import/reset MUST exclude or preserve Shared state according to their direction | Prevents local maintenance operations from destroying unrecoverable v1 access |
| SP-ARCH-016 | No v1 membership discovery API or implicit recovery scan exists | Runtime recovery cannot expand product scope |

### 16.2 Rejected decisions

| ID | Rejected option | Why rejected |
| --- | --- | --- |
| SP-ARCH-R001 | Add Shared fields to the existing Personal Item model/table | Creates one misleading model with incompatible authority and lifecycle semantics |
| SP-ARCH-R002 | Let `ReminderDao` manage Personal and Shared mutations | Makes remote-first mutation and Personal local transactions indistinguishable |
| SP-ARCH-R003 | Put Shared remote API calls in `ItemRepository` | Allows Personal callers to bypass Shared policy, version, and trust boundaries |
| SP-ARCH-R004 | Let Home providers read Shared cache | Silently adds Shared to Home, attention, notification, badge, and Widget downstream consumers |
| SP-ARCH-R005 | Map Shared Items to Personal Items for reuse | Falsely enables Personal actions, history, schedules, backup, and UI assumptions |
| SP-ARCH-R006 | Let UI patch Shared cache rows | Turns projected cache into a mutation authority and breaks remote/local outcome separation |
| SP-ARCH-R007 | Apply per-mutation local fragment patches | A fragment cannot prove the cache is complete for the claimed Pack version |
| SP-ARCH-R008 | Create Shared identity in normal app startup | Makes Personal/local-first availability depend on remote auth and violates lazy identity |
| SP-ARCH-R009 | Add background sync, realtime, or membership discovery in v1 | Expands scope and introduces unapproved recovery/concurrency semantics |
| SP-ARCH-R010 | Put Shared policy in global services or router callbacks | Hides feature ownership and encourages excluded consumers to depend on it |

## 17. Deferred Decisions by Phase

All items below are intentionally unresolved in Phase 1a. A later phase MUST preserve Sections 6–16 while deciding them.

### Phase 1b — Local Cache Schema Design

- existing `AppDatabase` versus a separate database;
- Shared tables and column types;
- foreign keys and unique indexes;
- resulting schema version;
- any v5→v6 migration;
- trust-state storage representation;
- snapshot fingerprint storage representation;
- pending-mutation persistence;
- backup/import/reset SQL contract and proof of Shared preservation/exclusion.

Decision owner: Phase 1b schema design. **Boundary locked; implementation decision deferred.**

### Phase 1c — Snapshot Projector Design

- snapshot validation;
- canonical ordering;
- fingerprint algorithm;
- same-version/different-content behavior;
- older-response behavior;
- projection transaction;
- missing-row deletion/deactivation;
- `notModified` algorithm.

Decision owner: Phase 1c projector design. **Boundary locked; implementation decision deferred.**

### Phase 1d — Runtime Coordination Design

- per-Pack lock;
- database version guard;
- request serialization;
- `clientRequestId` lifecycle;
- unknown remote outcome after app restart;
- trust-state transitions.

Decision owner: Phase 1d runtime design. **Boundary locked; implementation decision deferred.**

### Phase 1e — Remote Security & RPC Design

- Supabase schema and dependency decision;
- RLS;
- RPC-only boundary;
- version increment mechanics;
- idempotency replay design;
- invite constraints implementation;
- concrete error catalog;
- idempotency/diagnostic retention policy.

Decision owner: Phase 1e contract/security design; implementation remains in Phases 3a–3g. **Boundary locked; implementation decision deferred.**

### Phase 1f — Application/UI/Test Contract

- formal ApplicationService API;
- Riverpod state model;
- route map;
- UI failure/recovery states;
- Fake Remote contract;
- automated test matrix;
- final UAT checklist.

Decision owner: Phase 1f application/UI/test contract. Production UI remains Phase 4. **Boundary locked; implementation decision deferred.**

## 18. Phase 1a Review Checklist

- [x] Source specifications and current repository layout were cross-checked.
- [x] Shared Pack is defined as an independent feature with six owned layers.
- [x] Framework-free domain and inward dependency rules are explicit.
- [x] Shared mutation, projection, retry, and trust responsibilities have owners without concrete algorithms.
- [x] Personal repository, DAO, providers, and models are excluded from Shared ownership.
- [x] Home, Widget, notification, badge, Activity, and global Item management exclusions are explicit.
- [x] Backup, import, Personal reset, router, identity, remote access, and local-persistence directions are explicit.
- [x] Accepted and rejected architecture decisions have stable IDs.
- [x] Phases 1b–1f own every deferred implementation decision listed by the gate.
- [x] No Shared Dart directory, dependency, schema, route, UI, provider, or test is authorized by this document.

## 19. Phase 1a Exit Criteria

Phase 1a is complete only when repository validation also confirms:

1. this document exists;
2. feature and layer ownership are explicit;
3. dependency direction is explicit;
4. forbidden dependencies are enumerated;
5. Personal repository/DAO/provider isolation is locked;
6. Home, Home Widget, and notification exclusions are locked;
7. backup/import/reset/router/identity/persistence directions are locked without later-phase implementation;
8. Phase 1b–1f deferrals are complete;
9. no production code, dependency, schema, route, UI, or test changed;
10. runtime behavior did not change;
11. `git diff --check` passes;
12. the working-tree diff contains only the expected documentation change, except for any pre-existing user changes separately reported.

## 20. Next Step

Next allowed step after this gate is reviewed and complete:

```text
Phase 1b: Local Cache Schema Design
```

Phase 1a stops here. It MUST NOT create or implement any Phase 1b decision.
