# 動物圖鑑 — 114 網頁期中專案

專案說明
-----
一個互動式的靜態前端作品，主題為「動物圖鑑」。示範使用 HTML5（語意化標籤）、CSS3 / Bootstrap 5、以及原生 JavaScript 完成動態資料渲染、搜尋/篩選、分類檢索、收藏功能與表單驗證。

組員
-----
- 組員：請在此填入組長與組員姓名（範例：A、B）

符合 HackMD（期中專案）檢核清單
-----
- HTML5 結構：使用 `header` / `main` / `section` / `footer` 等語意化標籤 ✅
- CSS3 / Bootstrap 5：已引入 Bootstrap CDN，並用自訂 `styles.css` 覆寫主題色與樣式 ✅
- JavaScript 互動：包含搜尋、篩選、分類檢索、modal 詳細檢視、收藏（localStorage）等多項互動 ✅
- DOM 操作：使用 `createElement`、`addEventListener`、`querySelector` 等方法動態建立與操作元素 ✅
- 表單驗證：聯絡表單使用 Constraint Validation API (`checkValidity()`)、並顯示 invalid-feedback ✅
- GitHub 版本控管：此專案目錄含 `.git`（請將 repo 推上 GitHub） ⚠️（需你把變更 push 到 GitHub）
- GitHub Pages：README 說明如何部署到 GitHub Pages，請上傳至 GitHub 並在 Settings -> Pages 啟用以取得公開網址 ⚠️（需你在 GitHub 上啟用）
- 檔案結構建議：專案包含 `index.html`, `styles.css`, `app.js`, `data/animals.json`, `assets/`（若需離線圖片請放入） ✅
- 截圖：繳交時請上傳至少 4 張截圖到 `screenshots/`（目前有 placeholder，請放入實際截圖） ⚠️（請補上截圖）

如何在本機執行
-----
建議使用簡單靜態伺服器以避免 fetch JSON 的跨域問題。

使用 PowerShell：
```pwsh
# 若有 Python
python -m http.server 5500

# 或使用 npx http-server（需 Node.js）
npx http-server . -p 5500
```
然後開啟瀏覽器： `http://localhost:5500`

檔案簡介
-----
- `index.html`：主頁（搜尋、篩選、分類、卡片、modal、聯絡表單）
- `styles.css`：自訂樣式（包含主題色覆寫）
- `app.js`：載入 `data/animals.json` 並動態渲染、處理事件、localStorage 收藏、表單驗證
- `data/animals.json`：動物資料（含 `category`、`habitat`、`size` 等欄位）
- `screenshots/`：請放入至少 4 張截圖（建議：首頁、搜尋/篩選、modal 詳情、聯絡表單驗證畫面）

評分對照（參考 HackMD）
-----
- 頁面設計與排版（20 分）：使用 Bootstrap RWD，語意化結構已落實。
- 互動功能與 JavaScript（30 分）：多項互動功能已實作（搜尋、篩選、分類、收藏、modal）。
- 表單驗證與使用者體驗（20 分）：使用 Constraint Validation API，顯示 invalid-feedback。
- 程式品質（10 分）：程式碼結構清楚，註解簡潔；可再加入更多註解與函式分割以提高可讀性。
- GitHub 管理與文件（10 分）：README 已補充執行與部署指引；請上傳 repo 並加上 screenshots。
- 成果展示與穩定性（10 分）：請在 GitHub Pages 部署後提供網址以完成此項。

後續建議（可選）
-----
- 把 `data/animals.json` 的圖片換成本地 `assets/` 圖片（避免依賴第三方），我可以自動下載授權圖片並加入 `assets/`。
- 新增截圖 `screenshots/` 中的至少 4 張畫面。
- 若要加分（+10）：加入 localStorage 的使用紀錄、深色模式、動畫效果或更完整的 RWD 微調。

已實作（此 repo）
-----
- 深色模式切換（會記住使用者偏好，儲存在 localStorage）
- 卡片動畫（淡入與 hover 動畫）
- RWD 微調（小螢幕的搜尋/分類排版與按鈕調整）


聯絡與授權
-----
請在 README 中補上組員、指導老師與授權資訊。

