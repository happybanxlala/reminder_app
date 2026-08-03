# 06 Shared Pack Direction Spec v1

Status: planned product direction / not implemented.

本文件定義 Reminder App 的 Shared Pack 產品方向與 phased scope。Shared Pack v1 尚未在 production code 中實作；目前 repository 沒有 Supabase dependency、remote table、RPC、Shared Pack route、Shared Pack repository、anonymous auth 或 Shared Drift cache table。

本文件不是現有 local Reminder domain 的替代品。現有 core/local model 仍以 `docs/core/04_core_model_spec_v1.md` 為準；Home Widget 邊界以 `docs/core/05_home_widget_spec.md` 為準；planned remote request contract 以 `docs/core/07_shared_pack_remote_contract_v1.md` 為準；planned runtime consistency、response ordering、cache trust 與 failure semantics 以 `docs/core/08_shared_pack_runtime_consistency_spec_v1.md` 為準。

## 1. 文件目的

Shared Pack 重新開發前，先鎖定產品語意與第一版邊界，避免再次把 Supabase auth、remote profile、anonymous user、remote identity mapping、invite、outbox、snapshot、backup、account binding、realtime / sync 等多個範圍一次塞進 v1。

Phase 0 的目標是讓後續開發者能清楚回答：

- Shared Pack v1 共享什麼。
- Shared Pack v1 不共享什麼。
- Owner 和 Member 分別可以做什麼。
- A 完成 Item 時，資料寫到 remote authoritative layer，再投影回 local Drift cache。
- B 手動刷新時，資料從 remote current-state snapshot 取得。
- local Drift cache 只在 remote 成功或 snapshot refresh 成功後更新。
- 哪些既有功能明確排除於 v1。

## 2. 核心產品語意

使用者心中的模型應該是：

> 「我有一個照顧清單，可以自己用，也可以邀請別人一起用。」

產品語意上只有兩種 Pack 使用範圍：

- Personal Pack：個人使用，只有自己可見、可完成、可管理。現有 production model 全部屬於 Personal/local-first Pack。
- Shared Pack：多人共同使用，成員可看到同一組 Shared Items，依角色完成或管理 Shared Items。

重要原則：

- Personal / Shared 是資料的使用範圍。
- Local / Remote 是技術儲存方式。
- UI 不應以「本機 / 遠端」作為主要分類。
- Shared Pack v1 的 remote authoritative data 不代表 Personal Pack 也同步到 remote。

## 3. Shared Pack Version Roadmap

Roadmap 只定義語意與依賴順序，不承諾日期。

### 3.1 Shared Pack v1

v1 只包含：

- 建立新的 Shared Pack。
- 第一個 vertical slice 只支援 `ItemType.stateBased` Shared Items。
- `owner` / `member` 兩種角色。
- Pack-scoped member `displayName`，不建立 global profile。
- invite code get-or-create、manual rotate、preview、加入流程。
- Shared Item current state。
- Owner 建立、編輯、封存 Shared Item definition。
- Owner 更新 Shared Pack metadata。
- `done` action。
- 最低限度 actor attribution，例如「由誰完成」。
- remote-first write。
- authoritative remote result。
- 所有改變 Shared Pack active current-state snapshot 的 mutation 都回傳 full active snapshot。
- manual snapshot refresh。
- independent Shared Drift readable cache。
- lazy anonymous identity initialization。
- Shared Pack list / entry。
- compact Shared Pack detail / settings page。
- Shared Item list。
- dedicated Shared Pack surface only。
- Shared Item lifecycle 只有 `active` / `archived`。
- `stateAnchorDate` 只能透過 `completeSharedItem` 推進。
- Invite state 不屬於 active snapshot，不改變 `packVersion`。
- `remoteApiContractVersion = 1` and `remoteSnapshotSchemaVersion = 1`。
- `remotePackVersion` monotonicity and cache trust semantics are defined by `08` as the Phase 0.7 runtime consistency contract.
- Personal data reset preserves Shared cache, anonymous identity/session and Shared Pack remote access metadata。
- Pack 恰好有一個 owner。
- Pack 內 duplicate display names allowed。
- display name validation。
- Shared Pack timestamps use UTC instants。
- `notModified` updates `lastRefreshedAt`。

### 3.2 Shared Pack v1.x

v1.x 可在 v1 資料流穩定後再規格化：

