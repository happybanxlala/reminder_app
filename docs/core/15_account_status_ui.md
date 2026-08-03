# 15 Account Status UI

## 1. Purpose

Phase 4D adds product UI for account status only.

The UI helps users understand whether the current device is protected by an account and what remains unavailable.

Phase 4D does not implement login.

Phase 4D does not implement OAuth.

Phase 4D does not call Supabase.auth.

Phase 4D does not activate Shared Pack production UI.

Phase 4D does not migrate Personal Pack data.

## 2. Relationship to Phase 4A

Reference: `docs/core/12_account_binding_foundation_spec.md`

The UI follows the confirmed account binding definition:

Account binding connects the current device's user data and shared identity to a stable account identity that can be recovered and re-verified later.

The UI must not claim that account binding, full cloud sync, or restore is already complete.

## 3. Relationship to Phase 4C

Reference: `docs/core/14_account_identity_runtime_foundation.md`

The UI reads `AccountIdentityRuntime` snapshots.

Default production runtime remains unbound.

Tests may use `FakeAccountIdentityRuntime` to render non-default states.

## 4. UI Location

Account status appears in:

Settings -> 帳號保護

The section appears after general settings and before data management.

## 5. Supported States

### unbound

Title: 帳號未綁定

Body: 此裝置上的 Personal Pack 資料尚未受到帳號保護。

Note: 綁定帳號後，日後可支援雲端備份與換機恢復。Shared Pack 功能亦會使用帳號保護成員身份。

Action enabled: no

Not promised: Personal Pack cloud sync, full restore, Shared Pack production flow.

### binding

Title: 正在綁定帳號

Body: 正在準備帳號保護。

Action enabled: no

Not promised: a real binding flow. This state may be driven by tests or future runtime only.

### bound

Title: 帳號已綁定

Body: 此裝置已有帳號保護身份。

Note: Personal Pack 雲端同步將於後續階段處理。

Action enabled: no

Not promised: full Personal Pack cloud sync or complete device restore.

### bindingFailed

Title: 帳號綁定未完成

Body: 帳號綁定未能完成，請稍後再試。

Action enabled: no

Not promised: retry, login, or OAuth flow.

### needsReauth

Title: 需要重新驗證帳號

Body: 請重新驗證帳號，之後才能繼續使用帳號保護功能。

Action enabled: no

Not promised: re-auth flow.

## 6. Default Production Behavior

Default production account status is unbound.

No login action is active in Phase 4D.

No remote request is made.

No Supabase.auth call is made.

## 7. Product Honesty Rules

- Do not claim Personal Pack data is fully backed up.
- Do not claim restore is complete.
- Do not claim Shared Pack production flow is active.
- Do not expose technical identity, token, Supabase, Local Pack, Remote Pack, mapping, snapshot, RPC, or outbox wording to users.

## 8. Test/Fake State Coverage

`FakeAccountIdentityRuntime` is used in tests to render all states.

Fake status rendering does not make account binding production-active.

Phase 4E Shared Pack Account Identity Bridge is defined in `docs/core/16_shared_pack_account_identity_bridge.md`.

The bridge uses the same account runtime boundary, but Account Status UI remains informational and does not activate Shared Pack production flows.

## 9. What Phase 4D Enables

Phase 4D enables:

- visible account protection status
- safer user education before real binding
- later account binding UI/runtime work

## 10. What Phase 4D Does Not Enable

Phase 4D does not enable:

- real account binding
- login
- OAuth
- Supabase auth
- Shared Pack production invite/join/refresh
- Personal Pack cloud sync
- restore
- realtime
- outbox
- background sync

## 11. Stop Conditions

Stop if:

- login UI is added
- OAuth is added
- Supabase.auth is added
- Shared Pack is marked active_v1_manual
- Personal Pack migration starts
- UI claims all data is backed up
- UI exposes Supabase, technical identity, token, Local Pack, or Remote Pack wording

## 12. Final Status Marker

phase_4d_status: account_status_ui_added

Phase 4D adds Account Status UI.

Default production account status remains unbound.

It does not implement real account binding.

It does not activate Shared Pack production UI.

The next phase is Phase 4E: Shared Pack Account Identity Bridge.

Shared Pack activation still requires explicitly approved account binding/runtime activation later.
