# 06 Shared Pack Direction Spec v1

Status: planned product direction / not implemented.

本文件定義 Reminder App 的 Shared Pack 產品方向與 phased scope。Shared Pack v1 尚未在 production code 中實作；目前 repository 沒有 Supabase dependency、remote table、RPC、Shared Pack route、Shared Pack repository、anonymous auth 或 local mapping table。

本文件不是現有 local Reminder domain 的替代品。現有 core/local model 仍以 `docs/core/04_core_model_spec_v1.md` 為準；Home Widget 邊界以 `docs/core/05_home_widget_spec.md` 為準；planned remote request contract 以 `docs/core/07_shared_pack_remote_contract_v1.md` 為準。

## 1. 文件目的

Shared Pack 重新開發前，先鎖定產品語意與第一版邊界，避免再次把 Supabase auth、remote profile、anonymous user、pack mapping、invite、outbox、snapshot、backup、account binding、realtime / sync 等多個範圍一次塞進 v1。

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
- `owner` / `member` 兩種角色。
- invite code 建立、預覽、加入流程。
- Item-only boundary。
- Shared Item current state。
- `done` action。
- 最低限度 actor attribution，例如「由誰完成」。
- remote-first write。
- authoritative remote result。
- manual snapshot refresh。
- local Drift readable cache。
- Shared Pack list / entry。
- compact Shared Pack detail / settings page。
- Shared Item list。

### 3.2 Shared Pack v1.x

v1.x 可在 v1 資料流穩定後再規格化：

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
- invite revoke / rotate / expiry policy。

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

Shared Pack v1 採 Item-only boundary。

v1 涵蓋：

- Shared Pack metadata。
- owner / member membership。
- invite code flow。
- Item domain。
- Item current state。
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
- 完整 action history sync。
- complex undo chain。
- Personal / Shared 完整雲端統一模型。

現有 Personal Pack 中的 Resource、StageTracker 或其他 relation，不得因 Shared Pack v1 而被暗中加入 remote model。

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
| 管理 Shared Pack metadata | yes | no |
| 建立 Shared Item definition | yes | no |
| 編輯 Shared Item definition | yes | no |
| 封存 Shared Item definition | yes | no |
| 完成 Shared Item | yes | yes |
| 建立或管理 invite code | yes | no |
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

## 7. Supported Item Actions

Shared Pack v1 只支援 `done`。

v1 支援：

- 完成 Shared Item。
- 記錄完成者 identity。
- remote 回傳 authoritative Item result。
- remote 成功後更新 local Drift cache。

v1 不支援：

- skip。
- defer。
- undo。
- reverted。
- action history UI。
- complex completion history merge。
- `ItemNextCycleStrategy` 的多種使用者選擇。

`undo`、`skip`、action history 等能力可列入 Shared Pack v1.x，但不可寫成 v1 已包含能力。

## 8. Anonymous Identity Limitation

Shared Pack v1 暫時使用 anonymous remote identity，避免把完整帳號綁定、OAuth、換機恢復與 membership recovery 塞入第一版。

限制：

- anonymous identity 是 Shared Pack remote access 的最低限度身份。
- Personal Pack 仍可在沒有 remote identity 的情況下維持 local-first。
- Shared Pack 建立或加入需要成功取得 anonymous remote identity。
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

## 9. Product Surface Boundary

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

## 10. Data Flow Principles

Shared Pack v1 的資料流必須保持可解釋。

### 10.1 Write Flow

```text
User action
→ local validation
→ completeSharedItem
→ remote atomic success
→ authoritative result
→ SharedPackCacheProjector updates local Drift cache
→ provider refresh
→ UI refresh
```

v1 不做：

- local-first optimistic write。
- outbox。
- background retry。
- automatic merge。
- realtime listener。

### 10.2 Read Flow

```text
User taps refresh
→ getSharedPackSnapshot
→ validate remoteSnapshotSchemaVersion
→ map DTO
→ Drift transaction
→ update mapping / lastRefreshedAt
→ provider refresh
→ UI refresh
```

## 11. Remote ID / Local ID Principle

本機資料可繼續使用 local ID；remote 資料可有 remote ID。但 mapping 必須集中管理，不應散落在不同 model。

Planned mapping direction：