- fixed Shared Item semantics。
- Pack timezone。
- recurring schedule parity。
- undo。
- skip。
- action history。
- Shared Items 進入 app Home attention aggregation。
- global Activity integration。
- notification integration。
- 更完整 member lifecycle。
- leave Shared Pack。
- member removal。
- owner transfer。
- invite automatic expiry policy。
- Shared Item restore / unarchive。

### 3.3 Shared Pack v2

v2 才考慮 Resource graph：

- `Resource`。
- `ResourceActionRecord`。
- `ResourceConsumptionRule`。
- Item completion 的 resource side effects。

### 3.4 Shared Pack v3

v3 才考慮 StageTracker graph：

- `StageTracker`。
- `StageRule`。
- `StageRecord`。
- `StageRelatedItem`。

### 3.5 Long-term

長期方向，不屬於 v1：

- Personal Pack → Shared Pack promotion。
- Personal Pack cloud sync。
- account binding。
- identity upgrade。
- device recovery。
- membership recovery。
- realtime。
- background sync。
- offline outbox。
- retry queue。
- conflict resolution / merge engine。
- Shared Home Widget snapshot integration。
- Shared Home Widget direct action。
- full Personal / Shared cloud unified model。

## 4. Shared Pack v1 Domain Boundary

Shared Pack v1 採 state-based Item-only boundary。

v1 涵蓋：

- Shared Pack metadata。
- owner / member membership。
- invite code flow。
- `ItemType.stateBased` Shared Item definition。
- state-based Shared Item current state。
- Item completion。
- 最低限度 actor attribution。
- remote authoritative result。
- local Drift readable cache。
- manual refresh。

v1 不涵蓋：

- `Resource`。
- `ResourceConsumptionRule`。
- Item completion 導致的 Resource consumption。
- `ResourceActionRecord`。
- `StageTracker`。
- `StageRule`。
- `StageRecord`。
- `StageRelatedItem`。
- `PackTemplate`。
- custom template sync。
- `ItemType.fixed`。
- one-time fixed。
- daily / weekly / everyXDays / everyXWeeks / monthly recurring fixed schedule。
- `ItemOverduePolicy`。
- fixed cycle advance。
- fixed schedule timezone calculation。
- 完整 action history sync。
- complex undo chain。
- Personal / Shared 完整雲端統一模型。

現有 Personal Pack 中的 Resource、StageTracker 或其他 relation，不得因 Shared Pack v1 而被暗中加入 remote model。
現有 Personal `FixedItemConfig` 不可為了「通用」而直接複製到 Shared Pack remote DTO；fixed Shared Item 需要先定義 Pack timezone、server completion time 與 calendar cycle semantics。

## 5. Personal To Shared Promotion Is Deferred

Shared Pack v1 只支援：

- 建立一個新的 Shared Pack。

Shared Pack v1 不支援：

- Personal Pack → Shared Pack promotion。
- 把現有 Personal Pack 上傳並轉換成 Shared Pack。
- 複製現有 Personal Pack 成為 Shared Pack。
- 取消共享後轉回 Personal Pack。

長期方向仍可保留「日後 Personal Pack 可以成為 Shared Pack」，但這是 later capability，不屬於 v1，也不可在 v1 migration、backup 或 UI wording 中暗示已支援。

## 6. Owner / Member Permission Matrix

Shared Pack v1 只有兩種角色：

- `owner`
- `member`

| Capability | owner | member |
| --- | --- | --- |
| 查看 Shared Pack | yes | yes |
| 查看 Shared Items | yes | yes |
| 建立 Shared Pack | yes | no |
| `updateSharedPackMetadata` | yes | no |
| `createSharedItem` | yes | no |
| `updateSharedItem` | yes | no |
| `archiveSharedItem` | yes | no |
| `completeSharedItem` | yes | yes |
| `getOrCreateInviteCode` | yes | no |
| `rotateInviteCode` | yes | no |
| 查看成員 | yes | yes |
| 邀請其他成員 | yes | no |
| 移除其他成員 | no in v1 | no |
| 管理 Pack lifecycle | minimal create only | no |

Member 在 v1 不可以：

- 新增 Item。
- 修改 Item definition。
- 修改 schedule / config。
- 封存或刪除 Item。
- 修改 Pack 名稱、icon 或 metadata。
- 建立 invite code。
- 邀請其他成員。
- 移除其他成員。
- 管理 Pack。

v1 暫不實作 `editor`、`viewer` 或其他角色。

Membership invariants:

