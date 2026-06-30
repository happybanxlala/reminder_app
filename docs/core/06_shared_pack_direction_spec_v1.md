# 06 Shared Pack Direction Spec v1

## 1. 文件目的

本文件用於重新定義 Reminder App 的 Shared Pack 方向。

此文件不是立即實作規格，而是日後重新開發 Shared Pack、Supabase remote model、邀請碼、帳號綁定、資料恢復與雲端同步時的方向基石。

過去 Shared Pack phase 曾快速擴展至 Supabase auth、remote profile、anonymous user、pack mapping、invite、outbox、snapshot、backup、account binding、realtime/sync 等多個範圍，導致程式碼量暴增、資料流難以理解、問題難以定位。

本次重整目標是：

* 保留已驗證方向良好的 UI/UX 想法。
* 降低第一版 Shared Pack 的工程複雜度。
* 讓 Supabase API / table / RPC request 能在程式碼中被清楚查看。
* 將日後資料恢復方向由「本地／雲端」重新定義為「個人／共享」。
* 避免 Codex 在未經 spec 指引下過度擴充功能。

---

## 2. 核心產品語意

Shared Pack 對使用者而言，不應該是一個技術性功能。

使用者心中的模型應該是：

> 「我有一個照顧清單，可以自己用，也可以邀請別人一起用。」

因此，產品語意上只有兩種 Pack：

1. **Personal Pack**

   * 個人使用。
   * 只有自己可見、可完成、可管理。
   * 日後每一個 Personal Pack 都可以各自成為一個 Shared Pack。
   * 日後帳號綁定後，也應可同步至 remote，作為雲端資料的一部分。

2. **Shared Pack**

   * 多人共同使用。
   * 成員可看到同一組 items。
   * 成員可完成 / 更新共同 items。
   * 邀請、成員身份、權限屬於 Shared Pack 的延伸能力。
   * 每一個 Shared Pack 都是獨立的共享範圍，可有自己的邀請碼。

重要原則：

> 「Personal / Shared」是資料的使用範圍。
> 「Local / Remote」只是技術儲存方式，不應成為使用者主要理解方式。

---

## 3. 值得保留的想法

### 3.1 邀請碼 UI/UX 方向可保留

過去 Shared Pack phase 中，邀請碼的 UI/UX 方向值得保留。

保留方向包括：

* 使用者可以在 Pack setting / member area 中建立邀請。
* 邀請碼是使用者可理解、可分享的 Pack 入口。
* 邀請碼必須 scoped to one Pack：不是 user invite code、不是 account invite code、也不是 local device invite code。
* 每個 Shared Pack 可有自己的邀請碼；多個 Shared Pack 因此可以同時存在多組邀請碼。
* 加入者透過輸入邀請碼加入該邀請碼對應的 Shared Pack，而不是加入某個使用者的 workspace。
* 邀請流程應盡量像「加入一個共享清單」，而不是像「設定同步系統」。
* UI 可以先保留為 shell / mock / future-ready，不必第一階段完全接上 remote invite implementation。

範例：

```text
Pack A → K7M 4Q9
Pack B → H8A 2XD
```

邀請碼 UX 的語言應偏向：

* 「邀請成員」
* 「輸入邀請碼」
* 「加入共享 Pack」
* 「成員」

「由誰完成」

邀請碼  格式
- Change invite codes to 6 characters.
- Use uppercase human-friendly alphanumeric characters.
- Avoid ambiguous characters:
- 0
- O
- 1
- I
- L
- Suggested character set:
- ABCDEFGHJKMNPQRSTUVWXYZ23456789
- Display may visually group the code as "K7M 4Q9", but the canonical stored/query code should be "K7M4Q9".
- Do not require users to type spaces or hyphens.

避免使用者看到過多技術語言，例如：

* remote profile
* Supabase user
* anonymous identity
* remote mapping
* RLS
* outbox
* snapshot

---

### 3.2 Supabase API / request table 必須更易查看

過去實作中，Supabase request 分散在不同 service、repository、controller、debug flow 中，令後續維護者難以知道：

* app 到底呼叫了哪些 Supabase table？
* 哪些地方使用 RPC？
* 哪些 request 需要 auth？
* 哪些 request 會寫入 remote？
* 哪些 request 只讀取 snapshot？
* 哪些 request 會影響 local Drift cache？
* 哪些 request 是 debug-only？

日後所有 Supabase request 必須集中登記。

#### 必須新增 Remote Request Catalog

建議文件：

```text
docs/core/07_remote_request_catalog.md
```

Concrete remote request entries are tracked in `docs/core/07_remote_request_catalog.md`.

每個 Supabase request 必須有一筆紀錄：

