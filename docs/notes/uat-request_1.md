接下來是第一版的uat階段，以下是QA第1次回饋的內容及個人的解法，請你分析可行性及合理性。
1. create item/resource/stage -> select pack:
有圖
* 目測：一般1＝之後決定, 一般2 ＝default pack
* 不應該同時出現一般，最寫成之後決定

2. fixed base item/ start date 欄對user理解意義不明
需討論
* 情況1：period日數沒有超出提醒日數(anchordate - duedate)，檔期重疊，難以想像用意。
* anchor date 欄位資源非關鍵。
* period和due date才是關鍵，且易理解。

3. item create/edit form 「提醒方式」 改為預設是「固定節奏」

4. item create/edit form 「逾期處理」 改為預設是「等待處理」
有圖
* 「逾期處理」 改為預設是「等待處理」，並將「等待處理」排序往上

5. Item / Resource / StageTracker 建立後的跨 Pack 搬移入口未提供。
可討論
* 取消在row overflow設置「搬移」入口想法
* 改為從update form 提供搬移入口，彈出dialog並個別修改/儲存
* 如有結構性影響，必需商討處理方式

6. 封存vs刪除
可討論
* 使用者仍不太能理解「封存」的意思，可能需在字面上改為「刪除」

7. 添加頁面刷新功能
* 頁面拉向下就能觸發刷新功能

8. item create／update form「資源綁定」開放在沒有可綁定資源時的「加入資源連動」觸發
可討論／有圖
* 目前在沒有可綁定的資源時，item create 不開放可見section，item update 提示無法「加入資源連動」
* 開放後，用戶可在「沒有可綁定資源」時新增資源
* 新資源預設與item's pack相同
* 「資源連動」section在一般情況下是收合，內部資料選填（使用者可自行忽略）
* 按下儲存後，所有資源才進入database

9. 設定頁，移去「顯示系統追蹤器」欄位

10. setting頁 新增function，備份database／ reset database／ 加入datafile
可討論
* 主要備份 item／resource／stage／pack/custom template
* 可使用json file 形式？
* 不需備份 系統 stage tracker 

11. 動態頁 添加更多款式action icon
需討論
* 不要單一使用紀錄icon
* 動態頁主要顯示使用者進行過的操作，需了解目前動態頁是顯示什麼
* 主要參考行動內容：完成／跳過／延期／新增／修改／等等
* card 左側可顯示：垂直的icon＋action type


will
stage trackers page，可切換顯示方式

- `deferred` action type 只保留相容性，不建立新的 deferred record。
- `deferred` 不在目前 MVP 建立流程中使用。
入口怪異

語言
手機widget
共用
日期推算

- 隱藏眼仔(starget)

暫不做
- Resource history 已有頁面，但 `sourceItemActionRecordId` 目前主要透過格式化文字呈現，尚未提供跳回來源 Item action 的互動入口。
- Home attention occurrence 已支援「知道了」；「忽略這次」的 UI 入口、確認流程與 undo 尚未完成。


棄
- Pack 管理頁目前只顯示 active packs；archived packs 的管理入口未完成。
- archived StageTracker 管理 UI 未完成。
- archived StageRule 的獨立瀏覽與還原入口未完成。
- manual important stage 的 archived record 獨立瀏覽與還原入口未完成。