- 一個 Shared Pack v1 恰好有一個 owner。
- 同一 `authUserId` 在同一 `remotePackId` 最多一個 membership。
- owner membership 在 v1 不可 leave。
- owner membership 在 v1 不可被移除。
- member removal 不屬於 v1。
- owner transfer 不屬於 v1。
- 同一 Pack 同一時間最多一個 active invite code。

Phase 1 technical design 應建立相等於 `unique(remotePackId, authUserId)` 的 database invariant。Membership uniqueness 使用 auth identity，不使用 `displayName`。

## 7. Supported Item Actions

Shared Pack v1 只支援 `done`。

v1 支援：

- 完成 Shared Item。
- 記錄完成者 identity。
- remote 回傳 authoritative Item result。
- remote 成功後更新 local Drift cache。

Shared state-based Item 至少包含：

- title。
- description。
- lifecycleStatus。
- stateAnchorDate。
- infoAfter / warningAfter / dangerAfter。
- completedAt。
- completedByMemberId。
- remote item version。

Shared Item v1 lifecycle 只支援：

- `active`。
- `archived`。

`active` Item 出現在 full active snapshot 與一般 Shared Item list，可被 Owner update，可被 Owner / Member complete，可被 Owner archive。

`archived` Item 不出現在 full active snapshot，不出現在一般 Shared Item list，不可 update，不可 complete。Restore / unarchive 不屬於 v1。

State-based config invariant 必須由 remote server-side 驗證：

```text
0 <= infoAfterMinutes
infoAfterMinutes <= warningAfterMinutes
warningAfterMinutes <= dangerAfterMinutes
```

Threshold values 必須是 non-null integer、不可為負數、不可超出 Phase 1 technical design 設定的合理 database range。

`createSharedItem` 必須提供 `initialStateAnchorDate`。Remote 驗證並 canonicalize 為 UTC instant 後保存為 `stateAnchorDate`，不接受無 anchor 的 active Shared Item。

`updateSharedItem` 只可修改 `title`、`description`、`infoAfterMinutes`、`warningAfterMinutes`、`dangerAfterMinutes`，不可修改 `stateAnchorDate`、completion attribution 或 lifecycle。

`completeSharedItem` 是 v1 唯一可更新一般 state anchor 的操作；authoritative `completedAt` 由 server 產生，`stateAnchorDate = completedAt`，`completedByMemberId` 由 caller membership 推導。

Shared Pack v1 timestamps 使用 UTC instant。DTO 使用 ISO-8601 UTC / offset；UI 顯示時轉成 device local timezone。State elapsed calculation 使用 `currentInstantUtc - stateAnchorDateUtc`。

v1 不支援：

- skip。
- defer。
- undo。
- reverted。
- action history UI。
- complex completion history merge。
- `ItemNextCycleStrategy` 的多種使用者選擇。
- paused Shared Item lifecycle。
- restore / unarchive。

`undo`、`skip`、action history 等能力可列入 Shared Pack v1.x，但不可寫成 v1 已包含能力。

## 8. Anonymous Identity Limitation

Shared Pack v1 暫時使用 anonymous remote identity，避免把完整帳號綁定、OAuth、換機恢復與 membership recovery 塞入第一版。

限制：

- anonymous identity 是 Shared Pack remote access 的最低限度身份。
- Personal Pack 仍可在沒有 remote identity 的情況下維持 local-first。
- Anonymous identity 採 lazy initialization；一般 App launch、Personal Pack、Home、Widget、backup 與一般設定頁不應自動觸發 anonymous sign-in。
- 只有在準備建立 Shared Pack、準備 preview invite code、準備 join Shared Pack，或進入需要 remote identity 的 Shared Pack flow 且 identity 尚不存在時，才呼叫 `SharedIdentityService.ensureIdentity()`。
- Shared Pack 建立、preview invite code 或加入需要成功取得 anonymous remote identity。
- identity initialization 失敗時，不建立 partial Shared Pack、不寫入假的 Shared cache；UI 顯示 calm retryable failure，Personal local-first 功能繼續可用。
- 尚未綁定帳號時，Shared Pack membership 與 remote access 未受到正式帳號保護。
- 刪除 App、清除裝置資料、遺失裝置或更換裝置後，使用者可能失去該 anonymous identity，以及對應的 Shared Pack access。
- 帳號綁定、identity upgrade、換機恢復與 membership recovery 不屬於 Shared Pack v1。

UI wording 不應暴露：

