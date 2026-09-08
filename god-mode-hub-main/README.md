# DeveloperTool V5 完整版

DeveloperTool V5.1 是這個專案的完整整理版，所有 Lua 模組都已統一到 V5 路徑與 V5 生命週期。

## 專案結構

- `loader.lua`：V5 根目錄載入器
- `DeveloperTool_V5/main.lua`：主程式、模組管理、舊實例清理
- `DeveloperTool_V5/src/Core/Cleanup.lua`：統一生命週期清理
- `DeveloperTool_V5/src/Modules/Movement.lua`：飛行、穿牆、無限跳、速度、跳躍、重力
- `DeveloperTool_V5/src/Modules/Visuals.lua`：全亮、大氣、後製、FOV、FreeCam
- `DeveloperTool_V5/src/Modules/ESP.lua`：玩家/NPC 高亮與玩家傳送
- `DeveloperTool_V5/src/Modules/Teleport.lua`：準心、出生點、座標、書籤傳送
- `DeveloperTool_V5/src/Modules/Performance.lua`：FPS、Ping、可恢復低畫質

## V5.1 主要改進

- 統一所有遠端路徑為 `DeveloperTool_V5`
- 重複執行時先清掉舊 V4/V5 UI 與 runtime
- 模組初始化與 Cleanup 更完整，避免殘留 RenderStepped、Heartbeat、Input、Player/Workspace 事件
- FreeCam 與飛行互斥，FreeCam 可用滑鼠/觸控旋轉；啟用時會鎖定角色原地，避免 WASD 讓玩家跟著移動，關閉後恢復原狀
- 新增「解鎖視角縮放限制」，可將相機最大縮放距離提高並在關閉/清理時恢復原設定
- 視野、光照、大氣、後製效果會記住原始狀態並可恢復
- ESP 不再依賴空轉 Heartbeat，玩家重生與場景新增 NPC 都會即時處理
- 傳送會檢查角色存活、清理速度，座標輸入使用數字欄位
- 低畫質不再永久刪除材質、貼圖或 SurfaceAppearance；可恢復原畫質
- 重要輸入全部保留「輸入數字」方式，不使用數字 Slider

## 載入

將 `loader.lua` 的內容執行即可載入 V5 主程式。主程式與模組都從目前 GitHub `main` 分支的 `god-mode-hub-main/DeveloperTool_V5/` 讀取。

## 已知限制

本專案仍依賴遠端 `HttpGet` / `loadstring` 與外部 Rayfield。遠端來源被修改、失效或不可連線時，載入仍可能失敗；這屬於遠端載入架構本身的限制。

## 一行載入

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/refs/heads/main/god-mode-hub-main/DeveloperTool_V5/loader.lua"))()
```