| 欄位              | 說明                                               |
| --------------- | ------------------------------------------------ |
| Request ID      | 穩定 ID，例如 `shared_pack.create_pack.v1`            |
| Feature         | shared_pack / account_binding / cloud_restore 等  |
| Code entry      | 實際呼叫位置                                           |
| Supabase object | table / view / RPC name                          |
| Operation       | select / insert / update / delete / rpc          |
| Auth required   | anonymous / linked account / service not allowed |
| Input DTO       | request input model                              |
| Output DTO      | response model                                   |
| Local effect    | 是否寫入 Drift / cache / mapping                     |
| Error behavior  | 失敗時 UI 怎樣顯示                                      |
| Test coverage   | 對應 unit / integration / manual test              |
| Notes           | RLS、限制、日後改動備註                                    |

#### 程式碼集中原則

UI、controller、provider、screen 不應直接呼叫 Supabase。

禁止在 UI 或一般 controller 中散落：

```dart
supabase.from('...')
supabase.rpc(...)
supabase.auth...
```

Supabase request 應集中在 remote gateway / remote data source 內。

建議結構：

```text
lib/features/shared_pack/remote/
  shared_pack_remote_api.dart
  shared_pack_remote_dto.dart
  shared_pack_remote_mapper.dart
  shared_pack_remote_request_ids.dart
  shared_pack_remote_repository.dart
```

其中：

* `shared_pack_remote_api.dart`

  * 唯一可以直接呼叫 Supabase table / RPC 的地方。
* `shared_pack_remote_request_ids.dart`

  * 對應 `docs/core/07_remote_request_catalog.md` 的 Request ID。
* `shared_pack_remote_dto.dart`

  * 所有 remote input / output DTO。
* `shared_pack_remote_mapper.dart`

  * remote DTO 與 local/domain model 的轉換。
* `shared_pack_remote_repository.dart`

  * 對 domain/service 層提供乾淨方法。

Codex 實作新 request 前，必須先更新 request catalog，再寫 code。

---

## 4. 第一版 Shared Pack 的最小範圍

Shared Pack v1 不應再一次過實作完整同步系統。

第一版只需要完成以下產品目標：

> A 更新 Shared Pack item 後，B 手動刷新，可以看見更新結果。

這是 Shared Pack v1 的唯一核心驗收標準。

### Shared Pack v1 應包含

* 建立 Shared Pack。
* Pack 有 owner。
* Pack 可以有 member。
* Invite code UI/UX 可以保留。
* 成員可加入 Shared Pack。
* Shared Pack items 可以由成員共同查看。
* A 完成 / 更新 item 後，寫入 remote。
* B 手動 refresh 後，拉取 remote snapshot。
* B 本機畫面更新後可見 A 的更新。

### Shared Pack v1 不包含

以下功能不應在 v1 實作：

* realtime sync
* background sync
* offline outbox
* conflict resolution
* automatic retry queue
* widget shared action
* backup restore remote access
* account switching
* Google / Apple OAuth
* 多裝置完整同步
* 複雜 completion history merge
* shared pack 與 personal pack 的完整雲端統一模型

若 Codex 在 v1 中主動加入以上範圍，視為違反本 spec。

---

## 5. 資料流原則

Shared Pack v1 的資料流必須保持可解釋。

### 寫入流程

```text
User action
→ local validation
→ call shared_pack_remote_api
→ remote success
→ update local Drift cache
→ UI refresh
```

v1 不做「先 local 成功、之後慢慢推 remote」的 outbox 模式。

原因：

* 使用者目前更需要理解資料流。
* 工程上可更容易 debug。
* 失敗時可明確知道 remote request 失敗。
* 避免過早引入 pending action / retry / conflict 狀態。

### 讀取流程

```text
User taps refresh
→ call remote snapshot/read API
→ map remote DTO
→ update local Drift cache
→ UI displays latest data
```

v1 不做 realtime listener。

---

## 6. Remote ID / Local ID 原則

本機資料可繼續使用 local ID。

Remote 資料可有 remote ID。

但 mapping 必須集中管理，不應散落在不同 model。

建議保留 mapping 概念，但簡化為清楚、少量、可查：

```text
local_pack_id  <-> remote_pack_id
local_item_id  <-> remote_item_id
```

Codex 不應在多個 unrelated tables 中新增不同形式的 mapping 欄位。

所有 mapping table / field 必須在 core model spec 中清楚列出。

---

## 7. Invite Code 方向

Invite code 是 Shared Pack 的主要加入方式。

Invite code 的 scope 是「單一 Pack」：