- Supabase UID。
- anonymous user。
- remote profile。
- authenticated role。

產品用語應偏向：

- 尚未綁定帳號。
- 此裝置上的共享存取尚未受到帳號保護。
- 綁定帳號後可支援日後恢復。

Phase 0 不實作 auth、OAuth 或 anonymous sign-in。

## 9. Member Display Name Semantics

Shared Pack v1 不建立 global remote profile。每個 membership 保存該 Pack 內的顯示名稱：

```text
shared_pack_member
- remoteMemberId
- remotePackId
- authUserId
- role
- displayName
- joinedAt
```

產品語意：

- `authUserId` 是技術 identity，不可直接顯示給使用者。
- `displayName` 是 Pack-scoped；同一 anonymous identity 在不同 Pack 可使用不同顯示名稱。
- `displayName` 不代表正式帳號名稱，也不代表 global user profile。
- Pack 內 `displayName` 不要求唯一，允許多位成員使用相同顯示名稱。
- `displayName` 不可用作 authentication、authorization、foreign key、completion actor identity 或 membership uniqueness。
- 真正 identity 使用 `remoteMemberId`。
- Owner 第一次建立 Shared Pack 時必須提供 `ownerDisplayName`。
- Joiner 確認加入 Shared Pack 時必須提供 `memberDisplayName`；`previewInviteCode` 不需要 joiner display name。
- Shared Item completion 以 `completedByMemberId` 對應 membership summary 的 `displayName`，UI 顯示「由 {displayName} 完成」。
- UI 不顯示 Supabase UID 或把 Supabase UID 當成使用者名稱。

`ownerDisplayName` 與 `memberDisplayName` validation：

- trim leading / trailing whitespace。
- trim 後不可為空。
- 不能只包含空白。
- 最大 40 Unicode code points。
- 可包含空格、中文、英文、數字及一般 emoji。
- 不可使用 `authUserId` / Supabase UID 作 fallback 公開名稱。

## 10. Product Surface Boundary

Shared Pack v1 第一個 vertical slice 只出現在：

- Shared Pack list / entry。
- Shared Pack detail。
- Shared Item list。
- Invite code owner flow。
- Invite code joiner flow。
- manual refresh。
- Shared Item done action。

Shared Pack v1 暫不整合：

- app Home attention aggregation。
- global Activity feed。
- global Item management grouping。
- notification scheduling。
- Home Widget snapshot。
- Home Widget action。
- traditional local backup restore。
- Personal Pack data flow。

Shared Item 即使已投影到 local Drift，也不代表它自動進入所有現有 repository query、Home、Widget、通知或 backup。這些整合應放入 v1.x 或後續 phase，並先更新對應 spec。

## 11. Data Flow Principles

Shared Pack v1 的資料流必須保持可解釋。

### 11.1 Write Flow

```text
User mutation
→ local validation
→ SharedPackApplicationService
→ specific SharedPackRemoteApi request
→ remote permission/version/idempotency validation
→ remote atomic success
→ authoritative mutation result + full active snapshot
→ SharedPackCacheProjector validates full snapshot
→ single Drift transaction reconciliation
→ update remotePackVersion / lastRefreshedAt after commit
→ provider refresh
→ UI refresh
```

所有會改變 Shared Pack active current-state snapshot 的 mutation，都必須回傳 mutation-specific authoritative result、`resultingPackVersion` 與 full active snapshot。`fullSnapshot.packVersion` 必須等於 `resultingPackVersion`。Mutation-specific result 可用於 UI feedback，但 cache truth 必須來自 full snapshot projection。

Client 不可只投影單一 mutation fragment 後，把 `remotePackVersion` 更新至 `resultingPackVersion`。這會讓本機 cache 宣稱已完整同步到某個 Pack version，但實際可能漏掉其他裝置的中間 mutation。

Runtime races, late responses, idempotency replay, remote-success/local-projection-failure, known-untrusted cache, and freshness semantics must follow `docs/core/08_shared_pack_runtime_consistency_spec_v1.md`。Phase 1 technical design may choose serialization or transaction guards, but may not violate the Phase 0.7 runtime invariants.

v1 不做：

- local-first optimistic write。
- outbox。
- background retry。
- automatic merge。
- realtime listener。

### 11.2 Read Flow