```text
shared_pack_mapping
- localPackId
- remotePackId
- remoteVersion
- lastRefreshedAt

shared_item_mapping
- localItemId
- remoteItemId
- remotePackId
- remoteVersion
```

Phase 0 不新增 mapping table。正式 table 名稱、欄位型別、index 與 migration 必須在 Phase 1 前確認。

## 12. Invite Code Direction

Invite code 是 Shared Pack 的主要加入方式。

Invite code 的 scope 是單一 Pack：

- Owner-side invite UX 必須放在 Pack context 內，例如 Shared Pack detail / members area。
- Joiner-side invite UX 可以放在 Shared Pack entry 或 Settings 入口；輸入後應解析到 specific Pack。
- Invite code 不代表使用者、帳號、workspace 或本機裝置。
- 多個 Shared Pack 可以有多個 invite codes。

格式方向：

- 6 characters。
- uppercase human-friendly alphanumeric characters。
- 避免 `0`、`O`、`1`、`I`、`L`。
- 建議 character set：`ABCDEFGHJKMNPQRSTUVWXYZ23456789`。
- Display 可顯示為 `K7M 4Q9`，canonical stored/query code 應為 `K7M4Q9`。
- 不要求使用者輸入空格或 hyphen。

v1 可接受限制：

- invite expiry 可先不做，或只在 Phase 1 明確決定後加入。
- 不需要 revoke / rotate。
- 不需要 QR code / deep link。
- 不需要多角色權限。

## 13. Backup And Recovery Boundary

現有 JSON backup 是 legacy local export / import。

Shared Pack v1 規定：

- Shared Pack remote access 不由 local backup 恢復。
- Shared Pack cache、membership、invite code、remote mapping 與 credential 不應被當成傳統 backup recovery data。
- Supabase access token、refresh token、service role key 或其他 credential 永遠不可進入 backup。
- Phase 0 不修改現有 backup production code。

資料恢復方向：

- 未綁定帳號：local backup 可保護 Personal local data。
- 已綁定帳號後的長期方向：Personal / Shared active data 由帳號與 remote membership 恢復。

## 14. Pack Lifecycle Boundary

必須明確區分：

- Personal Pack archive。
- Shared Pack leave。
- Shared Pack member removal。
- Shared Pack archive。
- Shared Pack deletion。

現有 Personal Pack 的「一起封存內容」或「移到一般」語意，不可直接套用到 Shared Pack。

Shared Pack lifecycle 需要獨立規格。v1 可只支援最小建立、加入、查看及完成流程。leave、owner transfer、last owner、remote delete、取消共享後轉回 Personal Pack 等流程放入 v1.x 或後續。

## 15. Codex 開發守則

Codex 在實作 Shared Pack 相關功能前，必須遵守：

1. 不可未更新 spec 就新增 Supabase dependency、table、RPC、request 或 migration。
2. 不可在 UI / controller 中直接呼叫 Supabase。
3. 不可把 realtime、outbox、account binding、backup recovery 混入 Shared Pack v1。
4. 不可將使用者 UI 語言設計成 local / remote。
5. 不可在未定義 migration strategy 前，自動把 Personal Pack data 推上 remote。
6. 不可在 backup 中保存 Supabase token / credentials。
7. 每個 phase 必須有清楚 manual test。
8. 每個 phase 完成後，開發者必須能用文字說明 A 的操作寫到哪裡、B 的刷新讀哪裡、local cache 何時更新。

## 16. Shared Pack v1 Success Standard

v1 成功標準：

- 使用者能建立新的 Shared Pack。
- Owner 能建立 invite code。
- Member 能用 invite code 加入 Shared Pack。
- Owner / Member 能查看 Shared Items。
- Owner / Member 能完成 Shared Item。
- A 完成 Shared Item 後，remote 成功並回傳 authoritative result。
- A 的 local Drift cache 在 remote 成功後更新。
- B 手動 refresh 後讀取 remote snapshot。
- B 的 local Drift cache 更新後能看見 A 完成後的 authoritative result。

若 Codex 開始新增未規劃的 sync / realtime / outbox、直接從 UI 呼叫 Supabase、或把 Personal / Shared 與 Local / Remote 再次混淆，應停止新增功能並回到 spec。
