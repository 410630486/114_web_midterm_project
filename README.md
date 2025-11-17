
# 動物圖鑑

**組員**：葉家亨

---

## 專案簡介

使用者可在網頁上線上報名校園活動。系統包含即時表單驗證與送出後的確認流程，並避免重複送出。

## 使用技術

- HTML
- CSS
- Bootstrap
- JavaScript
- Constraint Validation API (瀏覽器表單驗證)

## 功能特色

1. 表單即時驗證（必填欄位 / 格式檢查）
2. 報名資料在頁面上顯示確認（含摘要）
3. 防止使用者重複送出（按鈕鎖定或 token 檢查）

## 快速使用說明

1. 以簡易靜態伺服器啟動專案（避免 fetch JSON 的跨域問題）：

```pwsh
python -m http.server 5500
# 或（若有 Node.js）
npx http-server . -p 5500
```

2. 開啟瀏覽器並前往：

`http://localhost:5500`

3. 開啟 `index.html`，填寫報名表單並送出，系統會驗證欄位並顯示送出結果。

## GitHub Pages

[專案頁面]：https://410630486.github.io/114_web_midterm_project/