```text
User taps refresh
→ SharedPackApplicationService
→ getSharedPackSnapshot
→ full snapshot or notModified
→ validate remoteSnapshotSchemaVersion when full snapshot returned
→ map DTO
→ Drift transaction
→ replace / reconcile Shared cache rows
→ update remotePackVersion on full snapshot projection
→ update lastRefreshedAt after successful projection or verification
→ provider refresh
→ UI refresh
```

`getSharedPackSnapshot` 可用 `knownPackVersion`。若 remote 回傳 `notModified`，代表 client 已成功向 remote 驗證目前 cache version；client 必須更新 `shared_pack_cache.lastRefreshedAt = verifiedAt`，但不重寫 membership / item cache rows，也不改 `remotePackVersion`。

## 12. Remote ID / Local ID Principle

本機資料可繼續使用 local ID；remote 資料可有 remote ID。但 mapping 必須集中管理，不應散落在不同 model。

Planned independent Shared cache direction：

```text
shared_pack_cache
- localId
- remotePackId
- remotePackVersion
- lastRefreshedAt

shared_membership_cache
- localId
- remoteMemberId
- remotePackId
- displayName
- role

shared_item_cache
- localId
- remoteItemId
- remotePackId
- remoteItemVersion
```

現有 `item_packs`、`items` 與 `item_action_records` 繼續只代表 Personal / local-first domain。Shared Pack v1 不靠現有 Personal tables 加 remote columns 來區分 Personal / Shared。

`shared_pack_cache.localId + remotePackId` 與 `shared_item_cache.localId + remoteItemId` 可承擔 mapping 語意。額外 mapping table 不是預設要求；只有 Phase 1 technical design 證明有必要時才新增，且不可和 Shared cache 無理由重複保存相同 identity。

`remotePackVersion` 只代表目前本機完整 cache 所對應的完整 Pack snapshot version。`lastRefreshedAt` 表示最近一次成功從 remote 取得或驗證 Shared Pack current state 的 UTC 時間，包含 full snapshot projection 成功、mutation full snapshot projection 成功與 `notModified` verification。

Phase 0.6 不新增 Shared cache table。正式 table 名稱、欄位型別、index、migration 與 hard-delete / inactive tombstone 策略必須在 Phase 1 technical design 中確認。

## 13. Invite Code Direction

Invite code 是 Shared Pack 的主要加入方式。

Invite code 的 scope 是單一 Pack：

- Owner-side invite UX 必須放在 Pack context 內，例如 Shared Pack detail / members area。
- Joiner-side invite UX 可以放在 Shared Pack entry 或 Settings 入口；輸入後應解析到 specific Pack。
- Invite code 不代表使用者、帳號、workspace 或本機裝置。
- 多個 Shared Pack 可以有多個 invite codes。
- 同一個 Shared Pack 同一時間最多只有 one active invite code。

格式方向：

- 6 characters。
- uppercase human-friendly alphanumeric characters。
- 避免 `0`、`O`、`1`、`I`、`L`。
- 建議 character set：`ABCDEFGHJKMNPQRSTUVWXYZ23456789`。
- Display 可顯示為 `K7M 4Q9`，canonical stored/query code 應為 `K7M4Q9`。
- 不要求使用者輸入空格或 hyphen。

v1 行為：

- `getOrCreateInviteCode`：若 Pack 已有 active code，回傳同一 code；若沒有 active code，建立一個；不會使既有 active code 失效。
- `rotateInviteCode`：Owner-only，建立新 code，atomically 使舊 code 失效，回傳新 code。
- v1 沒有自動 expiry。
- active invite code canonical value 不可出現在一般 log。
- Invite state 不屬於 active Shared Pack snapshot。
- `getOrCreateInviteCode` 與 `rotateInviteCode` 不需要 `expectedPackVersion`，不回傳 `resultingPackVersion`，不改變 `packVersion`。
- 如果未來 Invite 需要 concurrency control，應建立 `inviteVersion`，不可借用 `packVersion`。
- 持有有效 invite code 者可預覽最低限度 Pack metadata：Pack title、Pack icon、join availability。
- 加入前不得回傳 member names、owner identity、Shared Item titles、Shared Item content 或 completion history。
- `previewInviteCode` 與 `joinSharedPack` 必須有 rate limiting / brute-force protection。
- Invite normalization 必須在 server-side atomic path 中再次執行，不可信任 client normalization。
- 不需要 QR code / deep link。
- 不需要多角色權限。
- 不支援多個並行 invite codes。
- 不把 invite code 當 recovery credential。