* Owner-side invite UX 必須放在 Pack context 內，例如 Pack settings / member area。
* Joiner-side invite UX 可以放在 Settings 作為全域入口，但輸入後應解析到一個 specific Pack。
* Invite code 不代表使用者、帳號、workspace 或本機裝置。
* 多個 Shared Pack 可以有多個 invite codes。
* 若使用者擁有 Pack A 與 Pack B，兩個 Pack 的邀請碼應分別管理、分別加入。

### UX 流程

Owner side:

```text
Pack settings
→ Members
→ Invite member
→ Generate invite code
→ Share code
```

Joiner side:

```text
Settings / Shared Pack entry
→ Enter invite code
→ Preview pack name
→ Confirm join
→ Pack appears in Home / Pack list
```

### v1 可接受限制

* Invite code 可有簡單 expiry，或先不做 expiry。
* Invite code 可先只支援 dev / manual test。
* Invite code 不需要一開始支援 revoke / rotate。
* Invite code 不需要一開始支援 QR code / deep link。
* Invite code 不需要一開始支援多角色權限。

### 日後可擴展

* QR code
* link invite
* revoke invite
* invite history
* owner / editor / viewer roles
* 成員移除
* 加入審批

---

## 8. 帳號綁定與資料恢復方向

帳號綁定與資料恢復是重要方向，但不屬於 Shared Pack v1。

日後帳號綁定後，資料模型應從「本地／雲端」改為「個人／共享」。

### 8.1 未綁定帳號前

未綁定帳號時，app 可以存在：

* device-local personal data
* limited remote shared data, if Shared Pack v1 requires anonymous remote identity
* local cache for remote shared packs

此階段應清楚告知使用者：

> 此裝置上的個人資料尚未受到帳號保護。

但不應將使用者暴露在過多 remote identity 細節中。

---

### 8.2 綁定帳號後

當使用者完成帳號綁定後：

* Personal Pack 應可推上 remote。
* Shared Pack 本身已在 remote。
* 本機 Drift 變成 local cache / offline-readable cache。
* 使用者心中的資料分類應是：

  * Personal
  * Shared

而不是：

* Local
* Cloud

### 8.3 Product wording

建議用語：

* 「個人 Pack」
* 「共享 Pack」
* 「帳號保護」
* 「雲端備份」
* 「換機恢復」
* 「已綁定帳號」

避免用語：

* 「本地 Pack」
* 「遠端 Pack」
* 「remote-backed」
* 「anonymous remote」
* 「Supabase UID」
* 「local-only / remote-only」

技術上可以仍然存在 local / remote，但 UI 不應以此作為主要語言。

---

## 9. 帳號綁定後的雲端資料模型方向

長期方向：

> 帳號綁定後，所有 active data 都應 remote-backed。
> Personal / Shared 只是 access scope，不是 storage location。

### Personal Pack

* owner = current account
* only owner can access
* 可同步至其他裝置
* 可透過帳號恢復

### Shared Pack

* pack 有 owner
* pack 有 members
* members 根據權限存取
* 可透過帳號恢復 membership
* 換機後登入同一帳號，應可重新取得 shared packs

### 本機 Drift

帳號綁定後，本機 Drift 不再是唯一資料來源。

它的角色是：

* app 快速顯示資料
* offline-readable cache
* widget / notification 的 local source
* remote snapshot 的本機投影

但 authoritative data 應逐步轉為 remote。

---

## 10. 資料恢復不應依賴傳統 local backup

長期方向中，傳統 backup 不應負責恢復 remote access。

Backup 可以保留為 legacy local export。

但帳號綁定後，主要恢復方式應是：

```text
Install app
→ Login / bind account
→ Pull personal packs
→ Pull shared memberships
→ Rebuild local cache
```

Backup 不應包含：

* Supabase access token
* refresh token
* service role key
* plaintext invite code as recovery method
* other user credentials

---

## 11. 實作分期建議

### Restart Phase 0：封存舊 Shared Pack

目標：

* 保留舊 phase 作為 archive branch / tag。
* 回到沒有 Shared Pack 的穩定版本。
* 不直接刪除過去成果。
* 從舊成果中提取：

  * invite UI/UX
  * useful docs
  * SQL ideas
  * request catalog idea
  * account binding lessons

完成條件：

* app 回到穩定可跑狀態。
* 舊 Shared Pack code 不再污染 main development branch。
* 新 spec 成為後續基石。

---

### Restart Phase 1：Shared Pack UX Shell

目標：

* 在不接 remote 的情況下，整理 Shared Pack 的產品語言。
* 保留邀請碼 UI/UX 方向。
* 使用 mock / disabled / future-ready 狀態。

包含：

