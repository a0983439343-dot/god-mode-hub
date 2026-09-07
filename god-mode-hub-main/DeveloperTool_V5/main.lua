-- DeveloperTool V5 | Main
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
if not Player then
    return
end

local PlayerGui = Player:WaitForChild("PlayerGui")
local Registry = "__DeveloperTool_V5_Runtime"

local function safeCall(label, callback)
    local ok, result = pcall(callback)
    if not ok then
        warn("DeveloperTool_V5 " .. label .. "失敗：", result)
    end
    return ok, result
end

local function cleanupPrevious()
    local previous = rawget(_G, Registry)
    if type(previous) == "table" and type(previous.Cleanup) == "function" then
        safeCall("舊實例清理", previous.Cleanup)
    end
    _G[Registry] = nil
    _G.DeveloperTool_V5_Cleanup = nil
end

cleanupPrevious()

local baseURL = "https://raw.githubusercontent.com/a0983439343-dot/god-mode-hub/refs/heads/main/god-mode-hub-main/DeveloperTool_V5/"

local function destroyOldGui()
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child.Name == "DeveloperTool_V5" or child.Name == "DeveloperTool_V4" then
            safeCall("舊 UI 清理", function()
                child:Destroy()
            end)
        end
    end
end

destroyOldGui()

local function fetchChunk(url, label)
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        return nil, label .. "下載失敗：" .. tostring(source)
    end
    if type(source) ~= "string" or source == "" then
        return nil, label .. "內容為空"
    end

    local chunk, compileError = loadstring(source)
    if not chunk then
        return nil, label .. "編譯失敗：" .. tostring(compileError)
    end
    return chunk, nil
end

local function loadModule(path)
    local chunk, err = fetchChunk(baseURL .. path, path)
    if not chunk then
        warn("DeveloperTool_V5 " .. err)
        return nil
    end

    local ok, result = pcall(chunk)
    if not ok then
        warn("DeveloperTool_V5 模組執行失敗：", path, result)
        return nil
    end
    return result
end

local Cleanup = loadModule("src/Core/Cleanup.lua")
if type(Cleanup) ~= "table" or type(Cleanup.new) ~= "function" then
    warn("DeveloperTool_V5 核心清理模組無法使用")
    return
end

local State = Cleanup.new("DeveloperTool_V5")
local Shared = {
    FlightActive = false,
    FreeCamActive = false,
    StopFlight = nil,
    StopFreeCam = nil,
}

local modulePaths = {
    {"Movement", "src/Modules/Movement.lua"},
    {"Visuals", "src/Modules/Visuals.lua"},
    {"ESP", "src/Modules/ESP.lua"},
    {"Teleport", "src/Modules/Teleport.lua"},
    {"Performance", "src/Modules/Performance.lua"},
}

local Modules = {}
for _, entry in ipairs(modulePaths) do
    Modules[entry[1]] = loadModule(entry[2])
end

local Rayfield
local rayfieldChunk, rayfieldErr = fetchChunk("https://sirius.menu/rayfield", "Rayfield")
if rayfieldChunk then
    local ok, result = pcall(rayfieldChunk)
    if ok then
        Rayfield = result
    else
        warn("DeveloperTool_V5 Rayfield 執行失敗：", result)
    end
else
    warn("DeveloperTool_V5 " .. tostring(rayfieldErr))
end

if not Rayfield then
    State:Cleanup()
    return
end

local Window
local windowOk, windowResult = pcall(function()
    return Rayfield:CreateWindow({
        Name = "開發者測試面板 V5",
        LoadingTitle = "開發者測試面板 V5",
        LoadingSubtitle = "Roblox 開發者測試工具｜完整版本",
        ConfigurationSaving = {Enabled = false},
        Discord = {Enabled = false},
        KeySystem = false,
    })
end)

if not windowOk or not windowResult then
    warn("DeveloperTool_V5 視窗建立失敗：", windowResult)
    State:Cleanup()
    return
end
Window = windowResult

local tabs = {}
local tabSpecs = {
    {"Movement", "移動", 4483362458},
    {"Visuals", "視覺", 4483362458},
    {"ESP", "ESP", 4483362458},
    {"Teleport", "傳送", 4483362458},
    {"Performance", "效能", 4483362458},
}

for _, spec in ipairs(tabSpecs) do
    local name, title, icon = spec[1], spec[2], spec[3]
    local ok, tab = pcall(function()
        return Window:CreateTab(title, icon)
    end)
    if ok then
        tabs[name] = tab
    else
        warn("DeveloperTool_V5 建立分頁失敗：", name, tab)
    end
end

-- UI must be registered before module cleanup so modules are restored first on shutdown.
State:Add(function()
    if Rayfield and type(Rayfield.Destroy) == "function" then
        pcall(function()
            Rayfield:Destroy()
        end)
    end
end)

local contextBase = {
    Player = Player,
    PlayerGui = PlayerGui,
    State = State,
    RunService = RunService,
    Rayfield = Rayfield,
    Window = Window,
    Shared = Shared,
}

local initialized = {}
for _, entry in ipairs(modulePaths) do
    local name = entry[1]
    local moduleObject = Modules[name]
    local tab = tabs[name]

    if type(moduleObject) == "table" and type(moduleObject.Init) == "function" and tab then
        local context = table.clone(contextBase)
        context.Tab = tab

        local ok, err = pcall(function()
            moduleObject:Init(context)
        end)

        if ok then
            initialized[name] = true
            State:Add(function()
                if type(moduleObject.Cleanup) == "function" then
                    pcall(function()
                        moduleObject:Cleanup()
                    end)
                end
            end)
        else
            warn("DeveloperTool_V5 模組初始化失敗：", name, err)
            if type(moduleObject.Cleanup) == "function" then
                pcall(function()
                    moduleObject:Cleanup()
                end)
            end
        end
    else
        warn("DeveloperTool_V5 缺少模組或分頁：", name)
    end
end

local closed = false
local function runtimeCleanup()
    if closed then
        return
    end
    closed = true

    Shared.FlightActive = false
    Shared.FreeCamActive = false
    State:Cleanup()
    _G[Registry] = nil
    _G.DeveloperTool_V5_Cleanup = nil
end

_G[Registry] = {
    Cleanup = runtimeCleanup,
    Version = "5.0.0",
}
_G.DeveloperTool_V5_Cleanup = runtimeCleanup

if tabs.Movement then
    pcall(function()
        tabs.Movement:CreateSection("系統")
        tabs.Movement:CreateLabel("DeveloperTool V5 · 5.0.0")
        tabs.Movement:CreateButton({
            Name = "關閉開發者測試面板",
            Callback = runtimeCleanup,
        })
    end)
end

local initializedNames = {}
for name in pairs(initialized) do
    table.insert(initializedNames, name)
end
table.sort(initializedNames)
print("DeveloperTool_V5 已載入：" .. table.concat(initializedNames, ", "))