## 14. Backup And Recovery Boundary

現有 JSON backup 是 legacy local export / import。

Shared Pack v1 規定：

- Shared Pack remote access 不由 local backup 恢復。
- Shared Pack cache、membership、invite code、remote identity mapping 與 credential 不應被當成傳統 backup recovery data。
- Supabase access token、refresh token、service role key 或其他 credential 永遠不可進入 backup。
- Phase 0 不修改現有 backup production code。

現有 Settings data reset 必須收斂為 Reset Personal local data：

- 清除 Personal local domain data。
- 重建 Personal system default Pack。
- 重建 Personal app settings / system records。
- 保留 `shared_pack_cache`、`shared_membership_cache`、`shared_item_cache`。
- 保留 anonymous remote identity/session。
- 保留 Shared Pack remote access metadata。

Shared Pack reset / unlink / sign-out / clear Shared cache 必須是日後獨立流程。v1 不新增 `listMySharedPacks`、`recoverMyMemberships`、`clearSharedData` 或 `signOutSharedIdentity`。

資料恢復方向：

- 未綁定帳號：local backup 可保護 Personal local data。
- 已綁定帳號後的長期方向：Personal / Shared active data 由帳號與 remote membership 恢復。

## 15. Pack Lifecycle Boundary

必須明確區分：

- Personal Pack archive。
- Shared Pack leave。
- Shared Pack member removal。
- Shared Pack archive。
- Shared Pack deletion。

現有 Personal Pack 的「一起封存內容」或「移到一般」語意，不可直接套用到 Shared Pack。

Shared Pack lifecycle 需要獨立規格。v1 支援最小建立、加入、查看、metadata update、state-based Shared Item management、invite code get-or-create / rotate 及完成流程。leave、owner transfer、last owner、remote delete、取消共享後轉回 Personal Pack 等流程放入 v1.x 或後續。

## 16. Codex 開發守則

Codex 在實作 Shared Pack 相關功能前，必須遵守：

1. 不可未更新 spec 就新增 Supabase dependency、table、RPC、request 或 migration。
2. 不可在 UI / controller 中直接呼叫 Supabase。
3. 不可把 realtime、outbox、account binding、backup recovery 混入 Shared Pack v1。
4. 不可將使用者 UI 語言設計成 local / remote。
5. 不可在未定義 migration strategy 前，自動把 Personal Pack data 推上 remote。
6. 不可在 backup 中保存 Supabase token / credentials。
7. 每個 phase 必須有清楚 manual test。
8. 每個 phase 完成後，開發者必須能用文字說明 A 的操作寫到哪裡、B 的刷新讀哪裡、local cache 何時更新。
9. 不可在未更新 06 / 07 前新增 product membership limit；infrastructure rate limit 不等於 product membership limit。

## 17. Shared Pack v1 Success Standard

v1 成功標準：

- 使用者能建立新的 Shared Pack。
- Owner 建立 Shared Pack 時保存 Pack-scoped `ownerDisplayName`。
- Owner 能建立、編輯、封存 state-based Shared Items。
- Owner 能更新 Shared Pack metadata。
- Owner 能 get-or-create / rotate invite code。
- Member 能用 invite code 加入 Shared Pack。
- Member 加入時保存 Pack-scoped `memberDisplayName`。
- Owner / Member 能查看 Shared Items。
- Owner / Member 能完成 Shared Item。
- A 完成 Shared Item 後，remote 成功並回傳 authoritative result + full active snapshot。
- A 的 local Drift cache 在 full snapshot projection 成功後更新。
- B 手動 refresh 後讀取 remote snapshot。
- B 的 local Drift cache 更新後能看見 A 完成後的 authoritative result。
- mutation full snapshot 對應 `resultingPackVersion`。
- B 的中間 mutation 不可被 A 的 fragment projection 遺漏。
- `updateSharedItem` 不可修改 anchor。
- invalid thresholds 被 remote 拒絕。
- Personal data reset 後 Shared Pack 仍可存取。
- invite rotate 不改 `packVersion`。
- `notModified` 更新 `lastRefreshedAt`。
- `remoteApiContractVersion = 1`。
- `remoteSnapshotSchemaVersion = 1`。
- active snapshot 不含 archived Item。

若 Codex 開始新增未規劃的 sync / realtime / outbox、直接從 UI 呼叫 Supabase、或把 Personal / Shared 與 Local / Remote 再次混淆，應停止新增功能並回到 spec。
