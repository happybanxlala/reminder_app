# Phase 5J.1 Email Account Binding Smoke Test

This smoke test verifies the current-session Email-change OTP binding path. It is not an Email sign-in, magic-link, account-switching, or recovery restore test.

## Supabase Dashboard Setup

1. Enable Email auth for the Supabase project.
2. Configure the Email change template to show an OTP code using `{{ .Token }}`.
3. Do not add project URL, anon key, SMTP secret, service-role key, real credentials, or test OTP values to this document or committed files.

## Setup

1. Install the app with Supabase config supplied through the existing dart-define path.
2. In developer Settings, create an anonymous remote identity.
3. Confirm Settings shows the account protection warning for an anonymous unprotected remote identity.

## Binding Flow

1. Open Settings.
2. Open `保護共同資料`.
3. Choose `Email`.
4. Enter an Email address and tap `寄出驗證碼`.
5. Confirm the app shows code-sent copy and an OTP input.
6. Enter the OTP from the Email change message and tap `確認驗證碼`.

## Expected Result

1. Settings shows `帳號已受保護`, `已綁定 Email`, and `你的共同 Pack 可透過此 Email 找回`.
2. Account protection status becomes linked/protected with `remoteProvider = email`.
3. The same local user id and same Supabase remote user id are preserved.
4. Phase 5K `恢復共同 Pack` can become available through normal provider invalidation, but recovery does not run automatically.

## Boundaries

- The app does not call Email sign-in or `signInWithOtp`.
- The app does not use a magic link or deep link callback for this MVP.
- The app does not save Email address, OTP code, magic-link token, access token, refresh token, session JSON, credential, service-role key, or plaintext invite code in Drift or backup.
- Binding does not pull/import remote snapshots, discover memberships, create/join packs, upload local-only packs, flush/retry outbox, mutate pending/failed outbox rows, replay backup data, or start background sync.
- If Supabase returns a different UID during verification, the app must show a friendly unsafe-state failure and must not mutate the local user.
