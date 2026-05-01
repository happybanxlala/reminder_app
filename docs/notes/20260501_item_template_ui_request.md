# ⚠️ AI IGNORE

This document is for personal notes and exploration only.

DO NOT use this file as:
- source of truth
- implementation reference
- product specification

Use only documents under `/docs/core/` for implementation decisions.

---
1. 對事項新增更個自定義的schedule類型﹐以適應不同類型的事項需求。
- 除了每天、每週外，還可以根據事項的特性設計更多的schedule類型，如「每月」、「每X天」、「每X週」等。
- 針對不同類型的schedule，設計相應的配置選項，如「每X天」需要用戶輸入X的值，「每月」可能需要用戶選擇具體日期等。
- 配置設計應該簡潔明了，讓用戶能夠快速設置和理解不同類型的schedule。

2. 提供責任包模版﹐以便快速創建新的責任包。
內建多種模版選項﹐涵蓋不同類型的責任包（如家務、照料貓咪、財務管理）。用戶可快速套用模版並根據需要進行修改﹐節省創建責任包的時間。用戶還可以自定義模版﹐以適應特定需求。

實作細節：
- 設計一個模版管理頁面﹐允許用戶瀏覽和選擇不同類型的責任包模版。
- 模版管理入口為事項列表頁面的header右側，為「套用模版」按鈕，點擊後彈出模版選擇界面。
- 在模版選擇界面，展示模版列表，每個模版顯示名稱、類型和簡短描述、以及一個「查看」按鈕。
- 模版可分為內建模版和用戶自定義模版兩類，使用tabs或分類方式展示。
- 查看模版詳情時，展示模版包含的事項列表和每個事項的關鍵信息，並提供「套用此模版」按鈕。
- 用戶點擊「套用此模版」後，將模版中的事項複製到當前責任包中，並在模組名稱添加「(模版)」後綴作為責任包標題。用戶可在套用後可於事項列表中對責任包進行修改和調整，以適應具體情況。
- 不提供用戶自定義模版的創建頁面，但允許用戶從現成的責任包中保存為模版，以便未來使用。

需討論的問題：
- 資料結構：模版的數據結構應該如何設計，以便於存儲和管理？每個模版應包含哪些關鍵信息（如名稱、類型、描述、事項列表等）？

第一個內建模版示例：
模版名稱：彩月島貓奴指南
類型：照料貓咪
描述：這個模版包含了照顧貓咪的日常事項，幫助你確保貓咪的健康和幸福。
事項列表：
名稱／描述／類型／Config
- 19:00 餵飯／餵罐／固定節奏／{"type": "fixed", "scheduleType": "daily", "warningBefore": 0, "dangerBefore": 0}
- 清理貓砂盆/兩週一次/彈性處理／{"type": "stateBased", "warningAfter": 10, "dangerAfter": 15}
- 替換貓砂盆尿墊／三天一次／彈性處理/{"type": "stateBased", "warningAfter": 3, "dangerAfter": 5}
- 飲水機加水／三天一次、不加會彩水會亂喝水／固定節奏／{"type": "fixed", "scheduleType": "everyXDays", "scheduleValue": 3, "warningBefore": 1, "dangerBefore": 0}
- 飲水機換濾芯／兩週一次／彈性處理／{"type": "stateBased", "warningAfter": 10, "dangerAfter": 15}
- 餵食機加食／兩週一次／固定節奏／{"type": "fixed", "scheduleType": "everyXDays", "scheduleValue": 3, "warningBefore": 1, "dangerBefore": 0}
- 替換餵食機乾燥劑／一月一次／彈性處理／{"type": "stateBased", "warningAfter": 30, "dangerAfter": 40}
- 補充貓用品／尿墊、貓砂，hktvmall買／庫存／{"type": "resourceBased", "durationDays": 0, "warningBefore": 3, "dangerBefore": 5}
- 補充貓乾糧／hktvmall買／庫存／{"type": "resourceBased", "durationDays": 0, "warningBefore": 5, "dangerBefore": 3}
- 補充貓罐頭／去葵芳買／庫存//{"type": "resourceBased", "durationDays": 0, "warningBefore": 5, "dangerBefore": 3}
- 剪指甲／一週一次／彈性處理／{"type": "stateBased", "warningAfter": 7, "dangerAfter": 10}
- 刷牙／一週一次／彈性處理／{"type": "stateBased", "warningAfter": 7, "dangerAfter": 10}

第二個內建模版示例：
模版名稱：家務清單
類型：家務
描述：這個模版包含了常見的家務事項，幫助你保持家庭整潔和有序。
事項列表：
名稱／描述／類型／Config
- 打掃地板／每週一次／彈性處理／{"type": "stateBased", "warningAfter": 7, "dangerAfter": 10}
- 打掃浴室／每週一次／彈性處理／{"type": "stateBased", "warningAfter": 7, "dangerAfter": 10}
- 洗衣服／每週一次／彈性處理／{"type": "stateBased", "warningAfter": 7, "dangerAfter": 10}
- 擦窗戶／每月一次／彈性處理／{"type": "stateBased", "warningAfter": 30, "dangerAfter": 40}
- 清理冰箱／每月一次／彈性處理／{"type": "stateBased", "warningAfter": 30, "dangerAfter": 40}
- 倒垃圾／每週一次／彈性處理／{"type": "stateBased", "warningAfter": 7, "dangerAfter": 10}
- 購買清潔用品／hktvmall買／庫存／{"type": "resourceBased", "durationDays": 0, "warningBefore": 3, "dangerBefore": 5}
- 購買洗衣用品／hktvmall買／庫存／{"type": "resourceBased", "durationDays": 0, "warningBefore": 3, "dangerBefore": 5}
- 購買垃圾袋／hktvmall買／庫存／{"type": "resourceBased", "durationDays": 0, "warningBefore": 3, "dangerBefore": 5}
- 購買清潔工具／hktvmall買／庫存／{"type": "resourceBased", "durationDays": 0, "warningBefore": 3, "dangerBefore": 5}

3. 從現成的責任包中保存為模版
- 在責任包，提供一個「保存為模版」的按鈕，存放在overflow menu中的第2個區塊中，允許用戶將當前責任包保存為一個新的模版。
- 用戶點擊「保存為模版」後，彈出一個對話框，讓用戶輸入模版的名稱、類型和描述。
- 系統會從欄位中提示當前責任包的名稱作為默認模版名稱，並在類型欄位提供一個下拉選單，讓用戶選擇模版類型（如家務、照料貓咪、財務管理等）。
- 用戶填寫完信息後，點擊「保存」按鈕，系統會將當前責任包中的事項複製到一個新的模版中。