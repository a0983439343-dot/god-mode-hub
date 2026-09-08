-- DeveloperTool V5 | Loader
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
if not Player then
    return
end

local URL = "https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/refs/heads/main/god-mode-hub-main/DeveloperTool_V5/main.lua"

local ok, source = pcall(function()
    return game:HttpGet(URL)
end)

if not ok or type(source) ~= "string" or source == "" then
    warn("DeveloperTool_V5 主程式下載失敗：", source)
    return
end

local chunk, compileError = loadstring(source)
if not chunk then
    warn("DeveloperTool_V5 主程式編譯失敗：", compileError)
    return
end

local success, runtimeError = pcall(chunk)
if not success then
    warn("DeveloperTool_V5 執行失敗：", runtimeError)
end