* Pack type: personal / shared
* Members section
* Invite member entry
* Enter invite code entry
* Shared Pack wording

不包含：

* Supabase request
* actual invite join
* remote sync
* account binding

---

### Restart Phase 2：Remote Request Catalog Foundation

目標：

* 建立 Supabase request catalog。
* 建立 remote API code boundary。
* 確保所有 remote call 可被查閱。

包含：

* `docs/core/07_remote_request_catalog.md`
* remote API folder structure
* Request ID convention
* no scattered Supabase calls rule
* basic tests ensuring UI/controller does not directly call Supabase

完成條件：

* 開發者可以從 request catalog 查到所有 remote request。
* 開發者可以從 remote API file 找到所有 Supabase table/RPC calls。

---

### Restart Phase 3：Shared Pack v1 Manual Refresh

目標：

* 完成最小 Shared Pack。
* A 更新，B 手動刷新後看見。

包含：

* minimal remote shared pack tables
* create shared pack
* join by invite code
* member reads pack
* member updates item
* manual refresh
* local cache update

不包含：

* realtime
* outbox
* background sync
* full cloud personal data
* account recovery

---

### Restart Phase 4：Account Binding Foundation

目標：

* 讓使用者可綁定帳號。
* 明確定義帳號保護資料的邊界。
* 不立即做完整 cloud migration。

包含：

* bind account UI
* account status UI
* safe language
* no token in backup
* no provider-specific overbuild

不包含：

* multi-provider account switching
* automatic full restore
* full remote upload of all personal data

---

### Restart Phase 5：Personal Data Cloud Migration

目標：

* 帳號綁定後，將 Personal Pack 推上 remote。
* 將資料模型逐步改為 Personal / Shared，而非 Local / Cloud。

包含：

* upload personal packs
* upload personal items
* remote ownership
* local cache rebuild
* duplicate prevention
* migration status

不包含：

* realtime
* complex conflict resolution
* multi-device simultaneous editing

---

### Restart Phase 6：Realtime / Offline / Advanced Sync

只有在 Phase 3-5 穩定後，才可考慮：

* realtime updates
* offline outbox
* retry queue
* conflict handling
* background sync
* widget shared pack actions
* advanced recovery

---

## 12. Codex 開發守則

Codex 在實作 Shared Pack 相關功能前，必須遵守以下規則：

1. 不可未更新 spec 就新增 Supabase table / RPC / request。
2. 不可在 UI / controller 中直接呼叫 Supabase。
3. 不可把 realtime、outbox、account binding、backup recovery 混入 Shared Pack v1。
4. 不可將使用者 UI 語言設計成 local / remote。
5. 不可在未定義 migration strategy 前，自動把 personal data 推上 remote。
6. 不可在 backup 中保存 Supabase token / credentials。
7. 每個 phase 必須有清楚 manual test。
8. 每個 phase 完成後，開發者必須能用文字說明：

   * A 的操作寫到哪裡？
   * B 的刷新讀哪裡？
   * local cache 何時更新？
   * remote request 在哪個 file？
   * request catalog 對應哪一條？

---

## 13. 成功標準

Shared Pack 重啟成功，不以功能數量衡量。

成功標準是：

* 使用者能理解 Shared Pack 是什麼。
* 開發者能理解資料怎樣流動。
* Supabase request 可被集中查看。
* 第一版做到 A 更新、B refresh 可見。
* 邀請碼 UX 清楚自然。
* 帳號綁定與資料恢復方向沒有與 Shared Pack v1 混在一起。
* project 沒有因為過早實作完整 sync system 而再次失控。

---

## 14. 停止條件

若開發過程出現以下情況，應停止新增功能並回到 spec：

* Codex 開始新增未規劃的 sync / realtime / outbox。
* Supabase request 再次分散在多個 UI/controller file。
* 使用者無法說明 A 更新後 B 如何看到。
* bug 需要靠更多 debug-only UI 才能理解。
* Personal / Shared 與 Local / Remote 再次混淆。
* migration / backup / account binding 被提前塞入 Shared Pack v1。

當出現以上情況，應先整理資料流與 request catalog，不應繼續加功能。

---

## 15. 最終方向總結

Reminder App 的長期方向不是做一個「本地 app 加上一些雲端功能」。

長期方向應是：

> 一個以 Personal Pack / Shared Pack 為核心的照顧提醒 app。
> 未綁定帳號時，資料主要受限於裝置。
> 綁定帳號後，個人與共享資料都可被帳號保護、同步與恢復。
> 本機資料庫是快取與裝置整合層，不是使用者需要理解的產品分類。

Shared Pack 重新開發時，第一步不是做更多同步，而是重新建立簡單、可理解、可維護的資料流。
