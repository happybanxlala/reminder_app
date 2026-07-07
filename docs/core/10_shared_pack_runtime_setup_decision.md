# 10 Shared Pack Runtime Setup Decision

## 1. Purpose

This document decides whether Shared Pack v1 can become active from product UI before Phase 4 account binding.

It is a review and guardrail record only. It does not implement runtime setup, account binding, Supabase startup, production identity, sync, restore, or new user-visible behavior.

Phase 3 closure record: `docs/core/11_shared_pack_phase_3_closure.md`.

Phase 4B config boundary record: `docs/core/13_secure_runtime_config_boundary.md`.

Phase 4B addresses the Supabase config blocker, but Shared Pack production activation still waits for identity/runtime setup.

Phase 4C identity runtime foundation record: `docs/core/14_account_identity_runtime_foundation.md`.

Phase 4C addresses account identity runtime foundation, but Shared Pack product activation still waits until account identity and UI wiring are safe.

The existing dev-gated recommendation remains true until a later phase explicitly changes the request catalog and production wiring.

## 2. Current State

- Remote schema and RPC contracts exist in `supabase/migrations/20260630000000_shared_pack_v1_remote_schema.sql`.
- Remote-side RPC smoke test exists at `supabase/tests/shared_pack_v1_rpc_smoke_test.sql` and has been run locally.
- Flutter remote API wrappers exist under `lib/features/shared_pack/remote/`.
- Local Drift mapping and cache projection exist through `SharedPackCacheProjectionService`.
- `SharedPackApplicationService` coordinates remote calls, identity, and local cache projection.
- Dev/manual harness coverage exists in `test/shared_pack_dev_manual_flow_test.dart`.
- Product UI wiring exists through `SharedPackUiController`, but default runtime remains setup-required and disabled.
- The six Shared Pack v1 request catalog entries remain `implemented_not_wired`.

## 3. Decision Question

Can Shared Pack v1 product UI be safely enabled as active from product UI before full account binding?

## 4. Required Runtime Pieces

1. Supabase client config
   - Requires a project URL and anon key.
   - Requires a safe configuration strategy that does not commit real values.
   - Must never use a service role key in the app.
   - Must never use `DATABASE_URL` in the app.
   - Current repo has no production-safe Supabase config convention.

2. Identity provider
   - Remote RPCs require owner, joiner, and requester identity IDs.
   - `StaticSharedPackIdentityProvider` exists for tests and dev/manual harnesses only.
   - A temporary device-scoped identity could support experiments, but would not provide reliable recovery after reinstall or device loss.
   - Account binding remains Phase 4.
   - Current repo has no production identity provider.

3. Application service provider wiring
   - The UI facade can call `SharedPackApplicationService` when explicitly supplied.
   - Production provider wiring would need `SharedPackRemoteRepository`, `SharedPackRemoteApi`, `SupabaseClient`, `SharedPackCacheProjectionService`, and `SharedPackIdentityProvider`.
   - Current default provider intentionally returns setup-required / disabled.

4. User-facing safety wording
   - Product UI must not claim account protection, cloud backup, restore, or recovery until those features exist.
   - User-facing copy must avoid technical identity, Supabase, RPC, RLS, mapping, snapshot, outbox, and remote wording.
   - Setup-required wording remains the safest current product state.

## 5. Option A: Enable active_v1_manual in Phase 3

This would require:

- Supabase config supplied through a safe runtime convention.
- A stable-enough identity provider for owner, joiner, and requester IDs.
- UI calls routed through `SharedPackUiController` and `SharedPackApplicationService`.
- Request catalog status changes only for requests truly reachable from product UI.
- Manual refresh only; no realtime, outbox, retry queue, or background sync.
- No account protection, backup, or recovery claim.

Risks:

- Device-scoped identity may not survive reinstall or device loss.
- Shared Pack membership may not be recoverable before Phase 4.
- Users may misunderstand Shared Pack as account-protected.
- Remote shared data may exist without a proper account recovery path.

## 6. Option B: Keep Dev-gated Until Phase 4

This keeps:

- Default product UI setup-required.
- Six Shared Pack v1 request statuses as `implemented_not_wired`.
- Phase 3 focused on remote schema, boundary, projection, service, dev harness, and UI guardrails.
- Product activation behind Phase 4 account binding / runtime setup decisions.

Benefits:

- Avoids temporary identity confusion.
- Avoids premature account-like behavior.
- Aligns with long-term account protection, cloud backup, and restore direction.
- Preserves clear Product language: Personal Pack / Shared Pack.

Cost:

- Shared Pack UI is not production-active yet.
- Two-device QA remains dev/manual only.

## 7. Recommended Decision

Recommendation marker: `keep_dev_gated_until_phase_4`.

Shared Pack v1 should not become active from product UI in Phase 3.

Exact blockers:

- No production-safe Supabase config convention.
- No production identity provider.
- Device-scoped identity is not approved for product activation because membership recovery is unclear.
- Production wording could imply account protection before account binding exists.
- Product activation would blur Phase 3 runtime setup with Phase 4 account binding.

Phase 4 must solve:

- Safe Supabase client config.
- Account or identity source.
- Recovery expectations for Shared Pack membership.
- User-facing wording for account protection, cloud backup, and restore.

Phase 3I should verify instead:

- Dev-gated UI hardening.
- Guardrails against direct Supabase calls from UI/provider/startup.
- Manual harness coverage and docs.
- Phase 4 handoff checklist.

## 8. Security / Secret Handling Decision

- No service role key in the app.
- No `DATABASE_URL` in the app.
- No access token, refresh token, database password, or real credential in committed files.
- No Supabase tokens or credentials in backup/export files.
- An anon key may become client config only after a safe config convention is approved.
- Real runtime values must not be committed.

## 9. Identity Boundary Decision

Device-scoped identity is not approved for production product activation in Phase 3.

Reasons:

- It may not survive reinstall or device loss.
- It does not imply account protection.
- It does not provide clear membership recovery.
- It is difficult to explain safely without exposing technical identity concepts.

Current identity status:

- `StaticSharedPackIdentityProvider` remains dev/test/manual only.
- Production identity remains unresolved.
- Product UI remains setup-required.
- Phase 4 must replace or formalize the identity boundary.

## 10. Request Catalog Status Decision

The six Shared Pack v1 requests remain `implemented_not_wired`.

They do not become active because production UI cannot safely call the real service without runtime config and identity.

## 11. Phase 3I Recommendation

Phase 3I should be Dev-gated v1 Hardening + Phase 4 handoff checklist.

It should verify:

- setup-required product UI remains clear
- fake/dev UI coverage remains useful
- no secrets are committed
- no direct Supabase calls leak outside the remote boundary
- no Personal Pack completion behavior changes
- Phase 4 prerequisites are documented

## 12. Stop Conditions

Stop if implementation requires:

- OAuth or account login
- account recovery
- storing credentials
- UI wording that implies account protection before it exists
- direct Supabase calls outside the remote boundary
- realtime, outbox, retry queue, background sync, or conflict resolution
- widget shared actions
- personal cloud migration or backup restore
